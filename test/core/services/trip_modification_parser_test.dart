import 'package:flutter_test/flutter_test.dart';
import 'package:yatra_ai/core/services/trip_modification_parser.dart';

void main() {
  group('TripModificationParser Tests', () {
    test('12. Parser variations (Duration)', () {
      final res1 = TripModificationParser.parse('I only have two days now');
      expect(res1.duration, 2);

      final res2 = TripModificationParser.parse('Make it 4 days');
      expect(res2.duration, 4);
    });

    test('12. Parser variations (Budget)', () {
      final res1 = TripModificationParser.parse('Make it cheaper');
      expect(res1.budgetDirection, 'decrease');

      final res2 = TripModificationParser.parse('I want a luxury trip');
      expect(res2.budgetDirection, 'increase');

      final res3 = TripModificationParser.parse('I have a 1000 es budget');
      expect(res3.budget, 1000);

      final res4 = TripModificationParser.parse('change budget to ₹15,000');
      expect(res4.budget, 15000);
    });

    test('12. Parser variations (Outdoor/Indoor)', () {
      final res1 = TripModificationParser.parse(
        'I don\'t want outdoor activities',
      );
      expect(res1.indoorOutdoorPreference, -1.0);
      expect(res1.excludedCategories?.contains('Outdoor'), true);

      final res2 = TripModificationParser.parse(
        'I want more indoor activities',
      );
      expect(res2.indoorOutdoorPreference, -1.0);
      expect(
        res1.excludedCategories?.contains('Outdoor'),
        true,
      ); // Equivalent logic applies
    });

    test('12. Parser variations (Food & Categories)', () {
      final res1 = TripModificationParser.parse('I want more food places');
      expect(res1.preferredCategories?.contains('Food'), true);

      final res2 = TripModificationParser.parse('Remove museums');
      expect(res2.excludedCategories?.contains('Culture'), true);
      expect(res2.excludedCategories?.contains('Historical'), true);
    });

    test('13. Parser variations (Known Places and Typo Handling)', () {
      final res1 = TripModificationParser.parse('i hvae only one day for rajadad fort so i hvae 1000 es');
      expect(res1.addSpecificPlaces?.contains('Rajgad Fort'), true);
      expect(res1.removeSpecificPlaces?.contains('Sinhagad Fort'), true);
      expect(res1.duration, 1);
      expect(res1.budget, 1000);
      expect(res1.aiExplanation?.contains('Rajgad Fort'), true);
    });
  });
}
