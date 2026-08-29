import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/place_repository.dart';
import 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final PlaceRepository repository;

  ExploreCubit(this.repository) : super(ExploreInitial());

  Future<void> searchPlaces(String query, {String? initialCategory}) async {
    try {
      emit(ExploreLoading());
      final places = await repository.searchPlaces(query);

      if (places.isEmpty) {
        emit(
          ExploreLoaded(
            places: [],
            searchQuery: '',
            selectedCategory: initialCategory ?? 'All',
          ),
        );
      } else {
        emit(
          ExploreLoaded(
            places: places,
            searchQuery: query,
            selectedCategory: initialCategory ?? 'All',
          ),
        );
      }
    } catch (e) {
      emit(ExploreError('Failed to search places: $e'));
    }
  }

  Future<void> getPlacesForDestination(
    String destinationId, {
    String? initialCategory,
  }) async {
    try {
      emit(ExploreLoading());
      final places = await repository.getPlacesForDestination(destinationId);
      emit(
        ExploreLoaded(
          places: places,
          selectedCategory: initialCategory ?? 'All',
        ),
      );
    } catch (e) {
      emit(ExploreError('Failed to load places: $e'));
    }
  }

  void filterByCategory(String category) {
    if (state is ExploreLoaded) {
      final currentState = state as ExploreLoaded;
      // In a real app we'd filter the list or make an API call.
      // For now we just update the selected category state.
      emit(
        ExploreLoaded(
          places: currentState.places,
          selectedCategory: category,
          searchQuery: currentState.searchQuery,
        ),
      );
    }
  }
}
