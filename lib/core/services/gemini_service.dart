import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/trip_modification.dart';

class GeminiService {
  Future<TripModification> parseTripModification(String text, {String? currentContext}) async {
    if (!ApiConstants.hasGeminiKey) {
      throw Exception('No Gemini API Key provided');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${ApiConstants.geminiApiKey}',
    );

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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentText =
            data['candidates'][0]['content']['parts'][0]['text'];
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
        throw Exception('Failed to communicate with Gemini API');
      }
    } catch (e) {
      throw Exception('Gemini parsing failed: $e');
    }
  }
}
