class BookingPet {
  final int id;
  final String name;
  final String? species;
  BookingPet({required this.id, required this.name, this.species});
  factory BookingPet.fromJson(Map<String, dynamic> json) => BookingPet(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    species: json['species'] as String?,
  );
}

class Booking {
  final int id;
  final BookingPet pet;
  final String bookingDate;
  final String bookingTime;
  final String serviceType;
  final String status;
  final String? notes;
  final bool isAppointment;

  Booking({
    required this.id,
    required this.pet,
    required this.bookingDate,
    required this.bookingTime,
    required this.serviceType,
    required this.status,
    this.notes,
    this.isAppointment = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as int,
    pet: BookingPet.fromJson(json['pet'] as Map<String, dynamic>),
    bookingDate: json['booking_date'] as String? ?? '',
    bookingTime: json['booking_time'] as String? ?? '',
    serviceType: json['service_type'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    notes: json['notes'] as String?,
    isAppointment: json['is_appointment'] as bool? ?? false,
  );
}
