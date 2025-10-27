import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pet.dart';
import '../../../providers/pet_provider.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _species = 'dog';
  final _breed = TextEditingController();
  final _age = TextEditingController();
  String? _gender;
  final _color = TextEditingController();
  final _weight = TextEditingController();
  final _microchip = TextEditingController();
  final _notes = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _color.dispose();
    _weight.dispose();
    _microchip.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<PetProvider>();
    final pet = Pet(
      id: 0,
      name: _name.text.trim(),
      species: _species,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      age: _age.text.trim().isEmpty ? null : int.tryParse(_age.text.trim()),
      gender: _gender,
      color: _color.text.trim().isEmpty ? null : _color.text.trim(),
      weight: _weight.text.trim().isEmpty ? null : double.tryParse(_weight.text.trim()),
      microchipId: _microchip.text.trim().isEmpty ? null : _microchip.text.trim(),
      medicalNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      tag: null,
    );
    final err = await provider.addPet(pet);
    setState(() => _saving = false);
    if (err == null && mounted) {
      Navigator.of(context).pop(pet);
    } else if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _species,
                items: const [
                  DropdownMenuItem(value: 'dog', child: Text('Dog')),
                  DropdownMenuItem(value: 'cat', child: Text('Cat')),
                  DropdownMenuItem(value: 'bird', child: Text('Bird')),
                  DropdownMenuItem(value: 'rabbit', child: Text('Rabbit')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _species = v ?? 'dog'),
                decoration: const InputDecoration(labelText: 'Species'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _breed, decoration: const InputDecoration(labelText: 'Breed')),
              const SizedBox(height: 12),
              TextFormField(controller: _age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _color, decoration: const InputDecoration(labelText: 'Color')),
              const SizedBox(height: 12),
              TextFormField(controller: _weight, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextFormField(controller: _microchip, decoration: const InputDecoration(labelText: 'Microchip ID')),
              const SizedBox(height: 12),
              TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Medical notes'), maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator() : const Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
