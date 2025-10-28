import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  CustomerProfile? _customer;
  bool _loading = false;

  AppUser? get user => _user;
  CustomerProfile? get customer => _customer;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null && _customer != null;

  Future<void> tryAutoLogin() async {
    try {
      _loading = true;
      notifyListeners();
      final (u, c) = await _authService.currentUser();
      _user = u;
      _customer = c;
    } catch (_) {
      _user = null;
      _customer = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      final resp = await _authService.login(email: email, password: password);
      _user = resp.user;
      _customer = resp.customer;
      return null;
    } catch (e) {
      return _extractError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String icNumber,
    required String address,
    required String password,
  }) async {
    try {
      _loading = true;
      notifyListeners();
      final resp = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        icNumber: icNumber,
        address: address,
        password: password,
      );
      _user = resp.user;
      _customer = resp.customer;
      return null;
    } catch (e) {
      return _extractError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _customer = null;
    notifyListeners();
  }

  String _extractError(Object e) {
    try {
      // Handle DioException specifically
      if (e.toString().contains('DioException')) {
        final dioError = e as dynamic;
        if (dioError.response != null) {
          final statusCode = dioError.response.statusCode;
          final data = dioError.response.data;
          
          // Try to extract error message from response
          if (data is Map<String, dynamic>) {
            if (data['message'] != null) {
              return '[$statusCode] ${data['message']}';
            }
            if (data['errors'] != null) {
              final errors = data['errors'] as Map<String, dynamic>;
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                return '[$statusCode] ${firstError.first}';
              }
            }
          }
          
          return 'Server error [$statusCode]: ${data.toString()}';
        }
        return 'Network error: ${dioError.message}';
      }
      return e.toString();
    } catch (_) {
      return 'Something went wrong: ${e.toString()}';
    }
  }
}
