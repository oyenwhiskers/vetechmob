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
      _data = await _service.getDashboard();
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
