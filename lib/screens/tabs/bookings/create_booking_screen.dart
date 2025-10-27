import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../models/pet.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _petId;
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _service = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final petsProv = context.read<PetProvider>();
    if (petsProv.pets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => petsProv.fetch());
    }
  }

  @override
  void dispose() {
    _date.dispose();
    _time.dispose();
    _service.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final err = await context.read<BookingProvider>().create(
          petId: _petId!,
          date: _date.text.trim(),
          time: _time.text.trim(),
          serviceType: _service.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    setState(() => _saving = false);
    if (err == null && mounted) {
      Navigator.of(context).pop(true);
    } else if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 1),
      initialDate: today,
    );
    if (picked != null) {
      _date.text = picked.toIso8601String().split('T').first; // YYYY-MM-DD
      setState(() {});
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      _time.text = '$h:$m';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _petId,
                items: pets.map((Pet p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => _petId = v),
                decoration: const InputDecoration(labelText: 'Pet'),
                validator: (v) => v == null ? 'Please select a pet' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _date,
                decoration: InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _time,
                decoration: InputDecoration(
                  labelText: 'Time (HH:MM)',
                  suffixIcon: IconButton(icon: const Icon(Icons.schedule), onPressed: _pickTime),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _service, decoration: const InputDecoration(labelText: 'Service type'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator() : const Text('Create'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
