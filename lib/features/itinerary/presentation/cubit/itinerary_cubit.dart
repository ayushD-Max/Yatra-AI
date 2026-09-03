import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/place.dart';
import '../../../../core/models/itinerary.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/repositories/place_repository.dart';
import '../../../../core/services/itinerary_generator.dart';
import '../../../../core/models/trip_modification.dart';
import '../../../../core/services/trip_modification_parser.dart';
import '../../../../core/services/gemini_service.dart';
import 'itinerary_state.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final PlaceRepository placeRepository;
  final GeminiService geminiService;
  final SharedPreferences prefs;
  static const _tripKey = 'current_trip';
  static const _geminiTimeout = Duration(seconds: 30);

  Trip? currentTrip;

  ItineraryCubit(this.placeRepository, this.geminiService, this.prefs)
      : super(ItineraryInitial()) {
    _loadTrip();
  }

  void _loadTrip() {
    try {
      final tripJson = prefs.getString(_tripKey);
      if (tripJson != null) {
        currentTrip = Trip.fromJson(jsonDecode(tripJson));
        if (currentTrip?.generatedItinerary != null &&
            currentTrip!.generatedItinerary!.isNotEmpty) {
          emit(
            ItineraryLoaded(
              Itinerary(
                tripId: currentTrip!.id,
                days: currentTrip!.generatedItinerary!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      prefs.remove(_tripKey);
    }
  }

  void _saveTrip() {
    if (currentTrip != null) {
      prefs.setString(_tripKey, jsonEncode(currentTrip!.toJson()));
    }
  }

  void clearTrip() {
    prefs.remove(_tripKey);
    currentTrip = null;
    emit(ItineraryInitial());
  }

  void startPreChat(Trip trip, Place anchorPlace) {
    currentTrip = trip;
    _saveTrip();

    final message = "I see you want to visit ${anchorPlace.name}. Is this the main place you definitely want to visit?";
    emit(ItineraryPreChat(trip, anchorPlace, [{'role': 'ai', 'text': message}], false));
  }



  Future<void> sendPreChatMessage(String text) async {
    if (state is! ItineraryPreChat) return;

    final currentState = state as ItineraryPreChat;
    final updatedHistory = List<Map<String, String>>.from(currentState.chatHistory);
    updatedHistory.add({'role': 'user', 'text': text});

    emit(currentState.copyWith(chatHistory: updatedHistory, isTyping: true));

    try {
      final tripContext = 'Destination: ${currentState.trip.destination?.name}\n'
          'Budget: ${currentState.trip.preferences.budget != null ? '₹${currentState.trip.preferences.budget}' : 'Not set (Optional)'}\n'
          'Duration: ${currentState.trip.preferences.numberOfDays ?? 'Not set'} days\n'
          'Travel Style: ${currentState.trip.preferences.travelStyle}\n'
          'Anchor Place: ${currentState.anchorPlace.name}\n'
          'Available Time: ${currentState.trip.preferences.availableTimeMinutes != null ? '${currentState.trip.preferences.availableTimeMinutes} minutes' : 'Not set'}\n'
          'Start Time: ${currentState.trip.preferences.startTime ?? 'Not set'}\n'
          'Include Nearby: ${currentState.trip.preferences.includeNearbyPlaces != null ? currentState.trip.preferences.includeNearbyPlaces : 'Not set'}';

      final historyString = updatedHistory.map((m) => '${m['role']}: ${m['text']}').join('\n');

      final response = await geminiService.processPreChat(text, historyString, tripContext).timeout(_geminiTimeout);

      updatedHistory.add({'role': 'ai', 'text': response.message});

      var newPrefs = currentState.trip.preferences;
      if (response.budget != null) {
        newPrefs = newPrefs.copyWith(budget: response.budget!);
      }
      if (response.days != null) {
        newPrefs = newPrefs.copyWith(numberOfDays: response.days);
      }
      if (response.availableTimeMinutes != null) {
        newPrefs = newPrefs.copyWith(availableTimeMinutes: response.availableTimeMinutes);
      }
      if (response.includeNearbyPlaces != null) {
        newPrefs = newPrefs.copyWith(includeNearbyPlaces: response.includeNearbyPlaces);
      }
      if (response.tripType != null) {
        newPrefs = newPrefs.copyWith(travelStyle: response.tripType);
      }
      if (response.startTime != null) {
        newPrefs = newPrefs.copyWith(startTime: response.startTime);
      }

      var endDate = currentState.trip.endDate;
      if (newPrefs != currentState.trip.preferences) {
        if (newPrefs.numberOfDays != null && currentState.trip.startDate != null) {
          endDate = currentState.trip.startDate!.add(Duration(days: newPrefs.numberOfDays! - 1));
        }
      }

      final finalTrip = currentState.trip.copyWith(preferences: newPrefs, endDate: endDate);
      currentTrip = finalTrip;
      _saveTrip();

      emit(currentState.copyWith(
        trip: finalTrip,
        chatHistory: updatedHistory,
        isTyping: false,
      ));

      if (response.readyToGenerate) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await generateItinerary(finalTrip, [currentState.anchorPlace]);
      }
    } catch (e) {
      print('PreChat Error: $e');
      updatedHistory.add({'role': 'ai', 'text': "I couldn't reach the AI right now. Please try again."});
      emit(currentState.copyWith(
        chatHistory: updatedHistory,
        isTyping: false,
      ));
    }
  }

  Future<void> generateItinerary(Trip trip, List<Place> selectedPlaces) async {
    List<Map<String, String>> history = [];
    if (state is ItineraryPreChat) {
      history = List.from((state as ItineraryPreChat).chatHistory);
    }
    
    emit(ItineraryGenerating());

    try {
      // Simulate real-world generator processing time to let skeleton UI shine
      await Future.delayed(const Duration(milliseconds: 1500));

      final duration = trip.durationInDays;
      if (duration <= 0) throw Exception('Invalid trip duration');

      // Fetch all candidate places for this destination to build the perfect trip
      List<Place> candidates = List.from(selectedPlaces);
      if (trip.destination != null) {
        final destPlaces = await placeRepository.getPlacesForDestination(
          trip.destination!.id,
        );
        // Avoid adding duplicates
        final existingIds = candidates.map((p) => p.id).toSet();
        candidates.addAll(destPlaces.where((p) => !existingIds.contains(p.id)));
      }

      List<ItineraryDay> days = [];
      
      // If we have a robust chat history, let the AI generate the final schedule!
      if (history.isNotEmpty && history.length > 1) {
        try {
          final availablePlaces = candidates.map((p) => {
            'id': p.id,
            'name': p.name,
            'category': p.category,
            'duration': p.estimatedVisitDuration,
          }).toList();
          
          final aiSchedule = await geminiService.generateFinalItinerary(
            trip.destination?.name ?? 'Unknown',
            duration,
            history,
            availablePlaces,
          );
          
          days = ItineraryGenerator.parseAiSchedule(aiSchedule, candidates, trip.startDate ?? DateTime.now());
          
          // Fallback if AI returned empty
          if (days.isEmpty) {
            days = ItineraryGenerator.generate(trip, candidates);
          }
        } catch (e) {
          print('Cubit: AI Generation failed, falling back to greedy algorithm. Error: $e');
          days = ItineraryGenerator.generate(trip, candidates);
        }
      } else {
        days = ItineraryGenerator.generate(trip, candidates);
      }

      currentTrip = trip.copyWith(generatedItinerary: days);
      _saveTrip();

      emit(ItineraryLoaded(Itinerary(tripId: trip.id, days: days)));
    } catch (e) {
      emit(ItineraryError('Failed to generate itinerary: $e'));
    }
  }

  /// Handles natural language requests:
  /// - If no trip exists yet, creates one from scratch (cold start)
  /// - If a trip exists, modifies it based on the request
  Future<void> modifyItinerary(String request) async {
    // If no trip exists, create one from scratch using the chat input
    if (state is! ItineraryLoaded || currentTrip == null) {
      return _generateFromChat(request);
    }

    final currentState = state as ItineraryLoaded;

    emit(ItineraryGenerating());

    try {
      final currentItinerary = currentState.itinerary;
      final currentPlaces = currentItinerary.days
          .expand((day) => day.items.map((it) => it.place.name))
          .toSet()
          .toList();
      final currentContext =
          'Destination: ${currentTrip!.destination?.name ?? "Pune"}\n'
          'Current Budget: ₹${currentTrip!.preferences.budget}\n'
          'Current Travel Style: ${currentTrip!.preferences.travelStyle}\n'
          'Current Duration: ${currentTrip!.preferences.numberOfDays} days\n'
          'Current Itinerary Places: ${currentPlaces.join(", ")}';

      TripModification modification;
      try {
        modification = await geminiService.parseTripModification(
          request,
          currentContext: currentContext,
        );
      } catch (e) {
        modification = TripModificationParser.parse(request);
      }

      // Update preferences based on modification
      var newPrefs = currentTrip!.preferences;

      if (modification.budget != null) {
        newPrefs = newPrefs.copyWith(budget: modification.budget!);
      } else if (modification.budgetDirection == 'decrease' && newPrefs.budget != null) {
        newPrefs = newPrefs.copyWith(budget: (newPrefs.budget! * 0.7).toInt());
      } else if (modification.budgetDirection == 'increase' && newPrefs.budget != null) {
        newPrefs = newPrefs.copyWith(budget: (newPrefs.budget! * 1.5).toInt());
      }

      if (modification.indoorOutdoorPreference != null) {
        newPrefs = newPrefs.copyWith(
          indoorOutdoorPreference: modification.indoorOutdoorPreference,
        );
      }

      if (modification.preferredCategories != null &&
          modification.preferredCategories!.isNotEmpty) {
        newPrefs = newPrefs.copyWith(
          preferredCategories: [
            ...newPrefs.preferredCategories,
            ...modification.preferredCategories!,
          ],
        );
      }

      if (modification.excludedCategories != null &&
          modification.excludedCategories!.isNotEmpty) {
        newPrefs = newPrefs.copyWith(
          excludedCategories: [
            ...newPrefs.excludedCategories,
            ...modification.excludedCategories!,
          ],
        );
      }

      // Update dates if duration changed
      DateTime? newEndDate = currentTrip!.endDate;
      if (modification.duration != null && currentTrip!.startDate != null) {
        newPrefs = newPrefs.copyWith(numberOfDays: modification.duration);
        newEndDate = currentTrip!.startDate!.add(
          Duration(days: modification.duration! - 1),
        );
      }

      final tempTrip = currentTrip!.copyWith(
        preferences: newPrefs,
        endDate: newEndDate,
      );

      // Fetch full candidates again to fill any gaps
      List<Place> candidates = [];
      if (tempTrip.destination != null) {
        String destKey = tempTrip.destination!.id;
        if (destKey.isEmpty || destKey.startsWith('ChIJ') || destKey.length > 20) {
          destKey = tempTrip.destination!.name.split(',')[0].trim().toLowerCase();
        }
        candidates = await placeRepository.getPlacesForDestination(
          destKey,
        );
      }

      final updatedDays = ItineraryGenerator.modify(
        tempTrip,
        newPrefs,
        candidates,
        modification: modification,
      );

      currentTrip = tempTrip.copyWith(generatedItinerary: updatedDays);
      _saveTrip();

      emit(
        ItineraryLoaded(
          currentState.itinerary.copyWith(days: updatedDays),
          aiExplanation: modification.aiExplanation,
        ),
      );
    } catch (e) {
      emit(ItineraryError('Failed to modify itinerary: $e'));
    }
  }

  void removePlace(String placeId, int dayIndex) {
    if (state is ItineraryLoaded && currentTrip != null && currentTrip!.generatedItinerary != null) {
      try {
        final currentDays = List<ItineraryDay>.from(currentTrip!.generatedItinerary!);
        if (dayIndex >= 0 && dayIndex < currentDays.length) {
          final targetDay = currentDays[dayIndex];
          final updatedItems = targetDay.items.where((item) => item.place.id != placeId).toList();
          
          currentDays[dayIndex] = targetDay.copyWith(items: updatedItems);
          
          currentTrip = currentTrip!.copyWith(generatedItinerary: currentDays);
          _saveTrip();
          
          final currentState = state as ItineraryLoaded;
          emit(
            ItineraryLoaded(
              currentState.itinerary.copyWith(days: currentDays),
              aiExplanation: currentState.aiExplanation,
            ),
          );
        }
      } catch (e) {
        emit(ItineraryError('Failed to remove place: $e'));
      }
    }
  }

  /// Cold-start: Generate an itinerary purely from a chat message
  /// when no trip exists yet. Parses the user's request to extract
  /// destination, duration, budget, and preferences.
  Future<void> _generateFromChat(String request) async {
    emit(ItineraryGenerating());

    try {
      // Parse the request to extract trip parameters
      TripModification modification;
      try {
        modification = await geminiService.parseTripModification(request);
      } catch (e) {
        modification = TripModificationParser.parse(request);
      }

      // Extract or default parameters
      final int days = modification.duration ?? 2;
      final int budget = modification.budget ?? 15000;
      final String travelStyle = modification.travelStyle ?? 'Adventure';

      // Default to Pune as the base destination
      String destId = 'pune';
      String destName = 'Pune';

      // Try to detect destination from the request
      final lower = request.toLowerCase();
      final knownDests = {
        'mumbai': 'Mumbai',
        'goa': 'Goa',
        'jaipur': 'Jaipur',
        'varanasi': 'Varanasi',
        'delhi': 'Delhi',
        'chennai': 'Chennai',
        'pune': 'Pune',
        'lonavala': 'Lonavala',
        'mahabaleshwar': 'Mahabaleshwar',
      };

      for (var entry in knownDests.entries) {
        if (lower.contains(entry.key)) {
          destId = entry.key;
          destName = entry.value;
          break;
        }
      }

      // Also check if specific places mentioned map to a destination
      final puneKeywords = [
        'rajgad', 'rajadad', 'sinhagad', 'sinhgad', 'visapur',
        'shaniwar', 'dagdusheth', 'aga khan', 'tamhini', 'lonavala',
        'pawna', 'mulshi', 'khadakwasla', 'vetal', 'parvati',
        'lohagad', 'torna', 'tikona',
      ];
      for (var kw in puneKeywords) {
        if (lower.contains(kw)) {
          destId = 'pune';
          destName = 'Pune';
          break;
        }
      }

      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(Duration(days: days - 1));

      final trip = Trip(
        id: 'trip_${now.millisecondsSinceEpoch}',
        destination: Destination(
          id: destId,
          name: destName,
          country: 'India',
          region: 'Maharashtra',
          description: 'AI-generated trip to $destName',
          imageUrl: '',
          latitude: 18.5204,
          longitude: 73.8567,
        ),
        startDate: startDate,
        endDate: endDate,
        preferences: TripPreferences(
          budget: budget,
          numberOfDays: days,
          travelStyle: travelStyle,
          indoorOutdoorPreference:
              modification.indoorOutdoorPreference ?? 0.0,
          preferredCategories: modification.preferredCategories ?? [],
          excludedCategories: modification.excludedCategories ?? [],
        ),
      );

      // Fetch candidates
      List<Place> candidates = await placeRepository.getPlacesForDestination(
        destId,
      );

      // If modification specifies specific places, ensure those are prioritized
      if (modification.addSpecificPlaces != null &&
          modification.addSpecificPlaces!.isNotEmpty) {
        // Move matched places to the front of candidates
        final toAdd = modification.addSpecificPlaces!
            .map((p) => p.toLowerCase().trim())
            .toSet();
        final matched = <Place>[];
        final rest = <Place>[];
        for (var c in candidates) {
          if (toAdd.contains(c.name.toLowerCase().trim())) {
            matched.add(c);
          } else {
            rest.add(c);
          }
        }
        candidates = [...matched, ...rest];
      }

      // If no candidates found, try the fallback searchPlaces
      if (candidates.isEmpty) {
        candidates = await placeRepository.searchPlaces(destName);
      }

      if (candidates.isEmpty) {
        emit(const ItineraryError(
          'No places found for this destination. Try searching for a different location.',
        ));
        return;
      }

      final generatedDays = ItineraryGenerator.generate(trip, candidates);

      if (generatedDays.isEmpty) {
        emit(const ItineraryError(
          'Could not generate an itinerary with your budget and preferences. Try increasing your budget or duration.',
        ));
        return;
      }

      currentTrip = trip.copyWith(generatedItinerary: generatedDays);
      _saveTrip();

      // Build explanation
      final explanation = modification.aiExplanation ??
          "I've planned a $days-day trip to $destName with a budget of ₹$budget! "
          "Your itinerary includes ${generatedDays.expand((d) => d.items).length} activities "
          "across ${generatedDays.length} ${generatedDays.length == 1 ? 'day' : 'days'}. "
          "Feel free to modify it — just tell me what you'd like to change!";

      emit(
        ItineraryLoaded(
          Itinerary(tripId: trip.id, days: generatedDays),
          aiExplanation: explanation,
        ),
      );
    } catch (e) {
      emit(ItineraryError('Failed to generate trip: $e'));
    }
  }
}
