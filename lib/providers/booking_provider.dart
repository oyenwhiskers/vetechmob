import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final _service = BookingService();
  List<Booking> _bookings = [];
  bool _loading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetch({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _service.getBookings(status: status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> create({
    required int petId,
    required String date,
    required String time,
    required String serviceType,
    String? notes,
  }) async {
    try {
      _loading = true;
      notifyListeners();
      final b = await _service.createBooking(
        petId: petId,
        bookingDate: date,
        bookingTime: time,
        serviceType: serviceType,
        notes: notes,
      );
      _bookings = [b, ..._bookings];
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> cancel(int id) async {
    try {
      await _service.cancelBooking(id);
      _bookings = _bookings.where((b) => b.id != id).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
