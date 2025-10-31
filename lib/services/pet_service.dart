import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../models/pet.dart';
import '../models/treatment.dart';
import 'api_client.dart';

class PetService {
  final _api = ApiClient();

  Future<List<Pet>> getPets() async {
    final res = await _api.get('/pets');

    // Check for error status codes
    if (res.statusCode != 200) {
      final errorMessage = res.data is Map
          ? (res.data['message'] ?? 'Server error')
          : 'Server error';
      throw Exception(
        'Failed to fetch pets (${res.statusCode}): $errorMessage',
      );
    }

    final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list.map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Pet> createPet({
    required String name,
    required String species,
    String? breed,
    int? age,
    String? gender,
    String? color,
    double? weight,
    String? microchipId,
    String? medicalNotes,
  }) async {
    // Normalize enums to match backend validation
    final allowedSpecies = {'dog', 'cat', 'bird', 'rabbit', 'other'};
    final normSpecies = species.toLowerCase();
    final safeSpecies = allowedSpecies.contains(normSpecies)
        ? normSpecies
        : 'other';
    final normGender = gender?.toLowerCase();
    final allowedGender = {'male', 'female'};
    final safeGender = normGender != null && allowedGender.contains(normGender)
        ? normGender
        : (gender == null ? null : null);

    final payload = <String, dynamic>{
      'name': name,
      'species': safeSpecies,
      if (breed != null) 'breed': breed,
      if (age != null) 'age': age,
      if (safeGender != null) 'gender': safeGender,
      if (color != null) 'color': color,
      if (weight != null) 'weight': weight,
      if (microchipId != null) 'microchip_number': microchipId,
      if (medicalNotes != null) 'medical_notes': medicalNotes,
    };
    final res = await _api.post('/pets', data: payload);

    // Check for error status codes
    if (res.statusCode != 200 && res.statusCode != 201) {
      final errorMessage = res.data is Map
          ? (res.data['message'] ?? 'Server error')
          : 'Server error';
      throw Exception(
        'Failed to create pet (${res.statusCode}): $errorMessage',
      );
    }

    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<Pet> getPetDetails(int id) async {
    final res = await _api.get('/pets/$id');
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<Pet> updatePet(
    int id, {
    String? name,
    String? species,
    String? breed,
    int? age,
    String? gender,
    String? color,
    double? weight,
    String? microchipId,
    String? medicalNotes,
    File? petImageFile,
    Uint8List? petImageBytes,
    String? petImageName,
    bool removePetImage = false,
  }) async {
    FormData formData = FormData();

    if (name != null) formData.fields.add(MapEntry('name', name));
    if (species != null) {
      final allowedSpecies = {'dog', 'cat', 'bird', 'rabbit', 'other'};
      final normSpecies = species.toLowerCase();
      final safeSpecies = allowedSpecies.contains(normSpecies)
          ? normSpecies
          : 'other';
      formData.fields.add(MapEntry('species', safeSpecies));
    }
    if (breed != null) formData.fields.add(MapEntry('breed', breed));
    if (age != null) formData.fields.add(MapEntry('age', age.toString()));
    if (gender != null) {
      final normGender = gender.toLowerCase();
      final allowedGender = {'male', 'female'};
      if (allowedGender.contains(normGender)) {
        formData.fields.add(MapEntry('gender', normGender));
      }
    }
    if (color != null) formData.fields.add(MapEntry('color', color));
    if (weight != null)
      formData.fields.add(MapEntry('weight', weight.toString()));
    if (microchipId != null)
      formData.fields.add(MapEntry('microchip_number', microchipId));
    if (medicalNotes != null)
      formData.fields.add(MapEntry('medical_notes', medicalNotes));
    if (removePetImage)
      formData.fields.add(const MapEntry('remove_pet_image', '1'));

    if (petImageBytes != null && petImageBytes.isNotEmpty) {
      // infer mime type from file name
      final fileName = petImageName ?? 'pet.jpg';
      final lower = fileName.toLowerCase();
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
      formData.files.add(
        MapEntry(
          'pet_image',
          MultipartFile.fromBytes(
            petImageBytes,
            filename: fileName,
            contentType: contentType,
          ),
        ),
      );
    } else if (petImageFile != null) {
      String fileName = petImageFile.path.split('/').last;
      // infer mime type
      final lower = fileName.toLowerCase();
      MediaType? contentType;
      if (lower.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (lower.endsWith('.gif')) {
        contentType = MediaType('image', 'gif');
      } else if (lower.endsWith('.svg')) {
        contentType = MediaType('image', 'svg+xml');
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      }
      formData.files.add(
        MapEntry(
          'pet_image',
          await MultipartFile.fromFile(
            petImageFile.path,
            filename: fileName,
            contentType: contentType,
          ),
        ),
      );
    }

    // Use POST with method spoofing to ensure Laravel processes file uploads
    formData.fields.add(const MapEntry('_method', 'PUT'));
    final res = await _api.post('/pets/$id', data: formData);
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<void> deletePet(int id) async {
    await _api.delete('/pets/$id');
  }

  Future<PetTag> scanAndAssignTag({
    required String tagCode,
    required int petId,
  }) async {
    final res = await _api.post(
      '/pets/scan-tag',
      data: {'tag_code': tagCode, 'pet_id': petId},
    );
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return PetTag.fromJson(data['tag'] as Map<String, dynamic>);
  }

  Future<PetTag> assignTagToPet({
    required int petId,
    required String tagCode,
  }) async {
    try {
      debugPrint('🏷️ Assigning tag: $tagCode to pet: $petId');

      final res = await _api.post(
        '/pets/$petId/assign-tag',
        data: {'tag_code': tagCode},
      );

      debugPrint('📡 Response status: ${res.statusCode}');
      debugPrint('📦 Response data type: ${res.data.runtimeType}');
      debugPrint('📦 Response data: ${res.data}');

      // Check for HTTP errors
      if (res.statusCode == null ||
          res.statusCode! < 200 ||
          res.statusCode! >= 300) {
        final errorMessage = res.data is Map
            ? (res.data['message'] ?? 'Server error')
            : 'Server error';
        throw Exception('HTTP ${res.statusCode}: $errorMessage');
      }

      // Handle response safely
      if (res.data == null) {
        throw Exception('Empty response from server');
      }

      final responseData = res.data as Map<String, dynamic>;
      debugPrint('✅ Parsed response data: $responseData');

      // Check for success flag
      if (responseData['success'] != true) {
        final message = responseData['message'] ?? 'Tag assignment failed';
        throw Exception(message);
      }

      // Get the data object
      if (!responseData.containsKey('data') || responseData['data'] == null) {
        debugPrint('❌ Response structure: ${responseData.keys.toList()}');
        throw Exception(
          'Response missing data field. Got keys: ${responseData.keys.toList()}',
        );
      }

      final data = responseData['data'] as Map<String, dynamic>;
      debugPrint('📋 Data object: $data');
      debugPrint('📋 Data keys: ${data.keys.toList()}');

      // Get the tag from data
      if (!data.containsKey('tag') || data['tag'] == null) {
        debugPrint('❌ Data structure: ${data.keys.toList()}');
        throw Exception(
          'Response missing tag in data. Got keys: ${data.keys.toList()}',
        );
      }

      final tagData = data['tag'] as Map<String, dynamic>;
      debugPrint('🏷️ Tag data: $tagData');

      // Create and return PetTag
      final petTag = PetTag.fromJson(tagData);
      debugPrint('✅ Created PetTag: id=${petTag.id}, code=${petTag.tagCode}');

      return petTag;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in assignTagToPet: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> releaseTagFromPet(int petId) async {
    // Since there's no documented release-tag endpoint, we'll use the update endpoint
    // to set tag_id to null or use a dedicated endpoint if it exists
    try {
      // Try dedicated endpoint first
      await _api.post('/pets/$petId/release-tag', data: {});
    } catch (e) {
      // If that fails, try updating the pet with tag_id: null
      // This may or may not work depending on backend implementation
      throw Exception(
        'Release tag endpoint not available. Backend needs to implement POST /pets/{id}/release-tag',
      );
    }
  }

  Future<List<Treatment>> getPetTreatments(int petId) async {
    final res = await _api.get('/pets/$petId/treatments');
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final list = (data['treatments'] as List<dynamic>? ?? []);
    return list
        .map((e) => Treatment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Treatment> getTreatmentDetails({
    required int petId,
    required int treatmentId,
  }) async {
    final res = await _api.get('/pets/$petId/treatments/$treatmentId');
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Treatment.fromJson(data);
  }
}
