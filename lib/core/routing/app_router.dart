import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/explore/presentation/screens/place_details_screen.dart';
import '../../features/trip_planning/presentation/screens/plan_trip_screen.dart';
import '../../features/itinerary/presentation/screens/itinerary_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../core/models/destination.dart';
import '../../core/models/place.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/explore',
        builder: (context, state) {
          final dest = state.extra as Destination?;
          final category = state.uri.queryParameters['category'];
          final autofocus = state.uri.queryParameters['autofocus'] == 'true';
          return ExploreScreen(
            destination: dest,
            initialCategory: category,
            autofocusSearch: autofocus,
          );
        },
      ),
      GoRoute(
        path: '/place/:id',
        builder: (context, state) {
          final place = state.extra as Place;
          return PlaceDetailsScreen(place: place);
        },
      ),
      GoRoute(
        path: '/plan_trip',
        builder: (context, state) {
          Place? place = state.extra as Place?;
          place ??= const Place(
            id: 'mock_pune',
            name: 'Pune',
            description: 'Cultural Capital of Maharashtra',
            latitude: 18.5204,
            longitude: 73.8567,
            imageUrl:
                'https://images.unsplash.com/photo-1552820728-8b83bb6b773f?q=80&w=600',
            category: 'City',
          );
          return PlanTripScreen(destinationPlace: place);
        },
      ),
      GoRoute(
        path: '/itinerary',
        builder: (context, state) => const ItineraryScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}
