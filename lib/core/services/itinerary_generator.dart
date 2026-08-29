import '../models/itinerary.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../models/trip_modification.dart';

class ItineraryGenerator {
  /// Generates a completely new itinerary based on trip preferences.
  static List<ItineraryDay> generate(Trip trip, List<Place> candidates) {
    if (trip.startDate == null || trip.endDate == null) return [];

    final numDays = trip.durationInDays;
    if (numDays <= 0) return [];

    final scoredPlaces = _scoreAndFilterPlaces(trip.preferences, candidates);

    // Sort descending by score, then alphabetically by ID for determinism
    scoredPlaces.sort((a, b) {
      if (b.value != a.value) return b.value.compareTo(a.value);
      return a.key.id.compareTo(b.key.id);
    });

    final List<Place> selectedPlaces = scoredPlaces.map((e) => e.key).toList();

    return _distributePlacesToDays(selectedPlaces, numDays, trip.startDate!);
  }

  /// Modifies an existing itinerary based on new preferences and preserved items.
  static List<ItineraryDay> modify(
    Trip currentTrip,
    TripPreferences newPrefs,
    List<Place> allCandidates, {
    TripModification? modification,
  }) {
    final numDays = currentTrip.copyWith(preferences: newPrefs).durationInDays;
    if (numDays <= 0) return [];

    // 1. Flatten existing itinerary to preserve items
    final existingItems =
        currentTrip.generatedItinerary
            ?.expand((day) => day.items)
            .map((e) => e.place)
            .toList() ??
        [];

    // Apply specific removals from modification
    if (modification != null &&
        modification.removeSpecificPlaces != null &&
        modification.removeSpecificPlaces!.isNotEmpty) {
      final toRemove = modification.removeSpecificPlaces!
          .map((p) => p.toLowerCase().trim())
          .toSet();
      existingItems.removeWhere((place) {
        return toRemove.contains(place.name.toLowerCase().trim()) ||
            toRemove.contains(place.id.toLowerCase().trim());
      });
    }

    // 2. Score existing items with NEW preferences to see if they survive
    final scoredExisting = _scoreAndFilterPlaces(newPrefs, existingItems);
    scoredExisting.sort((a, b) {
      if (b.value != a.value) return b.value.compareTo(a.value);
      return a.key.id.compareTo(b.key.id);
    });

    final existingFood = scoredExisting
        .where((e) =>
            e.key.category.toLowerCase().contains('food') ||
            e.key.category.toLowerCase().contains('cafe'))
        .toList();
    final existingNonFood =
        scoredExisting.where((e) => !existingFood.contains(e)).toList();

    // Forced additions from modification
    List<Place> forcedAdditions = [];
    if (modification != null &&
        modification.addSpecificPlaces != null &&
        modification.addSpecificPlaces!.isNotEmpty) {
      final toAdd = modification.addSpecificPlaces!
          .map((p) => p.toLowerCase().trim())
          .toSet();
      for (var candidate in allCandidates) {
        if (toAdd.contains(candidate.name.toLowerCase().trim()) ||
            toAdd.contains(candidate.id.toLowerCase().trim())) {
          forcedAdditions.add(candidate);
        }
      }
    }

    List<Place> preservedPlaces = [
      ...forcedAdditions,
      ...existingFood.map((e) => e.key).take(numDays),
      ...existingNonFood.map((e) => e.key).take(numDays * 3),
    ];

    // Filter duplicates
    final seenIds = <String>{};
    preservedPlaces = preservedPlaces.where((p) => seenIds.add(p.id)).toList();

    // 3. Fill gaps if we have fewer places than capacity for each category
    final int maxFoodCapacity = numDays;
    final int maxNonFoodCapacity = numDays * 3;

    final Set<String> preservedIds = preservedPlaces.map((e) => e.id).toSet();
    final unselectedCandidates = allCandidates
        .where((p) => !preservedIds.contains(p.id))
        .toList();

    final scoredCandidates = _scoreAndFilterPlaces(newPrefs, unselectedCandidates);
    scoredCandidates.sort((a, b) {
      if (b.value != a.value) return b.value.compareTo(a.value);
      return a.key.id.compareTo(b.key.id);
    });

    final candidateFood = scoredCandidates
        .where((e) =>
            e.key.category.toLowerCase().contains('food') ||
            e.key.category.toLowerCase().contains('cafe'))
        .toList();
    final candidateNonFood =
        scoredCandidates.where((e) => !candidateFood.contains(e)).toList();

    final preservedFoodCount = preservedPlaces
        .where((p) =>
            p.category.toLowerCase().contains('food') ||
            p.category.toLowerCase().contains('cafe'))
        .length;
    final preservedNonFoodCount = preservedPlaces.length - preservedFoodCount;

    if (preservedFoodCount < maxFoodCapacity) {
      final gaps = maxFoodCapacity - preservedFoodCount;
      preservedPlaces.addAll(candidateFood.map((e) => e.key).take(gaps));
    }
    if (preservedNonFoodCount < maxNonFoodCapacity) {
      final gaps = maxNonFoodCapacity - preservedNonFoodCount;
      preservedPlaces.addAll(candidateNonFood.map((e) => e.key).take(gaps));
    }

    // 4. Re-score the final combined list to sort them properly before distributing
    final finalScored = _scoreAndFilterPlaces(newPrefs, preservedPlaces);
    finalScored.sort((a, b) {
      if (b.value != a.value) return b.value.compareTo(a.value);
      return a.key.id.compareTo(b.key.id);
    });

    final finalPlaces = finalScored.map((e) => e.key).toList();

    return _distributePlacesToDays(
      finalPlaces,
      numDays,
      currentTrip.startDate!,
    );
  }

  static List<MapEntry<Place, double>> _scoreAndFilterPlaces(
    TripPreferences prefs,
    List<Place> places,
  ) {
    final List<MapEntry<Place, double>> scored = [];

    for (var place in places) {
      // Hard Filters
      bool exclude = false;
      for (var ec in prefs.excludedCategories) {
        if (place.category.toLowerCase() == ec.toLowerCase() ||
            place.tags.any((t) => t.toLowerCase() == ec.toLowerCase()) ||
            (ec.toLowerCase() == 'outdoor' && place.isOutdoor) ||
            (ec.toLowerCase() == 'indoor' && !place.isOutdoor)) {
          exclude = true;
          break;
        }
      }
      if (prefs.indoorOutdoorPreference == -1.0 && place.isOutdoor) {
        exclude = true;
      }
      if (prefs.indoorOutdoorPreference == 1.0 && !place.isOutdoor) {
        exclude = true;
      }
      if (exclude) continue;

      // Cost estimation based on category (rough logic for budget filtering)
      int estimatedCost = 500; // Default base cost
      if (place.category == 'Food') {
        estimatedCost = 1000;
      } else if (place.category == 'Culture' ||
          place.category == 'Historical') {
        estimatedCost = 800;
      } else if (place.category == 'Adventure') {
        estimatedCost = 2500;
      } else if (place.category == 'Relaxation') {
        estimatedCost = 1500;
      }

      if (estimatedCost > prefs.budget) continue;

      // Scoring
      double score = 10.0; // Base score
      score += place.rating * 5; // Up to 25 pts

      for (var pc in prefs.preferredCategories) {
        if (place.category.toLowerCase() == pc.toLowerCase() ||
            place.tags.any((t) => t.toLowerCase() == pc.toLowerCase())) {
          score += 20;
        }
      }

      if (place.tags.any(
        (t) => t.toLowerCase() == prefs.travelStyle.toLowerCase(),
      )) {
        score += 15;
      }

      // Attribute scaling
      if (place.isOutdoor) {
        score += (prefs.indoorOutdoorPreference * 15);
      } else {
        score += (-prefs.indoorOutdoorPreference * 15);
      }

      if (place.category == 'Food') score += (prefs.foodPreference * 10);
      if (place.category == 'Culture' || place.category == 'Historical') {
        score += (prefs.culturePreference * 10);
      }
      if (place.category == 'Adventure') {
        score += (prefs.adventurePreference * 10);
      }

      scored.add(MapEntry(place, score));
    }

    return scored;
  }

  static double _distanceSq(Place p1, Place p2) {
    final double dx = p1.latitude - p2.latitude;
    final double dy = p1.longitude - p2.longitude;
    return dx * dx + dy * dy;
  }

  static List<ItineraryDay> _distributePlacesToDays(
    List<Place> places,
    int numDays,
    DateTime startDate,
  ) {
    if (places.isEmpty) return [];
    final List<ItineraryDay> days = [];

    // Find food places for lunch/dinner
    final List<Place> foodPlaces = places
        .where(
          (p) =>
              p.category.toLowerCase().contains('food') ||
              p.category.toLowerCase().contains('cafe'),
        )
        .toList();
    final List<Place> nonFoodPlaces = places.where((p) => !foodPlaces.contains(p)).toList();

    final Set<String> usedIds = {};

    for (int i = 0; i < numDays; i++) {
      final date = startDate.add(Duration(days: i));
      final List<ItineraryItem> items = [];

      // Slot 1: Morning Activity (10:00 - 12:00)
      Place? morningPlace;
      for (var p in nonFoodPlaces) {
        if (!usedIds.contains(p.id)) {
          morningPlace = p;
          usedIds.add(p.id);
          break;
        }
      }

      if (morningPlace != null) {
        final startTime = DateTime(date.year, date.month, date.day, 10, 0);
        items.add(
          ItineraryItem(
            id: '${morningPlace.id}_day${i + 1}_slot1',
            place: morningPlace,
            startTime: startTime,
            endTime: startTime.add(
              Duration(minutes: morningPlace.estimatedVisitDuration),
            ),
            notes: 'Travel: 🚗 15 mins drive from Hotel',
          ),
        );
      }

      // Slot 2: Lunch (13:00 - 14:30) - find CLOSEST unused food place
      Place? lunchPlace;
      double minFoodDist = double.infinity;
      for (var p in foodPlaces) {
        if (!usedIds.contains(p.id)) {
          final dist = morningPlace != null ? _distanceSq(morningPlace, p) : 0.0;
          if (dist < minFoodDist) {
            minFoodDist = dist;
            lunchPlace = p;
          }
        }
      }

      if (lunchPlace != null) {
        usedIds.add(lunchPlace.id);
        final startTime = DateTime(date.year, date.month, date.day, 13, 0);
        items.add(
          ItineraryItem(
            id: '${lunchPlace.id}_day${i + 1}_lunch',
            place: lunchPlace,
            startTime: startTime,
            endTime: startTime.add(const Duration(minutes: 90)),
            notes: 'Travel: 🚶 Close by (approx. 10 mins walk)',
          ),
        );
      } else {
        // Mock a generic lunch if no food place left
        final startTime = DateTime(date.year, date.month, date.day, 13, 0);
        items.add(
          ItineraryItem(
            id: 'mock_lunch_day${i + 1}',
            place: const Place(
              id: 'generic_lunch',
              name: 'Local Restaurant / Cafe',
              description: 'Time to grab some delicious local food!',
              latitude: 0,
              longitude: 0,
              imageUrl:
                  'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=600&auto=format&fit=crop',
              category: 'Food',
              isOutdoor: false,
            ),
            startTime: startTime,
            endTime: startTime.add(const Duration(minutes: 90)),
            notes: 'Travel: 🚶 5 mins walk',
          ),
        );
      }

      // Slot 3: Afternoon Activity (15:00 - 17:30) - find CLOSEST unused activity to lunch (or morning)
      final referencePlace = lunchPlace ?? morningPlace;
      Place? afternoonPlace;
      double minActivityDist = double.infinity;
      for (var p in nonFoodPlaces) {
        if (!usedIds.contains(p.id)) {
          final dist = referencePlace != null ? _distanceSq(referencePlace, p) : 0.0;
          if (dist < minActivityDist) {
            minActivityDist = dist;
            afternoonPlace = p;
          }
        }
      }

      if (afternoonPlace != null) {
        usedIds.add(afternoonPlace.id);
        final startTime = DateTime(date.year, date.month, date.day, 15, 0);
        items.add(
          ItineraryItem(
            id: '${afternoonPlace.id}_day${i + 1}_slot2',
            place: afternoonPlace,
            startTime: startTime,
            endTime: startTime.add(
              Duration(minutes: afternoonPlace.estimatedVisitDuration),
            ),
            notes: 'Travel: 🚗 Short drive (approx. 15 mins)',
          ),
        );
      }

      // Slot 4: Evening Activity / Dinner (19:00 - 21:00) - find CLOSEST unused activity to afternoon
      final ref2 = afternoonPlace ?? lunchPlace ?? morningPlace;
      Place? eveningPlace;
      double minEvDist = double.infinity;
      for (var p in nonFoodPlaces) {
        if (!usedIds.contains(p.id)) {
          final dist = ref2 != null ? _distanceSq(ref2, p) : 0.0;
          if (dist < minEvDist) {
            minEvDist = dist;
            eveningPlace = p;
          }
        }
      }

      if (eveningPlace != null) {
        usedIds.add(eveningPlace.id);
        final startTime = DateTime(date.year, date.month, date.day, 19, 0);
        items.add(
          ItineraryItem(
            id: '${eveningPlace.id}_day${i + 1}_slot3',
            place: eveningPlace,
            startTime: startTime,
            endTime: startTime.add(
              Duration(minutes: eveningPlace.estimatedVisitDuration),
            ),
            notes: 'Travel: 🚗 Short drive (approx. 20 mins)',
          ),
        );
      }

      if (items.isNotEmpty) {
        days.add(ItineraryDay(date: date, dayNumber: i + 1, items: items));
      }
    }

    return days;
  }
}
