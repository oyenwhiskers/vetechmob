import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Allow all status codes so we can handle errors gracefully
      validateStatus: (status) => true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Debug logging
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔵 REQUEST: ${options.method} ${options.uri}');
        print('📤 Headers: ${options.headers}');
        print('📦 Data: ${options.data}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Debug logging
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🟢 RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        print('📥 Data: ${response.data}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        handler.next(response);
      },
      onError: (e, handler) {
        // Debug logging with detailed error info
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔴 ERROR: ${e.requestOptions.method} ${e.requestOptions.uri}');
        print('❌ Status: ${e.response?.statusCode}');
        print('📥 Response data: ${e.response?.data}');
        print('📄 Error message: ${e.message}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        handler.next(e);
      },
    ));
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static Future<String?> _readToken() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: AppConstants.tokenStorageKey);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) async {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {Object? data}) async {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {Object? data}) async {
    return _dio.delete<T>(path, data: data);
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenStorageKey, value: token);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: AppConstants.tokenStorageKey);
  }
}
