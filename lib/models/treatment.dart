class Collaborator {
  final int id;
  final String name;
  final String? clinicName;
  final String? phone;
  final String? address;

  Collaborator({required this.id, required this.name, this.clinicName, this.phone, this.address});

  factory Collaborator.fromJson(Map<String, dynamic> json) => Collaborator(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        clinicName: json['clinic_name'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
      );
}

class Treatment {
  final int id;
  final String treatmentDate;
  final String treatmentLocation;
  final String diagnosis;
  final String? disease;
  final String? medicinePrescribed;
  final String? dosage;
  final String? notes;
  final Collaborator? collaborator;
  final double? weight;
  final double? temperature;

  Treatment({
    required this.id,
    required this.treatmentDate,
    required this.treatmentLocation,
    required this.diagnosis,
    this.disease,
    this.medicinePrescribed,
    this.dosage,
    this.notes,
    this.collaborator,
    this.weight,
    this.temperature,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) => Treatment(
        id: json['id'] as int,
        treatmentDate: json['treatment_date'] as String? ?? '',
        treatmentLocation: json['treatment_location'] as String? ?? '',
        diagnosis: json['diagnosis'] as String? ?? '',
        disease: json['disease'] as String?,
        medicinePrescribed: json['medicine_prescribed'] as String?,
        dosage: json['dosage'] as String?,
        notes: json['notes'] as String?,
        collaborator: json['collaborator'] != null ? Collaborator.fromJson(json['collaborator'] as Map<String, dynamic>) : null,
        weight: _toDouble(json['weight']),
        temperature: _toDouble(json['temperature']),
      );
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final parsed = double.tryParse(v);
    return parsed;
  }
  return null;
}
