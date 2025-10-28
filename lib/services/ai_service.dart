import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet.dart';
import '../models/treatment.dart';
import '../models/chat_message.dart';

class AIService {
  // Note: In production, store API key securely (environment variables, backend proxy, etc.)
  // For development, you can set it here or pass it from a config
  static const String _apiKey = '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'; // Replace with your actual API key
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini'; // Using GPT-4o-mini as specified

  /// Generate a medical history summary for the AI context
  String _buildMedicalHistoryContext(Pet pet, List<Treatment> treatments) {
    final buffer = StringBuffer();
    
    buffer.writeln('Pet Information:');
    buffer.writeln('- Name: ${pet.name}');
    buffer.writeln('- Species: ${pet.species}');
    if (pet.breed != null) buffer.writeln('- Breed: ${pet.breed}');
    if (pet.age != null) buffer.writeln('- Age: ${pet.age} years old');
    if (pet.gender != null) buffer.writeln('- Gender: ${pet.gender}');
    if (pet.color != null) buffer.writeln('- Color: ${pet.color}');
    if (pet.weight != null) buffer.writeln('- Weight: ${pet.weight} kg');
    if (pet.microchipId != null) buffer.writeln('- Microchip ID: ${pet.microchipId}');
    if (pet.medicalNotes != null && pet.medicalNotes!.isNotEmpty) {
      buffer.writeln('- Medical Notes: ${pet.medicalNotes}');
    }
    
    buffer.writeln('\nMedical History (${treatments.length} treatments):');
    
    if (treatments.isEmpty) {
      buffer.writeln('No previous treatments recorded.');
    } else {
      for (var i = 0; i < treatments.length; i++) {
        final t = treatments[i];
        buffer.writeln('\nTreatment ${i + 1}:');
        buffer.writeln('- Date: ${t.treatmentDate}');
        buffer.writeln('- Location: ${t.treatmentLocation}');
        buffer.writeln('- Diagnosis: ${t.diagnosis}');
        if (t.disease != null) buffer.writeln('- Disease: ${t.disease}');
        if (t.medicinePrescribed != null) {
          buffer.writeln('- Medicine: ${t.medicinePrescribed}');
        }
        if (t.dosage != null) buffer.writeln('- Dosage: ${t.dosage}');
        if (t.notes != null) buffer.writeln('- Notes: ${t.notes}');
        if (t.collaborator != null) {
          buffer.writeln('- Veterinarian: ${t.collaborator!.name}');
          if (t.collaborator!.clinicName != null) {
            buffer.writeln('- Clinic: ${t.collaborator!.clinicName}');
          }
        }
      }
    }
    
    return buffer.toString();
  }

  /// Send a chat message to OpenAI with medical context
  Future<String> sendMessage({
    required Pet pet,
    required List<Treatment> treatments,
    required List<ChatMessage> chatHistory,
    required String userMessage,
  }) async {
    try {
      // Build the medical history context
      final medicalContext = _buildMedicalHistoryContext(pet, treatments);
      
      // Build the system prompt
      final systemPrompt = '''You are a helpful veterinary AI assistant. You have access to the medical records of a pet and can provide health-related guidance to the pet owner.

IMPORTANT GUIDELINES:
1. You are NOT a replacement for a veterinarian. Always recommend consulting with a licensed veterinarian for diagnosis and treatment.
2. Base your responses on the medical history provided.
3. Be empathetic and supportive.
4. If the situation seems urgent, strongly advise immediate veterinary care.
5. Provide general health information and insights based on the pet's history.
6. Keep your responses clear, concise, and easy to understand for pet owners.

$medicalContext

Please help the owner understand their pet's health and answer their questions based on the above information.''';

      // Build messages array for API
      final messages = <Map<String, String>>[];
      
      // Add system message with medical context
      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });
      
      // Add chat history
      for (final msg in chatHistory) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
      
      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Make API request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('OpenAI API Error: ${errorData['error']['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  /// Validate API key (optional utility method)
  static bool isApiKeySet() {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_OPENAI_API_KEY_HERE';
  }
}
