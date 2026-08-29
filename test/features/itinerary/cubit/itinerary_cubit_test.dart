import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatra_ai/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:yatra_ai/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:yatra_ai/core/models/trip.dart';
import 'package:yatra_ai/core/models/place.dart';
import 'package:yatra_ai/core/repositories/mock_place_repository.dart';

import 'package:yatra_ai/core/services/gemini_service.dart';

void main() {
  group('ItineraryCubit Tests', () {
    late ItineraryCubit cubit;
    late SharedPreferences prefs;
    late GeminiService geminiService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      geminiService = GeminiService();
      cubit = ItineraryCubit(MockPlaceRepository(), geminiService, prefs);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state should be ItineraryInitial', () {
      expect(cubit.state, equals(ItineraryInitial()));
    });

    test('generateItinerary emits Loaded state', () async {
      final trip = Trip(
        id: '1',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 3), // 3 days
      );

      final places = List.generate(
        9,
        (i) => Place(
          id: 'p$i',
          name: 'Place $i',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Nature',
        ),
      );

      await cubit.generateItinerary(trip, places);

      expect(cubit.state, isA<ItineraryLoaded>());
      final loadedState = cubit.state as ItineraryLoaded;
      expect(loadedState.itinerary.days.length, 3);
    });

    test('modifyItinerary "two days" reduces days to 2', () async {
      final trip = Trip(
        id: '1',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 4), // 4 days
      );

      final places = List.generate(
        12,
        (i) => Place(
          id: 'p$i',
          name: 'Place $i',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Nature',
        ),
      );

      await cubit.generateItinerary(trip, places);

      expect((cubit.state as ItineraryLoaded).itinerary.days.length, 4);

      await cubit.modifyItinerary("I only have two days now");

      expect(cubit.state, isA<ItineraryLoaded>());
      expect((cubit.state as ItineraryLoaded).itinerary.days.length, 2);
    });

    test('modifyItinerary "remove museum" removes museum places', () async {
      final trip = Trip(
        id: '1',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 1), // 1 day
      );
      final places = [
        Place(
          id: 'p1',
          name: 'Museum of Art',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Culture',
          isOutdoor: false,
          tags: const ['Museum'],
        ),
        Place(
          id: 'p2',
          name: 'Park',
          description: '',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          category: 'Nature',
          isOutdoor: true,
        ),
      ];
      await cubit.generateItinerary(trip, places);

      expect(
        (cubit.state as ItineraryLoaded).itinerary.days.first.items.length,
        3,
      );

      await cubit.modifyItinerary("remove museum");

      final state = cubit.state as ItineraryLoaded;
      expect(state.itinerary.days.first.items.length, 2);
      expect(
        state.itinerary.days.first.items.any((i) => i.place.name == 'Park'),
        true,
      );
    });
  });
}
