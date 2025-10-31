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

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _color.dispose();
    _weight.dispose();
    _microchip.dispose();
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
      weight: _weight.text.trim().isEmpty
          ? null
          : double.tryParse(_weight.text.trim()),
      microchipId: _microchip.text.trim().isEmpty
          ? null
          : _microchip.text.trim(),
      medicalNotes: null,
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
    const primaryColor = Color(0xFFC1E8F7);
    const accentColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Pet'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Icon
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets, size: 50, color: accentColor),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add Your Pet',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in the details below',
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    _buildSectionTitle('Basic Information', Icons.info_outline),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _name,
                      label: 'Pet Name',
                      hint: 'e.g., Max, Bella',
                      icon: Icons.badge_outlined,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Pet name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      label: 'Species',
                      value: _species,
                      icon: Icons.category_outlined,
                      items: const [
                        DropdownMenuItem(value: 'dog', child: Text('Dog')),
                        DropdownMenuItem(value: 'cat', child: Text('Cat')),
                      ],
                      onChanged: (v) => setState(() => _species = v ?? 'dog'),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _breed,
                      label: 'Breed',
                      hint: 'e.g., Golden Retriever',
                      icon: Icons.pets_outlined,
                    ),

                    const SizedBox(height: 24),

                    // Physical Details Section
                    _buildSectionTitle(
                      'Physical Details',
                      Icons.fitness_center_outlined,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _age,
                            label: 'Age',
                            hint: 'Years',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Gender',
                            value: _gender,
                            icon: Icons.wc_outlined,
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Select'),
                              ),
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _color,
                            label: 'Color',
                            hint: 'e.g., Brown',
                            icon: Icons.palette_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _weight,
                            label: 'Weight (kg)',
                            hint: 'kg',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _microchip,
                      label: 'Microchip Number',
                      hint: 'e.g., 9851 0000 1234 567',
                      icon: Icons.memory_outlined,
                      keyboardType: TextInputType.text,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Pet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    const accentColor = Color(0xFF1E3A8A);

    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    const primaryColor = Color(0xFFC1E8F7);
    const accentColor = Color(0xFF1E3A8A);

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 22, color: accentColor),
        filled: true,
        fillColor: primaryColor.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    const primaryColor = Color(0xFFC1E8F7);
    const accentColor = Color(0xFF1E3A8A);

    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: accentColor),
        filled: true,
        fillColor: primaryColor.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
