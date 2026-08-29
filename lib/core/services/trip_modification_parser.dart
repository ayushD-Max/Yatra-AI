import '../models/trip_modification.dart';

class TripModificationParser {
  static TripModification parse(String input) {
    final lower = input.toLowerCase();

    int? newDuration;
    int? newBudget;
    String? budgetDirection;
    List<String> addCategories = [];
    List<String> removeCategories = [];
    double? indoorOutdoorPref;

    // 1. Duration parsing
    final durationRegex = RegExp(
      r'(one|two|three|four|five|six|seven|1|2|3|4|5|6|7)\s+days?',
    );
    final match = durationRegex.firstMatch(lower);
    if (match != null) {
      final val = match.group(1);
      switch (val) {
        case '1':
        case 'one':
          newDuration = 1;
          break;
        case '2':
        case 'two':
          newDuration = 2;
          break;
        case '3':
        case 'three':
          newDuration = 3;
          break;
        case '4':
        case 'four':
          newDuration = 4;
          break;
        case '5':
        case 'five':
          newDuration = 5;
          break;
        case '6':
        case 'six':
          newDuration = 6;
          break;
        case '7':
        case 'seven':
          newDuration = 7;
          break;
      }
    }

    // 2. Budget parsing
    final budgetRegex = RegExp(r'(?:rs\.?|₹|inr)?\s*(\d+(?:,\d+)*)\s*(?:rs\.?|₹|inr|budget|es|buck|rupees)?');
    final budgetMatch = budgetRegex.firstMatch(lower);
    if (budgetMatch != null) {
      final valStr = budgetMatch.group(1)!.replaceAll(',', '');
      final parsed = int.tryParse(valStr);
      if (parsed != null && parsed >= 0) {
        newBudget = parsed;
      }
    }

    if (lower.contains('cheaper') ||
        lower.contains('less money') ||
        (lower.contains('budget') && newBudget == null)) {
      budgetDirection = 'decrease';
    } else if (lower.contains('more expensive') || lower.contains('luxury')) {
      budgetDirection = 'increase';
    }

    // 3. Indoor/Outdoor
    if (lower.contains('no outdoor') ||
        lower.contains("don't want outdoor") ||
        lower.contains('remove outdoor')) {
      indoorOutdoorPref = -1.0;
      removeCategories.add('Outdoor');
    } else if (lower.contains('more outdoor') ||
        lower.contains('want outdoor')) {
      indoorOutdoorPref = 1.0;
      addCategories.add('Outdoor');
    }

    if (lower.contains('no indoor') ||
        lower.contains("don't want indoor") ||
        lower.contains('remove indoor')) {
      indoorOutdoorPref = 1.0;
      removeCategories.add('Indoor');
    } else if (lower.contains('more indoor') || lower.contains('want indoor')) {
      indoorOutdoorPref = -1.0;
      addCategories.add('Indoor');
    }

    // 4. Category parsing
    if (lower.contains('food') ||
        lower.contains('eat') ||
        lower.contains('restaurant')) {
      if (lower.contains('no food') ||
          lower.contains('remove food') ||
          lower.contains('no eat') ||
          lower.contains('no restaurant')) {
        removeCategories.add('Food');
      } else {
        addCategories.add('Food');
      }
    }

    if (lower.contains('culture') ||
        lower.contains('history') ||
        lower.contains('museum')) {
      if (lower.contains('no culture') ||
          lower.contains('remove culture') ||
          lower.contains('no history') ||
          lower.contains('remove history') ||
          lower.contains('no museum') ||
          lower.contains('remove museum')) {
        removeCategories.add('Culture');
        removeCategories.add('Historical');
      } else {
        addCategories.add('Culture');
        addCategories.add('Historical');
      }
    }

    if (lower.contains('adventure')) {
      if (lower.contains('no adventure') ||
          lower.contains('remove adventure')) {
        removeCategories.add('Adventure');
      } else {
        addCategories.add('Adventure');
      }
    }

    if (lower.contains('nature') || lower.contains('relax')) {
      if (lower.contains('no nature') ||
          lower.contains('remove nature') ||
          lower.contains('no relax') ||
          lower.contains('remove relax')) {
        removeCategories.add('Nature');
      } else {
        addCategories.add('Nature');
      }
    }

    // 5. Known Places parsing (with typo handling for rajgad/rajadad)
    final knownPlaces = {
      'Rajgad Fort': ['rajgad', 'rajadad', 'rajgad fort'],
      'Sinhagad Fort': ['sinhagad', 'sinhgad', 'sinhagad fort'],
      'Visapur Fort': ['visapur', 'visapur fort'],
      'Waari Book Cafe': ['waari', 'waari book', 'waari cafe'],
      'Shaniwar Wada': ['shaniwar', 'shaniwar wada'],
      'Dagdusheth Halwai Ganpati Temple': ['dagdusheth', 'dagdusheth ganpati', 'ganpati temple'],
      'Aga Khan Palace': ['aga khan', 'aga khan palace'],
    };

    List<String> addSpecificPlaces = [];
    List<String> removeSpecificPlaces = [];

    for (var entry in knownPlaces.entries) {
      final fullName = entry.key;
      final keywords = entry.value;
      for (var kw in keywords) {
        if (lower.contains(kw)) {
          final idx = lower.indexOf(kw);
          final prefix = idx > 15 ? lower.substring(idx - 15, idx) : lower.substring(0, idx);
          if (prefix.contains('remove') ||
              prefix.contains('delete') ||
              prefix.contains('no ') ||
              prefix.contains('avoid') ||
              prefix.contains("don't") ||
              prefix.contains("dont") ||
              prefix.contains('exclude')) {
            removeSpecificPlaces.add(fullName);
          } else {
            addSpecificPlaces.add(fullName);
          }
          break;
        }
      }
    }

    if (lower.contains('only') && addSpecificPlaces.isNotEmpty) {
      final addedSet = addSpecificPlaces.toSet();
      for (var fullName in knownPlaces.keys) {
        if (!addedSet.contains(fullName)) {
          removeSpecificPlaces.add(fullName);
        }
      }
    }

    // Build friendly conversational explanation for the local parser fallback
    String explanation = "I've updated your itinerary based on your preferences.";
    if (newDuration != null) {
      explanation = "I've changed your trip duration to $newDuration ${newDuration == 1 ? 'day' : 'days'}.";
    }
    if (newBudget != null) {
      explanation += " I also updated your budget to ₹$newBudget.";
    }
    if (addSpecificPlaces.isNotEmpty) {
      explanation += " I made sure to include ${addSpecificPlaces.join(', ')} in your schedule.";
    }

    return TripModification(
      duration: newDuration,
      budget: newBudget,
      budgetDirection: budgetDirection,
      indoorOutdoorPreference: indoorOutdoorPref,
      preferredCategories: addCategories.isNotEmpty ? addCategories : null,
      excludedCategories: removeCategories.isNotEmpty ? removeCategories : null,
      addSpecificPlaces: addSpecificPlaces.isNotEmpty ? addSpecificPlaces : null,
      removeSpecificPlaces: removeSpecificPlaces.isNotEmpty ? removeSpecificPlaces : null,
      aiExplanation: explanation,
    );
  }
}
