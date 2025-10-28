import 'package:flutter/foundation.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final _service = DashboardService();
  DashboardData? _data;
  bool _loading = false;
  String? _error;

  DashboardData? get data => _data;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _service.getDashboard();

      // Sort recent bookings by status priority then latest created first
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

      final sortedRecent = [...raw.recentBookings];
      sortedRecent.sort((a, b) {
        final sa = statusPriority(a.status);
        final sb = statusPriority(b.status);
        if (sa != sb) return sa.compareTo(sb);

        // Prefer latest created first. Use ID desc as a stable proxy.
        final idComp = b.id.compareTo(a.id);
        if (idComp != 0) return idComp;

        // Fallback to date/time desc (latest/most recent first)
        DateTime parseDate(String s) {
          try {
            return DateTime.parse(s);
          } catch (_) {
            final p = s.split('-');
            if (p.length == 3) {
              return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
            }
            return DateTime(1970);
          }
        }
        DateTime parseTime(String s) {
          try {
            if (s.contains('T')) {
              final dt = DateTime.parse(s);
              return DateTime(2000, 1, 1, dt.hour, dt.minute);
            }
            final tp = s.split(':');
            if (tp.length >= 2) {
              return DateTime(2000, 1, 1, int.parse(tp[0]), int.parse(tp[1]));
            }
          } catch (_) {}
          return DateTime(2000);
        }
        final da = parseDate(a.bookingDate);
        final db = parseDate(b.bookingDate);
        final ta = parseTime(a.bookingTime);
        final tb = parseTime(b.bookingTime);
        final aDT = DateTime(da.year, da.month, da.day, ta.hour, ta.minute);
        final bDT = DateTime(db.year, db.month, db.day, tb.hour, tb.minute);
        return bDT.compareTo(aDT);
      });

      _data = DashboardData(
        statistics: raw.statistics,
        nextBooking: raw.nextBooking,
        recentBookings: sortedRecent,
        pets: raw.pets,
      );
    } catch (e) {
      _error = _extractErrorMessage(e);
      print('❌ DashboardProvider fetch error: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(Object e) {
    try {
      final errorStr = e.toString();
      if (errorStr.contains('500')) {
        return 'Server error (500). Backend needs fixing.';
      }
      if (errorStr.contains('timeout')) {
        return 'Connection timeout (20s). Server is slow or down.';
      }
      if (errorStr.contains('401')) {
        return 'Authentication failed. Please login again.';
      }
      if (errorStr.contains('404')) {
        return 'Dashboard endpoint not found (404).';
      }
      return errorStr;
    } catch (_) {
      return 'Unknown error occurred';
    }
  }
}
