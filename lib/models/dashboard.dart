import 'booking.dart';
import 'pet.dart';

class DashboardStatistics {
  final int totalPets;
  final int totalBookings;
  final int upcomingBookings;
  final int totalTreatments;

  DashboardStatistics({
    required this.totalPets,
    required this.totalBookings,
    required this.upcomingBookings,
    required this.totalTreatments,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) => DashboardStatistics(
        totalPets: json['total_pets'] as int? ?? 0,
        totalBookings: json['total_bookings'] as int? ?? 0,
        upcomingBookings: json['upcoming_bookings'] as int? ?? 0,
        totalTreatments: json['total_treatments'] as int? ?? 0,
      );
}

class DashboardData {
  final DashboardStatistics statistics;
  final Booking? nextBooking;
  final List<Booking> recentBookings;
  final List<Pet> pets;

  DashboardData({
    required this.statistics,
    this.nextBooking,
    required this.recentBookings,
    required this.pets,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        statistics: DashboardStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
        nextBooking: json['next_booking'] != null ? Booking.fromJson(json['next_booking'] as Map<String, dynamic>) : null,
        recentBookings: (json['recent_bookings'] as List<dynamic>? ?? [])
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList(),
        pets: (json['pets'] as List<dynamic>? ?? [])
            .map((e) => Pet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
