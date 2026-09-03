import 'package:flutter_test/flutter_test.dart';
import 'package:yatra_ai/core/models/trip.dart';

void main() {
  group('TripPreferences Tests', () {
    test('serialization and deserialization', () {
      const prefs = TripPreferences(
        budget: 5000,
        travelStyle: 'Luxury',
        includeNearbyPlaces: true,
        startTime: '08:00 AM',
      );

      final json = prefs.toJson();
      expect(json['budget'], 5000);
      expect(json['travelStyle'], 'Luxury');
      expect(json['includeNearbyPlaces'], true);

      final decoded = TripPreferences.fromJson(json);
      expect(decoded.budget, 5000);
      expect(decoded.travelStyle, 'Luxury');
      expect(decoded.includeNearbyPlaces, true);
      expect(decoded.startTime, '08:00 AM');
    });

    test('copyWith works correctly', () {
      const prefs = TripPreferences(budget: 1000);
      final updated = prefs.copyWith(budget: 2000, travelStyle: 'Solo');

      expect(updated.budget, 2000);
      expect(updated.travelStyle, 'Solo');
    });
  });
}
