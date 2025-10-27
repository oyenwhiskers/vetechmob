import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final _service = ProfileService();
  AppUser? _user;
  CustomerProfile? _customer;
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  CustomerProfile? get customer => _customer;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final (u, c, s) = await _service.getProfile();
      _user = u;
      _customer = c;
      _stats = s;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> update({String? name, String? phone, String? address, String? email}) async {
    try {
      _loading = true;
      notifyListeners();
      final (u, c) = await _service.updateProfile(name: name, phone: phone, address: address, email: email);
      _user = u;
      _customer = c;
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword(String current, String next) async {
    try {
      await _service.updatePassword(currentPassword: current, newPassword: next);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteAccount(String password) async {
    try {
      await _service.deleteAccount(password: password);
      _user = null;
      _customer = null;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
