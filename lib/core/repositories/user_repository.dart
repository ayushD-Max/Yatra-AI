import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserRepository {
  final SharedPreferences prefs;
  static const _profileKey = 'user_profile';

  UserRepository(this.prefs);

  UserProfile getUserProfile() {
    final jsonStr = prefs.getString(_profileKey);
    if (jsonStr != null) {
      try {
        return UserProfile.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        print('Error decoding user profile: $e');
      }
    }
    // Return empty profile for fresh users
    return const UserProfile();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  int getTripsCount() {
    final tripStr = prefs.getString('current_trip');
    return tripStr != null ? 1 : 0;
  }

  int getSavedCount() {
    final favoritesStr = prefs.getStringList('favorites');
    return favoritesStr?.length ?? 0;
  }
}
