import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get geminiApiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  static String get openRouterApiKey {
    try {
      return dotenv.env['OPENROUTER_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }
  
  static bool get hasOpenRouterKey => openRouterApiKey.isNotEmpty;

  static String get foursquareApiKey {
    try {
      return dotenv.env['FOURSQUARE_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool get hasFoursquareKey => foursquareApiKey.isNotEmpty;

  static String get googleMapsApiKey {
    try {
      return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool get hasGoogleMapsKey => googleMapsApiKey.isNotEmpty;
}
