import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/place_repository.dart';
import '../../../../core/models/place.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final PlaceRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> loadHomeData({String locationId = 'pune'}) async {
    try {
      emit(HomeLoading());

      final trending = await repository.getTrendingDestinations();
      // Fetch places from the active location for ai insights and local gems
      final places = await repository.getPlacesForDestination(locationId);

      final shuffled = List<Place>.from(places)..shuffle();
      final localGems = shuffled.take(10).toList();
      final aiInsights = shuffled.skip(10).take(5).toList();

      emit(
        HomeLoaded(
          trendingDestinations: trending,
          aiInsights: aiInsights,
          localGems: localGems,
        ),
      );
    } catch (e) {
      emit(HomeError('Failed to load home data: $e'));
    }
  }
}
