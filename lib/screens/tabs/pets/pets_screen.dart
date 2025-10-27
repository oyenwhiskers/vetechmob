import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../models/pet.dart';
import 'pet_form_screen.dart';
import 'pet_detail_screen.dart';
import 'scan_tag_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PetProvider>().fetch());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.fetch,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: provider.pets.length,
                itemBuilder: (ctx, i) {
                  final p = provider.pets[i];
                  return Card(
                    child: ListTile(
                      title: Text(p.name),
                      subtitle: Text('${p.species}${p.breed != null ? ' • ${p.breed}' : ''}'),
                      leading: const Icon(Icons.pets),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p.tag != null) const Icon(Icons.qr_code_2),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Assign tag',
                            onPressed: () async {
                              final tag = await Navigator.of(context).push<String>(
                                MaterialPageRoute(builder: (_) => ScanTagScreen()),
                              );
                              if (tag != null && mounted) {
                                final err = await context.read<PetProvider>().assignTag(p.id, tag);
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PetDetailScreen(petId: p.id)),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<Pet>(
            MaterialPageRoute(builder: (_) => const PetFormScreen()),
          );
          if (created != null && mounted) {
            // Provider already updated list in addPet; just feedback
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet added')));
          }
        },
        label: const Text('Add Pet'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
