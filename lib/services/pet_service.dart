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
      throw Exception('Failed to fetch pets (${res.statusCode}): $errorMessage');
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
    final payload = <String, dynamic>{
      'name': name,
      'species': species,
      if (breed != null) 'breed': breed,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (color != null) 'color': color,
      if (weight != null) 'weight': weight,
      if (microchipId != null) 'microchip_id': microchipId,
      if (medicalNotes != null) 'medical_notes': medicalNotes,
    };
    final res = await _api.post('/pets', data: payload);
    
    // Check for error status codes
    if (res.statusCode != 200 && res.statusCode != 201) {
      final errorMessage = res.data is Map 
          ? (res.data['message'] ?? 'Server error') 
          : 'Server error';
      throw Exception('Failed to create pet (${res.statusCode}): $errorMessage');
    }
    
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<Pet> getPetDetails(int id) async {
    final res = await _api.get('/pets/$id');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<Pet> updatePet(int id, {
    String? name,
    String? species,
    String? breed,
    int? age,
    String? gender,
    String? color,
    double? weight,
    String? microchipId,
    String? medicalNotes,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (species != null) payload['species'] = species;
    if (breed != null) payload['breed'] = breed;
    if (age != null) payload['age'] = age;
    if (gender != null) payload['gender'] = gender;
    if (color != null) payload['color'] = color;
    if (weight != null) payload['weight'] = weight;
    if (microchipId != null) payload['microchip_id'] = microchipId;
    if (medicalNotes != null) payload['medical_notes'] = medicalNotes;

    final res = await _api.put('/pets/$id', data: payload);
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<void> deletePet(int id) async {
    await _api.delete('/pets/$id');
  }

  Future<PetTag> scanAndAssignTag({required String tagCode, required int petId}) async {
    final res = await _api.post('/pets/scan-tag', data: {'tag_code': tagCode, 'pet_id': petId});
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return PetTag.fromJson(data['tag'] as Map<String, dynamic>);
  }

  Future<PetTag> assignTagToPet({required int petId, required String tagCode}) async {
    try {
      print('🏷️ Assigning tag: $tagCode to pet: $petId');
      
      final res = await _api.post('/pets/$petId/assign-tag', data: {'tag_code': tagCode});
      
      print('📡 Response status: ${res.statusCode}');
      print('📦 Response data type: ${res.data.runtimeType}');
      print('📦 Response data: ${res.data}');
      
      // Check for HTTP errors
      if (res.statusCode == null || res.statusCode! < 200 || res.statusCode! >= 300) {
        final errorMessage = res.data is Map ? (res.data['message'] ?? 'Server error') : 'Server error';
        throw Exception('HTTP ${res.statusCode}: $errorMessage');
      }
      
      // Handle response safely
      if (res.data == null) {
        throw Exception('Empty response from server');
      }
      
      final responseData = res.data as Map<String, dynamic>;
      print('✅ Parsed response data: $responseData');
      
      // Check for success flag
      if (responseData['success'] != true) {
        final message = responseData['message'] ?? 'Tag assignment failed';
        throw Exception(message);
      }
      
      // Get the data object
      if (!responseData.containsKey('data') || responseData['data'] == null) {
        print('❌ Response structure: ${responseData.keys.toList()}');
        throw Exception('Response missing data field. Got keys: ${responseData.keys.toList()}');
      }
      
      final data = responseData['data'] as Map<String, dynamic>;
      print('📋 Data object: $data');
      print('📋 Data keys: ${data.keys.toList()}');
      
      // Get the tag from data
      if (!data.containsKey('tag') || data['tag'] == null) {
        print('❌ Data structure: ${data.keys.toList()}');
        throw Exception('Response missing tag in data. Got keys: ${data.keys.toList()}');
      }
      
      final tagData = data['tag'] as Map<String, dynamic>;
      print('🏷️ Tag data: $tagData');
      
      // Create and return PetTag
      final petTag = PetTag.fromJson(tagData);
      print('✅ Created PetTag: id=${petTag.id}, code=${petTag.tagCode}');
      
      return petTag;
    } catch (e, stackTrace) {
      print('❌ Error in assignTagToPet: $e');
      print('📚 Stack trace: $stackTrace');
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
      throw Exception('Release tag endpoint not available. Backend needs to implement POST /pets/{id}/release-tag');
    }
  }

  Future<List<Treatment>> getPetTreatments(int petId) async {
    final res = await _api.get('/pets/$petId/treatments');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final list = (data['treatments'] as List<dynamic>? ?? []);
    return list.map((e) => Treatment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Treatment> getTreatmentDetails({required int petId, required int treatmentId}) async {
    final res = await _api.get('/pets/$petId/treatments/$treatmentId');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Treatment.fromJson(data);
  }
}
