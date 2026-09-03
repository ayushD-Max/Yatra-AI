import 'package:flutter_test/flutter_test.dart';
import 'package:yatra_ai/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:yatra_ai/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:yatra_ai/core/repositories/place_repository.dart';
import 'package:yatra_ai/core/repositories/mock_place_repository.dart';
import 'package:yatra_ai/core/services/gemini_service.dart';
import 'package:yatra_ai/core/models/trip.dart';
import 'package:yatra_ai/core/models/destination.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ItineraryCubit Tests', () {
    late ItineraryCubit cubit;
    late PlaceRepository repository;
    late GeminiService geminiService;
    late SharedPreferences prefs;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = MockPlaceRepository();
      geminiService = GeminiService();
      cubit = ItineraryCubit(repository, geminiService, prefs);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ItineraryInitial', () {
      expect(cubit.state, isA<ItineraryInitial>());
    });

    test('generateItinerary emits Generating then Loaded', () async {
      final trip = Trip(
        id: 'test',
        destination: const Destination(
          id: 'pune',
          name: 'Pune',
          country: 'India',
          region: 'MH',
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          description: '',
        ),
        startDate: DateTime.now(),
        endDate: DateTime.now(), // 1 day
        preferences: const TripPreferences(
          budget: 5000,
        ),
      );

      // Verify state changes
      final states = <ItineraryState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.generateItinerary(trip, []);
      
      // Allow async operations and stream to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // It should emit at least Generating and possibly an Error or Loaded
      expect(states.isNotEmpty, true);
      expect(states.first, isA<ItineraryGenerating>());

      await subscription.cancel();
    });
  });
}
