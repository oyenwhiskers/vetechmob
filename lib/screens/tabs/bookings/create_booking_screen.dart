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
  String? _serviceType; // Changed from TextEditingController to String for dropdown
  final _notes = TextEditingController();
  bool _saving = false;

  // Focus nodes to enable dynamic focused styling
  final FocusNode _petFocus = FocusNode();
  final FocusNode _dateFocus = FocusNode();
  final FocusNode _timeFocus = FocusNode();
  final FocusNode _serviceFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final petsProv = context.read<PetProvider>();
    if (petsProv.pets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => petsProv.fetch());
    }
    // Rebuild when focus changes to update styles
    for (final n in [_petFocus, _dateFocus, _timeFocus, _serviceFocus, _notesFocus]) {
      n.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _date.dispose();
    _time.dispose();
    _notes.dispose();
    _petFocus.dispose();
    _dateFocus.dispose();
    _timeFocus.dispose();
    _serviceFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  InputDecoration _focusedDecoration(
    BuildContext context, {
    required String label,
    required FocusNode node,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final accent = Theme.of(context).colorScheme.secondary;
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
    );
    final focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accent, width: 2),
    );

    return InputDecoration(
      labelText: label,
      // Make label more visible when floating
  floatingLabelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
      // Fill only when focused to emulate the reference design
      filled: true,
  fillColor: node.hasFocus ? accent.withOpacity(0.08) : Colors.transparent,
    prefixIcon: prefixIcon != null
      ? Icon(prefixIcon, color: node.hasFocus ? accent : Colors.grey.shade600)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: focused,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final err = await context.read<BookingProvider>().create(
          petId: _petId!,
          date: _date.text.trim(),
          time: _time.text.trim(),
          serviceType: _serviceType!,
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
        child: Theme(
          // Increase contrast for focused fields just on this screen
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: const TextStyle(color: Colors.black87),
              floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              hintStyle: const TextStyle(color: Colors.black54),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
              ),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  focusNode: _petFocus,
                  value: _petId,
                  items: pets
                      .map((Pet p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _petId = v),
                  decoration: _focusedDecoration(
                    context,
                    label: 'Pet',
                    node: _petFocus,
                    prefixIcon: Icons.pets,
                  ),
                  iconEnabledColor: Theme.of(context).colorScheme.secondary,
                  validator: (v) => v == null ? 'Please select a pet' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  focusNode: _dateFocus,
                  controller: _date,
                  decoration: _focusedDecoration(
                    context,
                    label: 'Date (YYYY-MM-DD)',
                    node: _dateFocus,
                    prefixIcon: Icons.calendar_today,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary),
                      onPressed: _pickDate,
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  focusNode: _timeFocus,
                  controller: _time,
                  decoration: _focusedDecoration(
                    context,
                    label: 'Time (HH:MM)',
                    node: _timeFocus,
                    prefixIcon: Icons.schedule,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.schedule, color: Theme.of(context).colorScheme.secondary),
                      onPressed: _pickTime,
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  focusNode: _serviceFocus,
                  value: _serviceType,
                  items: const [
                    DropdownMenuItem(value: 'Vaccine', child: Text('Vaccine')),
                    DropdownMenuItem(value: 'Review', child: Text('Review')),
                  ],
                  onChanged: (v) => setState(() => _serviceType = v),
                  decoration: _focusedDecoration(
                    context,
                    label: 'Service type',
                    node: _serviceFocus,
                    prefixIcon: Icons.medical_services,
                  ),
                  iconEnabledColor: Theme.of(context).colorScheme.secondary,
                  validator: (v) => v == null ? 'Please select a service type' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  focusNode: _notesFocus,
                  controller: _notes,
                  decoration: _focusedDecoration(
                    context,
                    label: 'Notes',
                    node: _notesFocus,
                    prefixIcon: Icons.notes,
                  ),
                  maxLines: 3,
                ),
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
      ),
    );
  }
}
