import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';
import 'api_client.dart';

class ProfileService {
  final _api = ApiClient();

  Future<(AppUser, CustomerProfile, Map<String, dynamic>)> getProfile() async {
    final res = await _api.get('/profile');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    final customer = CustomerProfile.fromJson(data['customer'] as Map<String, dynamic>);
    final stats = (data['stats'] as Map<String, dynamic>? ?? {});
    return (user, customer, stats);
  }

  Future<(AppUser, CustomerProfile)> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? email,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;
    if (email != null) payload['email'] = email;

    final res = await _api.put('/profile', data: payload);
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    final customer = CustomerProfile.fromJson(data['customer'] as Map<String, dynamic>);
    return (user, customer);
  }

  Future<(AppUser, CustomerProfile)> updateProfileImage({
    Uint8List? imageBytes,
    String? fileName,
    bool removeImage = false,
  }) async {
    final form = FormData();
    if (removeImage) {
      form.fields.add(const MapEntry('remove_profile_image', '1'));
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final name = (fileName == null || fileName.isEmpty) ? 'avatar.jpg' : fileName;
      final lower = name.toLowerCase();
      MediaType contentType;
      if (lower.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (lower.endsWith('.gif')) {
        contentType = MediaType('image', 'gif');
      } else if (lower.endsWith('.svg')) {
        contentType = MediaType('image', 'svg+xml');
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else {
        contentType = MediaType('application', 'octet-stream');
      }
      form.files.add(MapEntry(
        'profile_image',
        MultipartFile.fromBytes(imageBytes, filename: name, contentType: contentType),
      ));
    }
    form.fields.add(const MapEntry('_method', 'PUT'));
    final res = await _api.post('/profile', data: form);
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    final customer = CustomerProfile.fromJson(data['customer'] as Map<String, dynamic>);
    return (user, customer);
  }

  Future<void> updatePassword({required String currentPassword, required String newPassword}) async {
    await _api.put('/profile/password', data: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    });
  }

  Future<void> deleteAccount({required String password}) async {
    await _api.delete('/profile', data: {
      'password': password,
    });
    await _api.clearToken();
  }
}
