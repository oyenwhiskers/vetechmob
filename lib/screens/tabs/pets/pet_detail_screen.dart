import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _onChangePhoto(Pet p) async {
    // Offer camera on mobile, gallery on all platforms
    final picker = ImagePicker();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
              if (p.petImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove current photo'),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'remove') {
      setState(() => _uploadingImage = true);
      final err = await context.read<PetProvider>().updatePet(
        p.id,
        removePetImage: true, // handled via service field
      );
      setState(() => _uploadingImage = false);
      if (err != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      } else {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo removed')));
      }
      return;
    }

    final source = action == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);

    // Prefer bytes upload to work on all platforms including Web
    final bytes = await picked.readAsBytes();
    final err = await context.read<PetProvider>().updatePet(
      p.id,
      petImageBytes: bytes,
      petImageName: picked.name,
    );
    setState(() => _uploadingImage = false);

    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Photo updated')));
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  String _getLocationDisplay(Treatment treatment) {
    if (treatment.treatmentLocation.toLowerCase() == 'government') {
      return 'DVS Sandakan';
    } else if (treatment.treatmentLocation.toLowerCase() == 'collaborator') {
      // Show clinic name if available, otherwise show 'Private Clinic'
      if (treatment.collaborator?.clinicName != null &&
          treatment.collaborator!.clinicName!.isNotEmpty) {
        return treatment.collaborator!.clinicName!;
      }
      return 'Private Clinic';
    }
    return treatment.treatmentLocation;
  }

  void _showTreatmentDetails(Treatment treatment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.red,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Treatment Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            Text(
                              _formatDate(treatment.treatmentDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Diagnosis
                  _buildDetailRow(
                    'Diagnosis',
                    treatment.diagnosis,
                    Icons.medical_information_outlined,
                  ),

                  // Disease
                  if (treatment.disease != null &&
                      treatment.disease!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Disease',
                      treatment.disease!,
                      Icons.coronavirus_outlined,
                    ),
                  ],

                  // Location
                  if (treatment.treatmentLocation.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Location',
                      _getLocationDisplay(treatment),
                      Icons.location_on_outlined,
                    ),
                  ],

                  // Medicine
                  if (treatment.medicinePrescribed != null &&
                      treatment.medicinePrescribed!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Medicine Prescribed',
                      treatment.medicinePrescribed!,
                      Icons.medication_outlined,
                    ),
                  ],

                  // Dosage
                  if (treatment.dosage != null &&
                      treatment.dosage!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Dosage',
                      treatment.dosage!,
                      Icons.medical_services_outlined,
                    ),
                  ],

                  // Notes
                  if (treatment.notes != null &&
                      treatment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Notes',
                      treatment.notes!,
                      Icons.note_outlined,
                    ),
                  ],

                  // Collaborator
                  if (treatment.collaborator != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1E3A8A,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF1E3A8A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Veterinarian',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dr ${treatment.collaborator!.name}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              if (treatment.collaborator!.clinicName !=
                                  null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  treatment.collaborator!.clinicName!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showQRCodeDialog(Pet pet) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pet Tag QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: pet.tag!.tagCode,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Tag Code
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      pet.tag!.tagCode,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pet Info
              Text(
                pet.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Text(
                pet.breed != null && pet.breed!.isNotEmpty
                    ? '${pet.species} • ${pet.breed}'
                    : pet.species,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Release Tag Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReleaseTagDialog(pet);
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Release Tag'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReleaseTagDialog(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Release Tag',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),

              // Content
              Text(
                'Are you sure you want to release tag ${pet.tag!.tagCode} from ${pet.name}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF1E3A8A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Release',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _releaseTag(pet);
    }
  }

  Future<void> _releaseTag(Pet pet) async {
    try {
      final provider = Provider.of<PetProvider>(context, listen: false);
      await provider.releaseTag(pet.id);

      // Reload pet data to update the UI
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag released from ${pet.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to release tag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditPetDialog(Pet pet) async {
    final nameController = TextEditingController(text: pet.name);
    final speciesController = TextEditingController(text: pet.species);
    final breedController = TextEditingController(text: pet.breed ?? '');
    final ageController = TextEditingController(
      text: pet.age?.toString() ?? '',
    );
    final genderController = TextEditingController(text: pet.gender ?? '');
    final statusController = TextEditingController(text: pet.status ?? 'alive');
    final colorController = TextEditingController(text: pet.color ?? '');
    final weightController = TextEditingController(
      text: pet.weight?.toString() ?? '',
    );
    final microchipController = TextEditingController(
      text: pet.microchipId ?? '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC1E8F7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        color: Color(0xFF1E3A8A),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Edit Pet Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                        color: const Color(0xFF1E3A8A),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Name *',
                              prefixIcon: const Icon(Icons.pets),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: speciesController,
                            decoration: InputDecoration(
                              labelText: 'Species *',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: breedController,
                            decoration: InputDecoration(
                              labelText: 'Breed',
                              prefixIcon: const Icon(Icons.info_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age (years)',
                              prefixIcon: const Icon(Icons.cake),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: genderController,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: const Icon(Icons.wc),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: statusController.text.isEmpty
                                ? 'alive'
                                : statusController.text,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.pets),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'alive',
                                child: Text('Alive'),
                              ),
                              DropdownMenuItem(
                                value: 'deceased',
                                child: Text('Deceased'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                statusController.text = value;
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: colorController,
                            decoration: InputDecoration(
                              labelText: 'Color',
                              prefixIcon: const Icon(Icons.palette),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              prefixIcon: const Icon(Icons.monitor_weight),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: microchipController,
                            decoration: InputDecoration(
                              labelText: 'Microchip ID',
                              prefixIcon: const Icon(Icons.memory_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Extract values before disposing controllers
      if (result == true && mounted) {
        final name = nameController.text;
        final species = speciesController.text;
        final breed = breedController.text;
        final age = ageController.text;
        final gender = genderController.text;
        final status = statusController.text;
        final color = colorController.text;
        final weight = weightController.text;
        final microchip = microchipController.text;

        await _updatePet(
          pet.id,
          name,
          species,
          breed,
          age,
          gender,
          status,
          color,
          weight,
          microchip,
        );
      }
    } finally {
      // Always dispose controllers to prevent memory leaks
      nameController.dispose();
      speciesController.dispose();
      breedController.dispose();
      ageController.dispose();
      genderController.dispose();
      statusController.dispose();
      colorController.dispose();
      weightController.dispose();
      microchipController.dispose();
    }
  }

  Future<void> _updatePet(
    int id,
    String name,
    String species,
    String breed,
    String age,
    String gender,
    String status,
    String color,
    String weight,
    String microchip,
  ) async {
    try {
      final provider = Provider.of<PetProvider>(context, listen: false);
      final error = await provider.updatePet(
        id,
        name: name.trim(),
        species: species.trim(),
        breed: breed.trim().isEmpty ? null : breed.trim(),
        age: age.trim().isEmpty ? null : int.tryParse(age.trim()),
        gender: gender.trim().isEmpty ? null : gender.trim(),
        status: status.trim().isEmpty ? 'alive' : status.trim(),
        color: color.trim().isEmpty ? null : color.trim(),
        weight: weight.trim().isEmpty ? null : double.tryParse(weight.trim()),
        microchipId: microchip.trim().isEmpty ? null : microchip.trim(),
      );

      if (error == null) {
        await _load(); // Reload pet data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update pet: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update pet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeletePetDialog(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Pet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete ${pet.name}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF1E3A8A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _deletePet(pet);
    }
  }

  Future<void> _deletePet(Pet pet) async {
    try {
      final provider = Provider.of<PetProvider>(context, listen: false);
      final error = await provider.deletePet(pet.id);

      if (error == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Go back to pets list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pet.name} has been deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete pet: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete pet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC1E8F7);
    const accentColor = Color(0xFF1E3A8A);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final p = _pet;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pet not found')),
      );
    }

    final speciesLower = p.species.toLowerCase();
    final isDogOrCat = speciesLower == 'dog' || speciesLower == 'cat';
    final speciesIcon = speciesLower == 'dog'
        ? FontAwesomeIcons.dog
        : speciesLower == 'cat'
        ? FontAwesomeIcons.cat
        : Icons.cruelty_free;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(p.name),
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeletePetDialog(p),
            tooltip: 'Delete Pet',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditPetDialog(p),
            tooltip: 'Edit Pet',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Pet Avatar
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 30, top: 10),
                child: Column(
                  children: [
                    // Pet Avatar (tap to change)
                    GestureDetector(
                      onTap: () => _onChangePhoto(p),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: p.isDeceased
                              ? Border.all(
                                  color: Colors.grey.shade400,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: ClipOval(
                          child: p.petImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: p.petImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.white,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: isDogOrCat
                                              ? FaIcon(
                                                  speciesIcon,
                                                  size: 50,
                                                  color: accentColor,
                                                )
                                              : Icon(
                                                  speciesIcon,
                                                  size: 50,
                                                  color: accentColor,
                                                ),
                                        ),
                                      ),
                                )
                              : Container(
                                  color: Colors.white,
                                  child: Center(
                                    child: isDogOrCat
                                        ? FaIcon(
                                            speciesIcon,
                                            size: 50,
                                            color: accentColor,
                                          )
                                        : Icon(
                                            speciesIcon,
                                            size: 50,
                                            color: accentColor,
                                          ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (p.isDeceased) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Deceased',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (_uploadingImage)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.breed != null && p.breed!.isNotEmpty
                          ? '${_capitalize(p.species)} • ${p.breed}'
                          : _capitalize(p.species),
                      style: TextStyle(
                        fontSize: 16,
                        color: accentColor.withValues(alpha: 0.8),
                      ),
                    ),
                    if (p.tag != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _showQRCodeDialog(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code_2,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tag ${p.tag!.tagCode}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Pet Information Cards
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info Section
                    _buildSectionTitle('Basic Information', Icons.info_outline),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (p.age != null)
                            _buildInfoRow(
                              Icons.cake_outlined,
                              'Age',
                              '${p.age} ${p.age == 1 ? 'year' : 'years'} old',
                            ),
                          if (p.age != null && p.gender != null)
                            const Divider(height: 24),
                          if (p.gender != null)
                            _buildInfoRow(
                              Icons.wc_outlined,
                              'Gender',
                              _capitalize(p.gender!),
                            ),
                          if (p.gender != null && p.color != null)
                            const Divider(height: 24),
                          if (p.color != null)
                            _buildInfoRow(
                              Icons.palette_outlined,
                              'Color',
                              p.color!,
                            ),
                          if (p.color != null && p.weight != null)
                            const Divider(height: 24),
                          if (p.weight != null)
                            _buildInfoRow(
                              Icons.monitor_weight_outlined,
                              'Weight',
                              '${p.weight} kg',
                            ),
                          if (p.weight != null && p.microchipId != null)
                            const Divider(height: 24),
                          if (p.microchipId != null)
                            _buildInfoRow(
                              Icons.memory_outlined,
                              'Microchip ID',
                              p.microchipId!,
                            ),
                        ],
                      ),
                    ),

                    // Medical Notes (if any)
                    if (p.medicalNotes != null &&
                        p.medicalNotes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Medical Notes',
                        Icons.medical_information_outlined,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          p.medicalNotes!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],

                    // Medical Treatments Section
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      'Medical Treatments',
                      Icons.local_hospital_outlined,
                    ),
                    const SizedBox(height: 12),

                    if (_treatments.isEmpty)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No treatments recorded',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._treatments.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showTreatmentDetails(t),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.local_hospital,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.diagnosis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: Color(0xFF1E3A8A),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatDate(
                                                      t.treatmentDate,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (t.treatmentLocation.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _getLocationDisplay(t),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (t.collaborator != null) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: accentColor.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 16,
                                                  color: accentColor,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Dr ${t.collaborator!.name}',
                                                  style: TextStyle(
                                                    color: accentColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (t.treatmentLocation
                                                  .toLowerCase() ==
                                              'collaborator') ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.business_outlined,
                                                    size: 16,
                                                    color:
                                                        Colors.orange.shade700,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Collaborator',
                                                    style: TextStyle(
                                                      color: Colors
                                                          .orange
                                                          .shade700,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Vitals Section (Weight & Temperature trends)
                    if (_treatments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Vitals',
                        Icons.monitor_heart_outlined,
                      ),
                      const SizedBox(height: 12),
                      _VitalsCharts(treatments: _treatments),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    const accentColor = Color(0xFF1E3A8A);
    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    const accentColor = Color(0xFF1E3A8A);
    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _VitalsCharts extends StatelessWidget {
  final List<Treatment> treatments;
  const _VitalsCharts({required this.treatments});

  List<Treatment> _sorted(List<Treatment> list) {
    final copy = [...list];
    copy.sort((a, b) {
      DateTime ad;
      DateTime bd;
      try {
        ad = DateTime.parse(a.treatmentDate);
      } catch (_) {
        ad = DateTime.fromMillisecondsSinceEpoch(0);
      }
      try {
        bd = DateTime.parse(b.treatmentDate);
      } catch (_) {
        bd = DateTime.fromMillisecondsSinceEpoch(0);
      }
      return ad.compareTo(bd);
    });
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted(treatments);
    final weightPoints = <double>[];
    final weightLabels = <String>[];
    final tempPoints = <double>[];
    final tempLabels = <String>[];

    for (final t in sorted) {
      // Weight
      if (t.weight != null) {
        weightPoints.add(t.weight!);
        weightLabels.add(_shortDate(t.treatmentDate));
      }
      // Temperature
      if (t.temperature != null) {
        tempPoints.add(t.temperature!);
        tempLabels.add(_shortDate(t.treatmentDate));
      }
    }

    if (weightPoints.isEmpty && tempPoints.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(24),
        child: Text(
          'No vitals recorded',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weightPoints.isNotEmpty) ...[
          _MiniChartCard(
            title: 'Weight (kg)',
            color: const Color(0xFF1E3A8A),
            values: weightPoints,
            labels: weightLabels,
            valueSuffix: 'kg',
          ),
          const SizedBox(height: 12),
        ],
        if (tempPoints.isNotEmpty)
          _MiniChartCard(
            title: 'Temperature (°C)',
            color: Colors.orange.shade700,
            values: tempPoints,
            labels: tempLabels,
            valueSuffix: '°C',
          ),
      ],
    );
  }

  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('MMMd').format(d);
    } catch (_) {
      return iso;
    }
  }
}

class _MiniChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<double> values;
  final List<String> labels;
  final String valueSuffix;

  const _MiniChartCard({
    required this.title,
    required this.color,
    required this.values,
    required this.labels,
    required this.valueSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              Text(
                values.isNotEmpty
                    ? '${values.last.toStringAsFixed(2)} $valueSuffix'
                    : '-',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: _MiniLineChart(
              values: values,
              labels: labels,
              lineColor: color,
              minY: minVal,
              maxY: maxVal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final double minY;
  final double maxY;

  const _MiniLineChart({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final ui.TextDirection dir = Directionality.of(context);
    return CustomPaint(
      painter: _LineChartPainter(
        values: values,
        labels: labels,
        lineColor: lineColor,
        minY: minY,
        maxY: maxY,
        textDirection: dir,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final double minY;
  final double maxY;
  final ui.TextDirection textDirection;

  _LineChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.minY,
    required this.maxY,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 28.0;
    final chartRect = Rect.fromLTWH(
      padding,
      8,
      size.width - padding - 8,
      size.height - 8 - 28,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFFF7FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(chartRect, const Radius.circular(8)),
      bgPaint,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.4)
      ..strokeWidth = 1;
    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final dy = chartRect.top + chartRect.height * (i / gridLines);
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
    }

    if (values.length < 1) return;

    final range = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY);
    final dx = values.length == 1 ? 0.0 : chartRect.width / (values.length - 1);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = chartRect.left + dx * i;
      final norm = (values[i] - minY) / range;
      final y = chartRect.bottom - norm * chartRect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < values.length; i++) {
      final x =
          chartRect.left + (values.length == 1 ? chartRect.width / 2 : dx * i);
      final norm = (values[i] - minY) / range;
      final y = chartRect.bottom - norm * chartRect.height;
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }

    // Y labels (min/max)
    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: textDirection,
    );
    final minLabel = minY.toStringAsFixed(2);
    final maxLabel = maxY.toStringAsFixed(2);
    textPainter.text = TextSpan(
      text: maxLabel,
      style: const TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout(maxWidth: padding - 6);
    textPainter.paint(
      canvas,
      Offset(0, chartRect.top - textPainter.height / 2),
    );
    textPainter.text = TextSpan(
      text: minLabel,
      style: const TextStyle(fontSize: 10, color: Colors.black54),
    );
    textPainter.layout(maxWidth: padding - 6);
    textPainter.paint(
      canvas,
      Offset(0, chartRect.bottom - textPainter.height / 2),
    );

    // X labels (first/last)
    if (labels.isNotEmpty) {
      final first = labels.first;
      final last = labels.last;
      final tpFirst = TextPainter(
        text: TextSpan(
          text: first,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        textDirection: textDirection,
      )..layout(maxWidth: chartRect.width / 2);
      tpFirst.paint(canvas, Offset(chartRect.left, chartRect.bottom + 4));

      final tpLast = TextPainter(
        text: TextSpan(
          text: last,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        textDirection: textDirection,
      )..layout(maxWidth: chartRect.width / 2);
      tpLast.paint(
        canvas,
        Offset(chartRect.right - tpLast.width, chartRect.bottom + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
