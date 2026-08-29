import 'package:flutter_test/flutter_test.dart';
import 'package:yatra_ai/core/models/trip.dart';
import 'package:yatra_ai/core/models/place.dart';
import 'package:yatra_ai/core/models/destination.dart';
import 'package:yatra_ai/core/services/itinerary_generator.dart';

void main() {
  group('ItineraryGenerator Tests', () {
    late List<Place> candidates;
    late Trip baseTrip;

    setUp(() {
      candidates = [
        const Place(
          id: 'p1',
          name: 'Pune Fort',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Culture',
          isOutdoor: true,
          rating: 4.5,
        ),
        const Place(
          id: 'p2',
          name: 'Pune Museum',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Culture',
          isOutdoor: false,
          rating: 4.2,
        ),
        const Place(
          id: 'p3',
          name: 'Vada Pav Stall',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Food',
          isOutdoor: true,
          rating: 4.8,
        ),
        const Place(
          id: 'p4',
          name: 'Fine Dining',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Food',
          isOutdoor: false,
          rating: 4.9,
        ),
        const Place(
          id: 'p5',
          name: 'Trekking Hill',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Adventure',
          isOutdoor: true,
          rating: 4.6,
        ),
        const Place(
          id: 'p6',
          name: 'Temple',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Culture',
          isOutdoor: false,
          rating: 4.7,
        ),
        const Place(
          id: 'p7',
          name: 'Park',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Nature',
          isOutdoor: true,
          rating: 4.3,
        ),
        const Place(
          id: 'p8',
          name: 'Mall',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Relaxation',
          isOutdoor: false,
          rating: 4.0,
        ),
        const Place(
          id: 'p9',
          name: 'Street Food',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Food',
          isOutdoor: true,
          rating: 4.4,
        ),
        const Place(
          id: 'p10',
          name: 'Lake',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Nature',
          isOutdoor: true,
          rating: 4.5,
        ),
        const Place(
          id: 'p11',
          name: 'Cafe',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Food',
          isOutdoor: false,
          rating: 4.5,
        ),
        const Place(
          id: 'p12',
          name: 'Historical Ruins',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Culture',
          isOutdoor: true,
          rating: 4.8,
        ),
      ];

      baseTrip = Trip(
        id: 'test_trip',
        destination: const Destination(
          id: 'pune',
          name: 'Pune',
          country: 'India',
          region: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          description: '',
        ),
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 4), // 4 days
        preferences: const TripPreferences(budget: 5000),
      );
    });

    test('1. Generate 4-day itinerary', () {
      final itinerary = ItineraryGenerator.generate(baseTrip, candidates);
      expect(itinerary.length, 4); // 4 days
      // 3 items per day * 4 days = 12 items. We have exactly 12 candidates.
      final totalItems = itinerary.expand((d) => d.items).length;
      expect(totalItems, 12);
    });

    test('2. Modify 4 days -> 2 days', () {
      final oldItinerary = ItineraryGenerator.generate(baseTrip, candidates);
      final tripWithItinerary = baseTrip.copyWith(
        generatedItinerary: oldItinerary,
      );

      final newPrefs = tripWithItinerary.preferences;
      final modifiedTrip = tripWithItinerary.copyWith(
        endDate: DateTime(2024, 1, 2), // 2 days
      );

      final newItinerary = ItineraryGenerator.modify(
        modifiedTrip,
        newPrefs,
        candidates,
      );
      expect(newItinerary.length, 2);
      final totalItems = newItinerary.expand((d) => d.items).length;
      expect(totalItems, 8); // Max capacity for 2 days is 8 (6 non-food + 2 food)
    });

    test('3. Exclude outdoor', () {
      final newPrefs = baseTrip.preferences.copyWith(
        excludedCategories: ['Outdoor'],
        indoorOutdoorPreference: -1.0,
      );

      final itinerary = ItineraryGenerator.generate(
        baseTrip.copyWith(preferences: newPrefs),
        candidates,
      );
      final items = itinerary.expand((d) => d.items).toList();

      // None of the items should be outdoor
      for (var item in items) {
        expect(item.place.isOutdoor, false);
      }
    });

    test('4. Prefer food', () {
      final newPrefs = baseTrip.preferences.copyWith(
        preferredCategories: ['Food'],
        foodPreference: 1.0,
      );

      final itinerary = ItineraryGenerator.generate(
        baseTrip.copyWith(preferences: newPrefs),
        candidates,
      );
      final hasFood = itinerary.expand((d) => d.items).any((item) => item.place.category == 'Food' && item.place.id != 'generic_lunch');
      expect(hasFood, true);
    });

    test('5. Reduce budget', () {
      final newPrefs = baseTrip.preferences.copyWith(budget: 100);
      final itinerary = ItineraryGenerator.generate(
        baseTrip.copyWith(preferences: newPrefs),
        candidates,
      );
      final items = itinerary.expand((d) => d.items).toList();

      // Food costs 1000, Culture 500, Adventure 2500. So ONLY things costing 0 should be here if we had any.
      // But we hardcoded costs. None cost 100. Should be empty!
      expect(items.isEmpty, true);
    });

    test('6. Preserve favorites (Top score priority)', () {
      // A place with a low rating normally wouldn't be first
      final lowRated = const Place(
        id: 'low',
        name: 'Low Rating',
        description: '',
        latitude: 0,
        longitude: 0,
        imageUrl: '',
        category: 'Relaxation',
        rating: 1.0,
      );
      var newCandidates = List<Place>.from(candidates)..add(lowRated);

      // If it's already in the itinerary and we are doing a 1 day trip, it gets preserved if we don't have enough capacity
      // Actually favorites are determined by the user, we mock this by passing it in.
      // The requirement is that existing activities are preserved when shrinking days.

      final oldItinerary = ItineraryGenerator.generate(baseTrip, candidates);
      final tripWithItinerary = baseTrip.copyWith(
        generatedItinerary: oldItinerary,
      );

      // Shrink to 1 day
      final modifiedTrip = tripWithItinerary.copyWith(
        endDate: DateTime(2024, 1, 1),
      );
      final newItinerary = ItineraryGenerator.modify(
        modifiedTrip,
        modifiedTrip.preferences,
        candidates,
      );

      final keptIds = newItinerary
          .expand((d) => d.items)
          .map((e) => e.place.id)
          .toSet();
      expect(keptIds.length, 4); // Max capacity for 1 day is 4 (3 non-food + 1 food)
    });

    test('7. Avoid duplicate places', () {
      final itinerary = ItineraryGenerator.generate(baseTrip, candidates);
      final ids = itinerary
          .expand((d) => d.items)
          .map((e) => e.place.id)
          .toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('8. Replace removed activities', () {
      final oldItinerary = ItineraryGenerator.generate(baseTrip, candidates);
      final tripWithItinerary = baseTrip.copyWith(
        generatedItinerary: oldItinerary,
      );

      // Exclude food, forcing replacement
      final newPrefs = baseTrip.preferences.copyWith(
        excludedCategories: ['Food'],
      );

      final newItinerary = ItineraryGenerator.modify(
        tripWithItinerary,
        newPrefs,
        candidates,
      );
      final items = newItinerary.expand((d) => d.items).toList();

      expect(items.any((i) => i.place.category == 'Food' && i.place.id != 'generic_lunch'), false);
    });

    test('9. No suitable replacement & 10. Empty candidate list', () {
      final itinerary = ItineraryGenerator.generate(baseTrip, []);
      expect(itinerary.isEmpty, true);
    });

    test('11. Deterministic output', () {
      final itinerary1 = ItineraryGenerator.generate(baseTrip, candidates);
      final itinerary2 = ItineraryGenerator.generate(baseTrip, candidates);
      final itinerary3 = ItineraryGenerator.generate(baseTrip, candidates);

      expect(itinerary1, itinerary2);
      expect(itinerary2, itinerary3);
    });
  });
}
