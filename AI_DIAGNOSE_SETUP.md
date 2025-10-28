# AI Diagnose Feature - Setup Guide

## Overview
The AI Diagnose feature allows pet owners to consult with an AI assistant about their pet's health. The AI has access to the pet's complete medical history and can provide health-related guidance based on symptoms and behavior.

## Features
- **Pet Selection**: Choose which pet you want to discuss with the AI
- **Medical History Integration**: AI automatically retrieves and understands the pet's medical records
- **Chat Interface**: Natural conversation with the AI assistant
- **Context-Aware Responses**: AI provides personalized advice based on the pet's history
- **Real-time Consultation**: Instant responses powered by GPT-4o-mini

## Setup Instructions

### 1. Get Your OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to [API Keys](https://platform.openai.com/api-keys)
4. Click "Create new secret key"
5. Copy the API key (you won't be able to see it again!)

### 2. Configure the API Key

Open the file `lib/services/ai_service.dart` and replace the placeholder with your actual API key:

```dart
// Line 9 in ai_service.dart
static const String _apiKey = 'sk-your-actual-api-key-here';
```

**IMPORTANT SECURITY NOTES:**
- ⚠️ Never commit your API key to version control
- ⚠️ For production apps, use environment variables or a secure backend proxy
- ⚠️ Add `lib/services/ai_service.dart` to `.gitignore` if you hardcode the key
- ✅ Best practice: Store the API key on your backend and proxy requests

### 3. Alternative: Backend Proxy (Recommended for Production)

Instead of storing the API key in the mobile app, create a backend endpoint:

**Backend endpoint example (Laravel):**
```php
// app/Http/Controllers/AIController.php
public function chat(Request $request) {
    $apiKey = env('OPENAI_API_KEY');
    $response = Http::withHeaders([
        'Authorization' => 'Bearer ' . $apiKey,
        'Content-Type' => 'application/json',
    ])->post('https://api.openai.com/v1/chat/completions', [
        'model' => 'gpt-4o-mini',
        'messages' => $request->messages,
        'temperature' => 0.7,
        'max_tokens' => 1000,
    ]);
    
    return response()->json($response->json());
}
```

**Then update `ai_service.dart` to call your backend:**
```dart
// Replace the direct OpenAI API call with your backend endpoint
final response = await http.post(
  Uri.parse('${AppConstants.baseUrl}/ai/chat'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $userToken',
  },
  body: jsonEncode({'messages': messages}),
);
```

## Usage

### 1. Select a Pet
- Open the AI Diagnose screen from the dashboard
- Choose which pet you want to discuss
- The AI will load the pet's medical history automatically

### 2. Start Chatting
- Ask questions about your pet's health
- Describe symptoms or behaviors
- Request clarification about medical history
- Get general health advice

### 3. Example Questions
- "My pet has been scratching a lot lately. What could be causing this?"
- "Can you review the last treatment and explain what was done?"
- "What should I watch out for based on their medical history?"
- "Is this symptom an emergency?"

## Technical Details

### Components Created

1. **`lib/models/chat_message.dart`**
   - Model for chat messages (user and AI)
   - Timestamp tracking

2. **`lib/services/ai_service.dart`**
   - OpenAI API integration
   - Medical history context building
   - GPT-4o-mini model configuration

3. **`lib/providers/ai_diagnose_provider.dart`**
   - State management for chat
   - Pet selection handling
   - Medical history retrieval
   - Message sending/receiving

4. **`lib/screens/tabs/ai_diagnose_screen.dart`**
   - Pet selection UI
   - Chat interface
   - Message bubbles
   - Input area

### API Costs

GPT-4o-mini pricing (as of 2024):
- Input: $0.15 per 1M tokens (~$0.0001 per message)
- Output: $0.60 per 1M tokens (~$0.0004 per message)

Very affordable for veterinary consultations!

### Data Flow

```
User → AI Diagnose Screen → AIDiagnoseProvider
                                    ↓
                            PetService (Get Medical History)
                                    ↓
                            AIService (Build Context + Send to OpenAI)
                                    ↓
                            OpenAI API (GPT-4o-mini)
                                    ↓
                            Response → Display in Chat
```

### Medical History Context

The AI receives:
- Pet name, species, breed, age, gender
- Weight, color, medical notes
- Complete treatment history:
  - Dates, locations, diagnoses
  - Medicines and dosages
  - Veterinarian notes
  - Clinic information

## Safety & Disclaimers

The AI assistant is designed with important safety guidelines:

1. ✅ **Always recommends consulting a licensed veterinarian**
2. ✅ **Emphasizes urgency for emergency situations**
3. ✅ **Provides general guidance, not diagnoses**
4. ✅ **Bases responses on medical history**
5. ✅ **Uses empathetic, supportive language**

## Troubleshooting

### "API Key Required" Warning
- Make sure you've replaced the placeholder API key in `ai_service.dart`
- Check that the key starts with `sk-`
- Verify the key is valid on the OpenAI platform

### "Failed to get AI response" Error
- Check your internet connection
- Verify your OpenAI API key is valid and has credits
- Check the console for detailed error messages
- Ensure you haven't exceeded rate limits

### "Failed to load medical history" Error
- Verify the pet has valid data in the database
- Check backend API is running
- Review the treatment endpoint: `GET /pets/{id}/treatments`

### Chat not scrolling
- The chat auto-scrolls to the latest message
- If it doesn't, try switching to another screen and back

## Future Enhancements

Possible improvements:
- [ ] Image analysis (upload pet photos)
- [ ] Voice input for easier questions
- [ ] Export chat history
- [ ] Share chat with veterinarian
- [ ] Multi-language support
- [ ] Symptom checker with structured forms
- [ ] Integration with appointment booking

## Support

For issues or questions:
1. Check the console logs for detailed error messages
2. Verify all setup steps are completed
3. Test with the OpenAI API directly to rule out key issues
4. Review the backend API endpoints

---

**Note:** This feature requires an active internet connection and a valid OpenAI API key with available credits.
