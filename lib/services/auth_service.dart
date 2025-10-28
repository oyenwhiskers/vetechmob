import '../models/user.dart';
import 'api_client.dart';

class AuthResponse {
  final AppUser user;
  final CustomerProfile customer;
  final String token;

  AuthResponse({required this.user, required this.customer, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        customer: CustomerProfile.fromJson(json['customer'] as Map<String, dynamic>),
        token: json['token'] as String,
      );
}

class AuthService {
  final _api = ApiClient();

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String icNumber,
    required String address,
    required String password,
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'phone': phone,
      'ic_number': icNumber.replaceAll('-', '').toUpperCase(),
      'address': address,
      'password': password,
      'password_confirmation': password,
    };
    final res = await _api.post('/register', data: payload);
    
    // Check for error status codes
    if (res.statusCode != null && res.statusCode! >= 400) {
      final data = res.data;
      String errorMessage = 'Registration failed';
      
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data['error'] != null) {
          errorMessage = data['error'].toString();
        } else if (data['errors'] != null) {
          // Handle validation errors
          final errors = data['errors'];
          if (errors is Map<String, dynamic>) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            }
          }
        }
      }
      
      throw Exception(errorMessage);
    }
    
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final auth = AuthResponse.fromJson(data);
    await _api.saveToken(auth.token);
    return auth;
  }

  Future<AuthResponse> login({required String email, required String password}) async {
    final res = await _api.post('/login', data: {'email': email, 'password': password});
    
    // Check for error status codes
    if (res.statusCode != null && res.statusCode! >= 400) {
      final data = res.data;
      String errorMessage = 'Login failed';
      
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data['error'] != null) {
          errorMessage = data['error'].toString();
        }
      }
      
      throw Exception(errorMessage);
    }
    
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final auth = AuthResponse.fromJson(data);
    await _api.saveToken(auth.token);
    return auth;
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {
      // ignore server failure on logout
    } finally {
      await _api.clearToken();
    }
  }

  Future<(AppUser, CustomerProfile)> currentUser() async {
    final res = await _api.get('/user');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return (
      AppUser.fromJson(data['user'] as Map<String, dynamic>),
      CustomerProfile.fromJson(data['customer'] as Map<String, dynamic>),
    );
  }
}
