import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../models/treatment.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/pet_service.dart';

class AIDiagnoseProvider extends ChangeNotifier {
  final _aiService = AIService();
  final _petService = PetService();

  Pet? _selectedPet;
  List<Treatment> _treatments = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;

  Pet? get selectedPet => _selectedPet;
  List<Treatment> get treatments => _treatments;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;
  bool get hasPetSelected => _selectedPet != null;

  /// Select a pet and load their medical history
  Future<void> selectPet(Pet pet) async {
    _selectedPet = pet;
    _messages.clear();
    _treatments = [];
    _error = null;
    notifyListeners();

    // Load medical history
    await _loadMedicalHistory();
    
    // Send welcome message
    _addWelcomeMessage();
  }

  /// Load medical history for the selected pet
  Future<void> _loadMedicalHistory() async {
    if (_selectedPet == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _treatments = await _petService.getPetTreatments(_selectedPet!.id);
    } catch (e) {
      _error = 'Failed to load medical history: $e';
      print('Error loading medical history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add welcome message with medical summary
  void _addWelcomeMessage() {
    if (_selectedPet == null) return;

    final welcomeText = '''Hello! I'm your AI veterinary assistant. I've reviewed ${_selectedPet!.name}'s medical records.

${_treatments.isEmpty ? '${_selectedPet!.name} has no recorded treatments yet.' : 'I found ${_treatments.length} previous treatment(s) in the records.'}

How can I help you today? Feel free to ask about:

- Symptoms or behaviors you've noticed
- ${_selectedPet!.name}'s medical history
- General health questions
- When to seek veterinary care

Remember, I'm here to provide guidance, but always consult with a licensed veterinarian for diagnosis and treatment.''';

    _messages.add(ChatMessage.assistant(welcomeText));
    notifyListeners();
  }

  /// Send a message to the AI
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _selectedPet == null) return;
    if (_isSendingMessage) return; // Prevent duplicate sends

    final userMessage = ChatMessage.user(content);
    _messages.add(userMessage);
    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    try {
      // Get AI response
      final response = await _aiService.sendMessage(
        pet: _selectedPet!,
        treatments: _treatments,
        chatHistory: _messages.where((m) => m != userMessage).toList(),
        userMessage: content,
      );

      // Add AI response
      _messages.add(ChatMessage.assistant(response));
    } catch (e) {
      _error = 'Failed to get AI response: $e';
      print('Error getting AI response: $e');
      
      // Add error message to chat
      _messages.add(ChatMessage.assistant(
        'I apologize, but I encountered an error processing your request. Please try again or consult with your veterinarian directly.',
      ));
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Clear the current chat session
  void clearChat() {
    _messages.clear();
    if (_selectedPet != null) {
      _addWelcomeMessage();
    }
    notifyListeners();
  }

  /// Reset everything
  void reset() {
    _selectedPet = null;
    _treatments = [];
    _messages = [];
    _isLoading = false;
    _isSendingMessage = false;
    _error = null;
    notifyListeners();
  }
}
