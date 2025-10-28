import '../models/booking.dart';
import 'api_client.dart';

class BookingService {
  final _api = ApiClient();

  Future<List<Booking>> getBookings({String? status, int? petId, String? date}) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (petId != null) query['pet_id'] = petId;
    if (date != null) query['date'] = date;
    final res = await _api.get('/bookings', query: query.isEmpty ? null : query);
    final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> createBooking({
    required int petId,
    required String bookingDate,
    required String bookingTime,
    required String serviceType,
    String? notes,
  }) async {
    final payload = {
      'pet_id': petId,
      'booking_date': bookingDate,
      'booking_time': bookingTime,
      'service_type': serviceType,
      if (notes != null) 'notes': notes,
    };
    final res = await _api.post('/bookings', data: payload);
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Booking.fromJson(data);
  }

  Future<Booking> getBookingDetails(int id) async {
    final res = await _api.get('/bookings/$id');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Booking.fromJson(data);
  }

  Future<Booking> updateBooking(int id, {
    String? bookingDate,
    String? bookingTime,
    String? serviceType,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (bookingDate != null) payload['booking_date'] = bookingDate;
    if (bookingTime != null) payload['booking_time'] = bookingTime;
    if (serviceType != null) payload['service_type'] = serviceType;
    if (notes != null) payload['notes'] = notes;

    final res = await _api.put('/bookings/$id', data: payload);
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Booking.fromJson(data);
  }

  Future<void> cancelBooking(int id) async {
    await _api.delete('/bookings/$id');
  }
}
