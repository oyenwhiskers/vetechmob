import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pet.dart';
import '../../../models/treatment.dart';
import '../../../providers/pet_provider.dart';

class PetDetailScreen extends StatefulWidget {
  final int petId;
  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Pet? _pet;
  List<Treatment> _treatments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = context.read<PetProvider>();
      final list = provider.pets;
      Pet? found;
      for (final p in list) {
        if (p.id == widget.petId) {
          found = p;
          break;
        }
      }
      _pet = found;
      _treatments = await provider.fetchTreatments(widget.petId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    final p = _pet;
    if (p == null) return const Center(child: Text('Pet not found'));

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text('${p.name} • ${p.species}'),
                subtitle: Text([
                  if (p.breed != null) p.breed,
                  if (p.age != null) 'Age: ${p.age}',
                  if (p.gender != null) 'Gender: ${p.gender}',
                  if (p.color != null) 'Color: ${p.color}',
                  if (p.weight != null) 'Weight: ${p.weight} kg',
                ].whereType<String>().join(' • ')),
                trailing: p.tag != null ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.qr_code_2),
                    Text('Tag ${p.tag!.tagCode}')
                  ],
                ) : null,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Medical treatments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_treatments.isEmpty) const Text('No treatments recorded') else ..._treatments.map((t) => Card(
              child: ListTile(
                leading: const Icon(Icons.local_hospital),
                title: Text(t.diagnosis),
                subtitle: Text('${t.treatmentDate} • ${t.treatmentLocation}'),
                trailing: t.collaborator != null ? Text(t.collaborator!.name) : null,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
