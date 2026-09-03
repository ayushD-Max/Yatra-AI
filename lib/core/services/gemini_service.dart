import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/trip_modification.dart';

class PreChatResponse {
  final String message;
  final bool readyToGenerate;
  final int? budget;
  final int? days;
  final int? availableTimeMinutes;
  final bool? includeNearbyPlaces;
  final String? tripType;
  final String? startTime;

  PreChatResponse({
    required this.message,
    required this.readyToGenerate,
    this.budget,
    this.days,
    this.availableTimeMinutes,
    this.includeNearbyPlaces,
    this.tripType,
    this.startTime,
  });

  factory PreChatResponse.fromJson(Map<String, dynamic> json) {
    return PreChatResponse(
      message: json['message'] ?? '',
      readyToGenerate: json['readyToGenerate'] ?? false,
      budget: json['budget'] as int?,
      days: json['days'] as int?,
      availableTimeMinutes: json['availableTimeMinutes'] as int?,
      includeNearbyPlaces: json['includeNearbyPlaces'] as bool?,
      tripType: json['tripType'] as String?,
      startTime: json['startTime'] as String?,
    );
  }
}

class GeminiService {
  Future<TripModification> parseTripModification(String text, {String? currentContext}) async {
    if (!ApiConstants.hasOpenRouterKey) {
      throw Exception('No OpenRouter API Key provided');
    }

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final contextPrompt = currentContext != null
        ? '\nHere is the current context of the trip/itinerary to help you make decisions:\n$currentContext\n'
        : '';

    final prompt =
        '''
You are a travel preference parser and conversational assistant. 
1. Convert the user's request into the JSON structure below.
2. In the "aiExplanation" field, provide a friendly, helpful conversational response like a standard AI assistant (e.g. ChatGPT/Gemini). Explain any changes you're making to their itinerary, answer their travel questions directly, or offer tips about their destination, including real details. If they ask a general question (e.g. "Tell me more about Rajgad Fort" or "Explain what this is"), answer it thoroughly in this field.
3. If the user requests to limit the trip to a specific place or places (e.g. "I only have one day for Rajgad Fort"), compare this request with the current itinerary places in the context. Set the new "duration" accordingly (e.g. 1), set the requested place in "addSpecificPlaces", and list all other current places that are no longer part of the focused request in "removeSpecificPlaces" so the local generator can remove them.
4. If they specify a budget (e.g. "₹1,000 budget"), set the "budget" field to the number (e.g. 1000) and set "budgetDirection" to "decrease" or "increase" based on comparison with the current budget.
$contextPrompt
User's request: "$text"

Return ONLY valid JSON matching exactly this structure (use null for unspecified fields, do not invent data):
{
  "duration": null,
  "budgetDirection": null,
  "budget": null,
  "preferredCategories": [],
  "excludedCategories": [],
  "travelStyle": null,
  "indoorOutdoorPreference": null,
  "addSpecificPlaces": [],
  "removeSpecificPlaces": [],
  "aiExplanation": "Your conversational response/answer here"
}
''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.openRouterApiKey}',
        },
        body: jsonEncode({
          'model': 'minimax/minimax-m3:free',
          'max_tokens': 1500,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contentText = data['choices'][0]['message']['content'];
        
        contentText = contentText.trim();
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(contentText);
        if (match != null) {
          contentText = match.group(0)!;
        }
        
        final Map<String, dynamic> parsedJson = jsonDecode(contentText);

        return TripModification(
          duration: parsedJson['duration'] as int?,
          budgetDirection: parsedJson['budgetDirection'] as String?,
          budget: parsedJson['budget'] as int?,
          preferredCategories:
              (parsedJson['preferredCategories'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          excludedCategories:
              (parsedJson['excludedCategories'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          travelStyle: parsedJson['travelStyle'] as String?,
          indoorOutdoorPreference:
              (parsedJson['indoorOutdoorPreference'] as num?)?.toDouble(),
          addSpecificPlaces:
              (parsedJson['addSpecificPlaces'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          removeSpecificPlaces:
              (parsedJson['removeSpecificPlaces'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          aiExplanation: parsedJson['aiExplanation'] as String?,
        );
      } else {
        throw Exception('Failed to communicate with OpenRouter API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gemini parsing failed: $e');
    }
  }

  Future<PreChatResponse> processPreChat(
    String userMessage,
    String chatHistory,
    String tripContext,
  ) async {
    if (!ApiConstants.hasOpenRouterKey) {
      throw Exception('No OpenRouter API Key provided');
    }

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final prompt = '''
You are the conversational trip-planning assistant inside Yatra AI.

The Flutter application provides a structured trip context below.
The Flutter application is the source of truth for trip data.

Here is the trip context:
$tripContext

Here is the chat history so far:
$chatHistory

User just said: "$userMessage"

Your job is to understand natural language, extract missing information, acknowledge what the user said, and ask only necessary follow-up questions.

Rules:
1. Never replace the selected Anchor Place unless the user explicitly requests a change.
2. Never ask for information that already exists in the provided context (e.g., if budget or days are already set, do NOT ask for them again).
3. If the user provides multiple values in one message, extract all of them into the JSON fields.
4. Preserve previously known values (they are handled locally, just return what you extracted).
5. Never convert a day number into a budget.
6. Never invent a budget.
7. Budget is optional. If the user explicitly says they have no budget, that's fine.
8. If the user corrects a value, return the new value.
9. Ask at most one concise follow-up question at a time.
10. Be conversational and natural. Acknowledge information already understood.
11. You MUST ask if they want to visit other nearby places or just stick to the main place. Extract this into includeNearbyPlaces (true/false).
12. You MUST ask what time they want to start their trip (e.g. "10:00 AM"). Extract this into startTime.
13. If all important information is available (destination, anchor place, includeNearbyPlaces, and startTime or days), return readyToGenerate=true. Budget is optional and should NOT block generation.

Return ONLY valid JSON matching exactly this structure (use null for fields that the user didn't mention, do not invent data):
{
  "message": "Your conversational response/question to the user",
  "readyToGenerate": false,
  "budget": null,
  "days": null,
  "startTime": null,
  "availableTimeMinutes": null,
  "tripType": null,
  "includeNearbyPlaces": null
}
''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.openRouterApiKey}',
        },
        body: jsonEncode({
          'model': 'minimax/minimax-m3:free',
          'max_tokens': 1500,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contentText = data['choices'][0]['message']['content'];
        
        contentText = contentText.trim();
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(contentText);
        if (match != null) {
          contentText = match.group(0)!;
        }
        
        final Map<String, dynamic> parsedJson = jsonDecode(contentText);
        return PreChatResponse.fromJson(parsedJson);
      } else {
        throw Exception('Failed to communicate with OpenRouter API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gemini pre-chat parsing failed: $e');
    }
  }
  Future<String> generatePackingList(String destinationName, int days, String? tripStyle) async {
    final prompt = '''
You are a highly helpful AI travel assistant. The user is traveling to $destinationName for $days days.
Their travel style/preferences: ${tripStyle ?? 'General Leisure'}.

Generate a concise, smart packing list categorized by Essentials, Clothing, Electronics, and Misc.
Format it in clean markdown using emojis and bullet points.
Return ONLY the markdown packing list.
''';

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.openRouterApiKey}',
      },
      body: jsonEncode({
        'model': 'minimax/minimax-m3:free',
        'max_tokens': 1500,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('Failed to generate packing list');
    }
  }

  Future<String> getPlaceInsights(String placeName, String city) async {
    final prompt = '''
You are a local travel expert in $city. Share a fascinating 3-sentence trivia or hidden insight about $placeName that most tourists don't know. Keep it engaging, fun, and concise. Do NOT wrap in quotes.
''';

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.openRouterApiKey}',
        },
        body: jsonEncode({
          'model': 'minimax/minimax-m3:free',
          'max_tokens': 300,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      }
      return 'Did you know? $placeName is one of the most beloved spots in $city for locals and tourists alike!';
    } catch (e) {
      return 'Insight temporarily unavailable. Enjoy your visit to $placeName!';
    }
  }

  Future<List<Map<String, dynamic>>> generateFinalItinerary(
    String city,
    int durationDays,
    List<Map<String, String>> chatHistory,
    List<Map<String, dynamic>> availablePlaces,
  ) async {
    // Convert the available places to a minimal string to save tokens
    final placesString = availablePlaces.map((p) => 
      "{id: ${p['id']}, name: ${p['name']}, category: ${p['category']}, duration: ${p['duration']}m}"
    ).join("\n");
    
    // Convert chat history to readable text
    final chatString = chatHistory.map((m) => "${m['role']}: ${m['text']}").join("\n");

    final prompt = '''
You are an expert AI Travel Planner. You must generate a highly optimized daily itinerary for a $durationDays-day trip to $city.
You MUST heavily rely on the user's constraints expressed in this chat history:
$chatString

Here is the list of available places you can schedule:
$placesString

Rules:
1. ONLY schedule places from the available places list. Use their exact IDs.
2. Respect the user's explicit constraints from the chat (e.g. if they only want 1 place, or specific start times, strictly follow it).
3. If the user only wants 1 specific place, schedule ONLY that place for Day 1 and leave the rest blank.
4. Output MUST be a raw JSON array of objects representing days. No markdown wrappers like ```json.
5. Format EXACTLY like this:
[
  {
    "dayIndex": 1,
    "items": [
      {"placeId": "pune_1", "startTime": "09:00", "endTime": "11:00"},
      {"placeId": "pune_2", "startTime": "11:30", "endTime": "13:30"}
    ]
  }
]
''';

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.openRouterApiKey}',
        },
        body: jsonEncode({
          'model': 'minimax/minimax-m3:free',
          'max_tokens': 4000,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contentText = data['choices'][0]['message']['content'];
        contentText = contentText.trim();
        
        final match = RegExp(r'\[[\s\S]*\]').firstMatch(contentText);
        if (match != null) {
          contentText = match.group(0)!;
        }

        final List<dynamic> jsonList = jsonDecode(contentText);
        return jsonList.cast<Map<String, dynamic>>();
      }
      throw Exception('API failed');
    } catch (e) {
      print('GeminiService Error generating final itinerary: $e');
      throw Exception('Failed to generate AI itinerary: $e');
    }
  }
}
