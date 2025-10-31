import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../models/treatment.dart';
import '../services/pet_service.dart';

class PetProvider extends ChangeNotifier {
  final _service = PetService();
  List<Pet> _pets = [];
  bool _loading = false;
  String? _error;

  List<Pet> get pets => _pets;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _pets = await _service.getPets();
    } catch (e) {
      _error = _extractErrorMessage(e);
      debugPrint('❌ PetProvider fetch error: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(Object e) {
    try {
      final errorStr = e.toString();
      debugPrint("Error occurred: $errorStr");
      if (errorStr.contains('500')) {
        return 'Server error (500). Please check server logs.\nThe backend needs to be fixed.';
      }
      if (errorStr.contains('timeout')) {
        return 'Connection timeout. Server is not responding.';
      }
      if (errorStr.contains('401')) {
        return 'Authentication failed. Please login again.';
      }
      if (errorStr.contains('404')) {
        return 'Pets endpoint not found (404).';
      }
      return errorStr;
    } catch (_) {
      return 'Unknown error occurred';
    }
  }

  Future<String?> addPet(Pet pet) async {
    try {
      _loading = true;
      notifyListeners();
      final created = await _service.createPet(
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        age: pet.age,
        gender: pet.gender,
        color: pet.color,
        weight: pet.weight,
        microchipId: pet.microchipId,
        medicalNotes: pet.medicalNotes,
      );
      _pets = [..._pets, created];
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> assignTag(int petId, String tagCode) async {
    try {
      final tag = await _service.assignTagToPet(petId: petId, tagCode: tagCode);
      final idx = _pets.indexWhere((p) => p.id == petId);
      if (idx != -1) {
        final p = _pets[idx];
        _pets[idx] = Pet(
          id: p.id,
          name: p.name,
          species: p.species,
          breed: p.breed,
          age: p.age,
          gender: p.gender,
          color: p.color,
          weight: p.weight,
          microchipId: p.microchipId,
          medicalNotes: p.medicalNotes,
          petImage: p.petImage,
          tag: tag,
        );
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePet(
    int petId, {
    String? name,
    String? species,
    String? breed,
    int? age,
    String? gender,
    String? status,
    String? color,
    double? weight,
    String? microchipId,
    String? medicalNotes,
    File? petImageFile,
    Uint8List? petImageBytes,
    String? petImageName,
    bool removePetImage = false,
  }) async {
    try {
      final updated = await _service.updatePet(
        petId,
        name: name,
        species: species,
        breed: breed,
        age: age,
        gender: gender,
        status: status,
        color: color,
        weight: weight,
        microchipId: microchipId,
        medicalNotes: medicalNotes,
        petImageFile: petImageFile,
        petImageBytes: petImageBytes,
        petImageName: petImageName,
        removePetImage: removePetImage,
      );
      
      final idx = _pets.indexWhere((p) => p.id == petId);
      if (idx != -1) {
        _pets[idx] = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Treatment>> fetchTreatments(int petId) async {
    return _service.getPetTreatments(petId);
  }

  Future<void> releaseTag(int petId) async {
    try {
      await _service.releaseTagFromPet(petId);
      final idx = _pets.indexWhere((p) => p.id == petId);
      if (idx != -1) {
        final p = _pets[idx];
        _pets[idx] = Pet(
          id: p.id,
          name: p.name,
          species: p.species,
          breed: p.breed,
          age: p.age,
          gender: p.gender,
          color: p.color,
          weight: p.weight,
          microchipId: p.microchipId,
          medicalNotes: p.medicalNotes,
          petImage: p.petImage,
          tag: null, // Remove the tag
        );
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to release tag: $e');
    }
  }

  Future<String?> deletePet(int petId) async {
    try {
      await _service.deletePet(petId);
      _pets.removeWhere((p) => p.id == petId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
