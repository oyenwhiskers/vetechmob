class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;

  AppUser({required this.id, required this.name, required this.email, required this.role});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'customer',
      );
}

class CustomerProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? icNumber;
  final String? address;

  CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.icNumber,
    this.address,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        icNumber: json['ic_number'] as String?,
        address: json['address'] as String?,
      );
}
