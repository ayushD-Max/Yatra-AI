import '../models/itinerary.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../models/trip_modification.dart';

class ItineraryGenerator {
  static List<ItineraryDay> generate(Trip trip, List<Place> candidates) {
    if (trip.startDate == null || trip.endDate == null) return [];

    final numDays = trip.durationInDays;
    if (numDays <= 0) return [];

    final scoredPlaces = _scoreAndFilterPlaces(trip.preferences, candidates);

    Place? anchorPlace;
    if (trip.anchorPlaceId != null) {
      final anchorIndex = scoredPlaces.indexWhere((e) => e.key.id == trip.anchorPlaceId);
      if (anchorIndex != -1) {
        anchorPlace = scoredPlaces[anchorIndex].key;
        scoredPlaces[anchorIndex] = MapEntry(anchorPlace, 10000.0);
      } else {
        final rawAnchor = candidates.where((c) => c.id == trip.anchorPlaceId).firstOrNull;
        if (rawAnchor != null) {
          anchorPlace = rawAnchor;
          scoredPlaces.add(MapEntry(anchorPlace, 10000.0));
        }
      }
    }

    // Sort descending by score, then alphabetically by ID for determinism
    scoredPlaces.sort((a, b) {
      if (b.value != a.value) return b.value.compareTo(a.value);
      return a.key.id.compareTo(b.key.id);
    });

    final List<Place> selectedPlaces = scoredPlaces.map((e) => e.key).toList();

    return _distributePlacesToDays(
      selectedPlaces,
      numDays,
      trip.startDate!,
      anchorPlace: anchorPlace,
      availableTimeMinutes: trip.preferences.availableTimeMinutes,
      includeNearbyPlaces: trip.preferences.includeNearbyPlaces,
    );
  }

  static List<ItineraryDay> parseAiSchedule(
    List<Map<String, dynamic>> aiSchedule,
    List<Place> candidates,
    DateTime startDate,
  ) {
    final List<ItineraryDay> days = [];
    
    for (int i = 0; i < aiSchedule.length; i++) {
      final dayData = aiSchedule[i];
      final List<dynamic> itemsData = dayData['items'] ?? [];
      final List<ItineraryItem> items = [];
      
      for (var itemData in itemsData) {
        final placeId = itemData['placeId'];
        final place = candidates.where((p) => p.id == placeId).firstOrNull;
        if (place != null) {
          items.add(
            ItineraryItem(
              place: place,
              startTime: itemData['startTime'] ?? '10:00',
              endTime: itemData['endTime'] ?? '11:00',
            ),
          );
        }
      }
      
      days.add(
        ItineraryDay(
          dayNumber: i + 1,
          date: startDate.add(Duration(days: i)),
          items: items,
        ),
      );
    }
    
    return days;
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

    if (newPrefs.includeNearbyPlaces != false) {
      if (preservedFoodCount < maxFoodCapacity) {
        final gaps = maxFoodCapacity - preservedFoodCount;
        preservedPlaces.addAll(candidateFood.map((e) => e.key).take(gaps));
      }
      if (preservedNonFoodCount < maxNonFoodCapacity) {
        final gaps = maxNonFoodCapacity - preservedNonFoodCount;
        preservedPlaces.addAll(candidateNonFood.map((e) => e.key).take(gaps));
      }
    } else {
      // User requested ONLY the anchor place. 
      // We'll still add food if completely missing, since they need to eat, but no other attractions.
      if (preservedFoodCount < maxFoodCapacity) {
        final gaps = maxFoodCapacity - preservedFoodCount;
        preservedPlaces.addAll(candidateFood.map((e) => e.key).take(gaps));
      }
    }

    // 4. Re-score the final combined list to sort them properly before distributing
    final finalScored = _scoreAndFilterPlaces(newPrefs, preservedPlaces);
    
    Place? anchorPlace;
    if (currentTrip.anchorPlaceId != null) {
      anchorPlace = allCandidates.where((c) => c.id == currentTrip.anchorPlaceId).firstOrNull;
      if (anchorPlace != null) {
        final anchorIndex = finalScored.indexWhere((e) => e.key.id == anchorPlace!.id);
        if (anchorIndex != -1) {
          finalScored[anchorIndex] = MapEntry(anchorPlace, 10000.0);
        } else {
          finalScored.add(MapEntry(anchorPlace, 10000.0));
        }
      }
    }

    finalScored.sort((a, b) {
      if (b.value != a.value) return b.value.compareTo(a.value);
      return a.key.id.compareTo(b.key.id);
    });

    final finalPlaces = finalScored.map((e) => e.key).toList();

    return _distributePlacesToDays(
      finalPlaces,
      numDays,
      currentTrip.startDate!,
      anchorPlace: anchorPlace,
      availableTimeMinutes: newPrefs.availableTimeMinutes,
      includeNearbyPlaces: newPrefs.includeNearbyPlaces,
      startTime: newPrefs.startTime,
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

      if (prefs.budget != null && estimatedCost > prefs.budget!) continue;

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
    DateTime startDate, {
    Place? anchorPlace,
    int? availableTimeMinutes,
    bool? includeNearbyPlaces,
    String? startTime,
  }) {
    if (places.isEmpty) return [];
    final List<ItineraryDay> days = [];

    final List<Place> foodPlaces = places
        .where(
          (p) =>
              p.category.toLowerCase().contains('food') ||
              p.category.toLowerCase().contains('cafe'),
        )
        .toList();
    final List<Place> nonFoodPlaces = places.where((p) => !foodPlaces.contains(p)).toList();

    final Set<String> usedIds = {};
    
    final now = DateTime.now();
    final bool isToday = startDate.year == now.year && startDate.month == now.month && startDate.day == now.day;

    for (int i = 0; i < numDays; i++) {
      final date = startDate.add(Duration(days: i));
      final List<ItineraryItem> items = [];

      DateTime currentStartTime;
      
      bool startTimeParsed = false;
      if (i == 0 && startTime != null && startTime.isNotEmpty) {
        final match = RegExp(r'(\d+)(?::(\d+))?\s*(am|pm)?', caseSensitive: false).firstMatch(startTime);
        if (match != null) {
          int h = int.parse(match.group(1)!);
          int m = match.group(2) != null ? int.parse(match.group(2)!) : 0;
          String? ampm = match.group(3)?.toLowerCase();
          
          if (ampm == 'pm' && h < 12) h += 12;
          if (ampm == 'am' && h == 12) h = 0;
          
          currentStartTime = DateTime(date.year, date.month, date.day, h, m);
          startTimeParsed = true;
        } else {
          currentStartTime = DateTime(date.year, date.month, date.day, 9, 0); // fallback
        }
      } else {
        currentStartTime = DateTime(date.year, date.month, date.day, 9, 0); // initialization fallback
      }

      if (!startTimeParsed) {
        if (i == 0 && isToday) {
          int minutes = now.minute;
          int addMinutes = 15 - (minutes % 15);
          currentStartTime = now.add(Duration(minutes: addMinutes));
        } else {
          currentStartTime = DateTime(date.year, date.month, date.day, 9, 0);
        }
      }

      int minutesSpentToday = 0;

      // First place: prioritize Anchor Place if day 1
      Place? firstPlace;
      if (i == 0 && anchorPlace != null && !usedIds.contains(anchorPlace.id)) {
        firstPlace = anchorPlace;
        usedIds.add(firstPlace.id);
      } else {
        for (var p in nonFoodPlaces) {
          if (!usedIds.contains(p.id)) {
            firstPlace = p;
            usedIds.add(p.id);
            break;
          }
        }
      }

      if (firstPlace != null) {
        final duration = firstPlace.estimatedVisitDuration;
        items.add(
          ItineraryItem(
            id: '${firstPlace.id}_day${i + 1}_slot1',
            place: firstPlace,
            startTime: currentStartTime,
            endTime: currentStartTime.add(Duration(minutes: duration)),
            notes: 'Travel: 🚗 15 mins drive from Hotel',
          ),
        );
        currentStartTime = currentStartTime.add(Duration(minutes: duration + 15));
        minutesSpentToday += duration + 15;
      }

      if (availableTimeMinutes != null && minutesSpentToday >= availableTimeMinutes) {
        if (items.isNotEmpty) days.add(ItineraryDay(date: date, dayNumber: i + 1, items: items));
        continue;
      }

      Place? lunchPlace;
      double minFoodDist = double.infinity;
      final referenceForLunch = firstPlace ?? anchorPlace;
      for (var p in foodPlaces) {
        if (!usedIds.contains(p.id)) {
          final dist = referenceForLunch != null ? _distanceSq(referenceForLunch, p) : 0.0;
          if (dist < minFoodDist) {
            minFoodDist = dist;
            lunchPlace = p;
          }
        }
      }

      if (lunchPlace != null) {
        usedIds.add(lunchPlace.id);
        final duration = lunchPlace.estimatedVisitDuration > 0 ? lunchPlace.estimatedVisitDuration : 60;
        items.add(
          ItineraryItem(
            id: '${lunchPlace.id}_day${i + 1}_lunch',
            place: lunchPlace,
            startTime: currentStartTime,
            endTime: currentStartTime.add(Duration(minutes: duration)),
            notes: 'Travel: 🚶 Close by (approx. 10 mins walk)',
          ),
        );
        currentStartTime = currentStartTime.add(Duration(minutes: duration + 15));
        minutesSpentToday += duration + 15;
      } else {
        final duration = 60;
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
            startTime: currentStartTime,
            endTime: currentStartTime.add(Duration(minutes: duration)),
            notes: 'Travel: 🚶 5 mins walk',
          ),
        );
        currentStartTime = currentStartTime.add(Duration(minutes: duration + 15));
        minutesSpentToday += duration + 15;
      }

      if (availableTimeMinutes != null && minutesSpentToday >= availableTimeMinutes) {
        if (items.isNotEmpty) days.add(ItineraryDay(date: date, dayNumber: i + 1, items: items));
        continue;
      }

      final referenceForAfternoon = lunchPlace ?? firstPlace ?? anchorPlace;
      Place? afternoonPlace;
      double minActivityDist = double.infinity;
      for (var p in nonFoodPlaces) {
        if (!usedIds.contains(p.id)) {
          final dist = referenceForAfternoon != null ? _distanceSq(referenceForAfternoon, p) : 0.0;
          if (dist < minActivityDist) {
            minActivityDist = dist;
            afternoonPlace = p;
          }
        }
      }

      if (afternoonPlace != null) {
        usedIds.add(afternoonPlace.id);
        final duration = afternoonPlace.estimatedVisitDuration;
        items.add(
          ItineraryItem(
            id: '${afternoonPlace.id}_day${i + 1}_slot2',
            place: afternoonPlace,
            startTime: currentStartTime,
            endTime: currentStartTime.add(Duration(minutes: duration)),
            notes: 'Travel: 🚗 Short drive (approx. 15 mins)',
          ),
        );
        currentStartTime = currentStartTime.add(Duration(minutes: duration + 15));
        minutesSpentToday += duration + 15;
      }

      if (availableTimeMinutes != null && minutesSpentToday >= availableTimeMinutes) {
        if (items.isNotEmpty) days.add(ItineraryDay(date: date, dayNumber: i + 1, items: items));
        continue;
      }

      final referenceForEvening = afternoonPlace ?? lunchPlace ?? firstPlace ?? anchorPlace;
      Place? eveningPlace;
      double minEvDist = double.infinity;
      for (var p in nonFoodPlaces) {
        if (!usedIds.contains(p.id)) {
          final dist = referenceForEvening != null ? _distanceSq(referenceForEvening, p) : 0.0;
          if (dist < minEvDist) {
            minEvDist = dist;
            eveningPlace = p;
          }
        }
      }

      if (eveningPlace != null) {
        usedIds.add(eveningPlace.id);
        final duration = eveningPlace.estimatedVisitDuration;
        items.add(
          ItineraryItem(
            id: '${eveningPlace.id}_day${i + 1}_slot3',
            place: eveningPlace,
            startTime: currentStartTime,
            endTime: currentStartTime.add(Duration(minutes: duration)),
            notes: 'Travel: 🚗 Short drive (approx. 20 mins)',
          ),
        );
        currentStartTime = currentStartTime.add(Duration(minutes: duration + 15));
        minutesSpentToday += duration + 15;
      }

      if (items.isNotEmpty) {
        days.add(ItineraryDay(date: date, dayNumber: i + 1, items: items));
      }
    }

    return days;
  }
}
