import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/repositories/mock_place_repository.dart';
import 'core/repositories/place_repository.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
// API Constants are handled internally by services now
import 'features/explore/presentation/cubit/explore_cubit.dart';
import 'features/trip_planning/presentation/cubit/trip_planning_cubit.dart';
import 'features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'features/favorites/presentation/cubit/favorites_cubit.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'core/repositories/user_repository.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  // Use strictly local mock data for the assignment
  final placeRepository = MockPlaceRepository();
  final userRepository = UserRepository(prefs);
  final geminiService = GeminiService();

  runApp(
    YatraApp(
      prefs: prefs,
      placeRepository: placeRepository,
      userRepository: userRepository,
      geminiService: geminiService,
    ),
  );
}

class YatraApp extends StatelessWidget {
  final SharedPreferences prefs;
  final PlaceRepository placeRepository;
  final UserRepository userRepository;
  final GeminiService geminiService;

  const YatraApp({
    super.key,
    required this.prefs,
    required this.placeRepository,
    required this.userRepository,
    required this.geminiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: placeRepository),
        RepositoryProvider.value(value: userRepository),
        RepositoryProvider.value(value: geminiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => HomeCubit(placeRepository)),
          BlocProvider(create: (_) => ExploreCubit(placeRepository)),
          BlocProvider(create: (_) => TripPlanningCubit()),
          BlocProvider(
            create: (_) =>
                ItineraryCubit(placeRepository, geminiService, prefs),
          ),
          BlocProvider(create: (_) => FavoritesCubit(prefs)),
          BlocProvider(create: (_) => ProfileCubit(userRepository)),
        ],
        child: MaterialApp.router(
          title: 'Yatra AI',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          scrollBehavior: PremiumScrollBehavior(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class PremiumScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
