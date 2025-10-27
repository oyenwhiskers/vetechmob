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
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
