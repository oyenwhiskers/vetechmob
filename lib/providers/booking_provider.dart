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

  Future<void> fetch({String? status, int? petId, String? date}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
  _bookings = await _service.getBookings(status: status, petId: petId, date: date);

      // Sort results for better UX
      // When viewing All: prioritize by status (pending > confirmed > completed > cancelled),
      // then by soonest date/time.
      // When viewing a specific status: sort by soonest date/time only.
      int statusPriority(String s) {
        switch (s.toLowerCase()) {
          case 'pending':
            return 0;
          case 'confirmed':
            return 1;
          case 'completed':
            return 2;
          case 'cancelled':
            return 3;
          default:
            return 4;
        }
      }

      DateTime toWallDateTime(Booking b) {
        // Parse date (YYYY-MM-DD or ISO)
        DateTime date;
        try {
          date = DateTime.parse(b.bookingDate);
        } catch (_) {
          // Fallback manual parse
          final p = b.bookingDate.split('-');
          if (p.length == 3) {
            date = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
          } else {
            date = DateTime.now();
          }
        }

        // Parse time (HH:mm or ISO) but keep wall-clock (no TZ shift)
        int hour = 0;
        int minute = 0;
        try {
          if (b.bookingTime.contains('T')) {
            final dt = DateTime.parse(b.bookingTime);
            hour = dt.hour;
            minute = dt.minute;
          } else {
            final tp = b.bookingTime.split(':');
            if (tp.length >= 2) {
              hour = int.parse(tp[0]);
              minute = int.parse(tp[1]);
            }
          }
        } catch (_) {
          // keep defaults
        }
        return DateTime(date.year, date.month, date.day, hour, minute);
      }

      _bookings.sort((a, b) {
        if (status == null) {
          final sa = statusPriority(a.status);
          final sb = statusPriority(b.status);
          if (sa != sb) return sa.compareTo(sb);
        }
        // Same status or specific filter: compare by date/time ascending
        return toWallDateTime(a).compareTo(toWallDateTime(b));
      });
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
