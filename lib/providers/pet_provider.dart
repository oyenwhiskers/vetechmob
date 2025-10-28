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
      print('❌ PetProvider fetch error: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(Object e) {
    try {
      final errorStr = e.toString();
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
          tag: tag,
        );
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
}
