class PetTag {
  final int id;
  final String tagCode;
  final String status;
  final String? qrCodeUrl;
  final String? issuedDate;

  PetTag({required this.id, required this.tagCode, required this.status, this.qrCodeUrl, this.issuedDate});

  factory PetTag.fromJson(Map<String, dynamic> json) => PetTag(
        id: json['id'] as int,
        tagCode: json['tag_code']?.toString() ?? '',
        status: json['status']?.toString() ?? 'active',
        qrCodeUrl: json['qr_code_url'] as String?,
        issuedDate: json['issued_date'] as String?,
      );
}

class Pet {
  final int id;
  final String name;
  final String species;
  final String? breed;
  final int? age;
  final String? gender;
  final String? color;
  final double? weight;
  final String? microchipId;
  final String? medicalNotes;
  final PetTag? tag;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.age,
    this.gender,
    this.color,
    this.weight,
    this.microchipId,
    this.medicalNotes,
    this.tag,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        species: json['species'] as String? ?? '',
        breed: json['breed'] as String?,
        age: json['age'] is int ? json['age'] as int : int.tryParse('${json['age']}'),
        gender: json['gender'] as String?,
        color: json['color'] as String?,
        weight: json['weight'] is num ? (json['weight'] as num).toDouble() : double.tryParse('${json['weight']}'),
        microchipId: json['microchip_id'] as String?,
        medicalNotes: json['medical_notes'] as String?,
        tag: json['tag'] != null ? PetTag.fromJson(json['tag'] as Map<String, dynamic>) : null,
      );
}
