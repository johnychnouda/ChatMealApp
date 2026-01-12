import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle OpenAI ChatGPT API interactions
class OpenAIService {
  static const String _apiKeyKey = 'openai_api_key';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _ttsUrl = 'https://api.openai.com/v1/audio/speech';
  static const String _whisperUrl = 'https://api.openai.com/v1/audio/transcriptions';
  
  String? _apiKey;
  
  // Available OpenAI TTS voices: alloy, echo, fable, onyx, nova, shimmer
  // Available models: tts-1 (fast), tts-1-hd (high quality)
  static const String _defaultVoice = 'nova'; // Natural, friendly voice
  static const String _defaultModel = 'tts-1'; // Use tts-1-hd for better quality
  
  /// Initialize the service and load API key from storage
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_apiKeyKey);
      return _apiKey != null && _apiKey!.isNotEmpty;
    } catch (e) {
      debugPrint('OpenAI Service: Error loading API key: $e');
      return false;
    }
  }
  
  /// Set the OpenAI API key
  Future<void> setApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
      _apiKey = apiKey;
    } catch (e) {
      debugPrint('OpenAI Service: Error saving API key: $e');
    }
  }
  
  /// Get the current API key (without exposing it)
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  
  /// Clear the API key
  Future<void> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiKeyKey);
      _apiKey = null;
    } catch (e) {
      debugPrint('OpenAI Service: Error clearing API key: $e');
    }
  }
  
  /// Send a message to ChatGPT and get a response
  /// 
  /// [userMessage] - The user's input message
  /// [context] - Optional context about the current state (e.g., selected restaurant, available restaurants)
  /// [conversationHistory] - Optional list of previous messages for context
  Future<String?> getChatResponse({
    required String userMessage,
    String? context,
    List<Map<String, String>>? conversationHistory,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('OpenAI Service: API key not set');
      return null;
    }
    
    try {
      // Build system message with context about ChatMeal
      String systemMessage = '''You are ChatMeal, a powerful AI assistant with full access to the food ordering app. 
You can search, filter, and access ALL restaurant data including ratings, cuisine types, delivery times, menu items, and prices.

YOUR CAPABILITIES:
1. SEARCH & FILTER RESTAURANTS:
   - Search by cuisine type (e.g., "Lebanese", "Italian", "Japanese")
   - Filter by rating (e.g., "best rated", "restaurants above 4.5 stars")
   - Filter by delivery time (e.g., "fastest delivery", "under 30 minutes")
   - Find restaurants by menu items (e.g., "restaurants with shawarma", "places that serve pizza")

2. ACCESS RESTAURANT DATA:
   - View restaurant details: name, cuisine, rating, delivery time
   - Access menu items: names, descriptions, prices
   - Compare restaurants based on any criteria

3. PERFORM ACTIONS:
   - Show restaurants list (say "show restaurants" or "browse")
   - Select a restaurant (say the restaurant name)
   - Filter by category (say the category name)
   - Answer questions about restaurants and menus

4. RECOMMENDATIONS:
   - Suggest restaurants based on user preferences
   - Recommend menu items
   - Help with food choices

When you want to perform an action, include it in your response naturally. For example:
- "Let me show you the restaurants" → triggers showing restaurants
- "Here's Pizza Palace" → triggers selecting that restaurant
- "Let me find Lebanese restaurants" → triggers filtering

Keep responses natural, helpful, and conversational. Use the restaurant data provided to give accurate, specific answers.''';
      
      if (context != null && context.isNotEmpty) {
        systemMessage += '\n\nCurrent context: $context';
      }
      
      // Build messages list
      List<Map<String, dynamic>> messages = [
        {'role': 'system', 'content': systemMessage},
      ];
      
      // Add conversation history if provided
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        for (var msg in conversationHistory) {
          messages.add({
            'role': msg['role'] ?? 'user',
            'content': msg['content'] ?? '',
          });
        }
      }
      
      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      // Make API request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo', // You can change to 'gpt-4' if you have access
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        debugPrint('OpenAI Service: API error - ${response.statusCode}');
        debugPrint('OpenAI Service: Response body - ${response.body}');
        
        // Handle specific error cases
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] as String?;
          final errorCode = errorData['error']?['code'] as String?;
          
          if (response.statusCode == 401) {
            return 'API key is invalid. Please check your OpenAI API key in settings.';
          } else if (response.statusCode == 429) {
            if (errorCode == 'insufficient_quota') {
              return 'Your OpenAI account needs credits. Please add payment information and credits to your account at platform.openai.com.';
            }
            return 'Rate limit exceeded. Please try again in a moment.';
          } else {
            return errorMessage ?? 'Sorry, I encountered an error. Please try again.';
          }
        } catch (e) {
          return 'Sorry, I encountered an error. Please try again.';
        }
      }
    } catch (e) {
      debugPrint('OpenAI Service: Error getting chat response: $e');
      return 'Sorry, I encountered an error. Please check your internet connection and try again.';
    }
  }
  
  /// Get a structured response for restaurant selection
  /// Returns a map with action type and data
  Future<Map<String, dynamic>?> getStructuredResponse({
    required String userMessage,
    List<Map<String, dynamic>>? availableRestaurants,
    String? selectedRestaurant,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return null;
    }
    
    try {
      String systemMessage = '''You are ChatMeal, a food ordering assistant. 
Analyze user messages and determine the intent and action needed.

Possible actions:
1. "browse_restaurants" - User wants to see restaurants
2. "select_restaurant" - User wants to select a specific restaurant (provide restaurant name)
3. "order_item" - User wants to order a specific item (provide item name and quantity if mentioned)
4. "general_chat" - General conversation or questions
5. "show_menu" - User wants to see menu for a restaurant

Respond ONLY with valid JSON in this format:
{
  "action": "action_type",
  "restaurant": "restaurant_name_or_null",
  "item": "item_name_or_null",
  "quantity": number_or_null,
  "response": "friendly_text_response"
}''';
      
      if (availableRestaurants != null && availableRestaurants.isNotEmpty) {
        systemMessage += '\n\nAvailable restaurants: ${availableRestaurants.map((r) => r['name']).join(', ')}';
      }
      
      if (selectedRestaurant != null) {
        systemMessage += '\n\nCurrently selected restaurant: $selectedRestaurant';
      }
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemMessage},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.3,
          'max_tokens': 200,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        debugPrint('OpenAI Service: Structured response error - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('OpenAI Service: Error getting structured response: $e');
      return null;
    }
  }
  
  /// Generate speech using OpenAI TTS API
  /// Returns the audio bytes (MP3 format)
  /// 
  /// [text] - The text to convert to speech
  /// [voice] - Voice to use (alloy, echo, fable, onyx, nova, shimmer). Default: nova
  /// [model] - Model to use (tts-1 or tts-1-hd). Default: tts-1
  Future<List<int>?> generateSpeech({
    required String text,
    String voice = _defaultVoice,
    String model = _defaultModel,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('OpenAI Service: API key not set for TTS');
      return null;
    }
    
    if (text.isEmpty) {
      debugPrint('OpenAI Service: Empty text for TTS');
      return null;
    }
    
    try {
      final response = await http.post(
        Uri.parse(_ttsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'input': text,
          'voice': voice,
          'response_format': 'mp3',
          'speed': 1.0, // Speed multiplier (0.25 to 4.0)
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('TTS request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('OpenAI Service: TTS API error - ${response.statusCode}');
        debugPrint('OpenAI Service: TTS Response body - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('OpenAI Service: Error generating speech: $e');
      return null;
    }
  }
  
  /// Transcribe audio using OpenAI Whisper API (ChatGPT's speech recognition)
  /// Returns the transcribed text
  /// 
  /// [audioBytes] - The audio file bytes (MP3, MP4, M4A, MPEG, MPGA, WAV, or WEBM)
  /// [language] - Optional language code (e.g., 'en' for English)
  Future<String?> transcribeAudio({
    required List<int> audioBytes,
    String? language,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('OpenAI Service: API key not set for Whisper');
      return null;
    }
    
    if (audioBytes.isEmpty) {
      debugPrint('OpenAI Service: Empty audio for Whisper');
      return null;
    }
    
    try {
      // Create multipart request for file upload
      final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl));
      
      request.headers['Authorization'] = 'Bearer $_apiKey';
      
      // Add audio file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: 'audio.m4a',
        ),
      );
      
      // Add model parameter
      request.fields['model'] = 'whisper-1';
      
      // Add language if specified
      if (language != null && language.isNotEmpty) {
        request.fields['language'] = language;
      }
      
      debugPrint('OpenAI Service: Sending audio to Whisper API (${audioBytes.length} bytes)');
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Whisper request timeout');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'] as String;
        debugPrint('OpenAI Service: Whisper transcription: $text');
        return text.trim();
      } else {
        debugPrint('OpenAI Service: Whisper API error - ${response.statusCode}');
        debugPrint('OpenAI Service: Whisper Response body - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('OpenAI Service: Error transcribing audio: $e');
      return null;
    }
  }
}
