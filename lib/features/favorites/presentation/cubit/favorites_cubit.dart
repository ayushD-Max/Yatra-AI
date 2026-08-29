import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/place.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final SharedPreferences prefs;
  static const _favoritesKey = 'favorite_places';

  FavoritesCubit(this.prefs) : super(FavoritesInitial()) {
    _loadFavorites();
  }

  void _loadFavorites() {
    try {
      final String? favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson != null) {
        final List<dynamic> decoded = jsonDecode(favoritesJson);
        final List<Place> places = decoded
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(FavoritesLoaded(places));
      } else {
        emit(const FavoritesLoaded([]));
      }
    } catch (e) {
      print('Error loading favorites: $e');
      emit(const FavoritesLoaded([]));
    }
  }

  void toggleFavorite(Place place) {
    if (state is FavoritesLoaded) {
      final currentState = state as FavoritesLoaded;
      final currentList = List<Place>.from(currentState.favoritePlaces);

      // We check by ID to avoid reference issues after JSON serialization
      final existingIndex = currentList.indexWhere((p) => p.id == place.id);

      if (existingIndex >= 0) {
        currentList.removeAt(existingIndex);
      } else {
        currentList.add(place);
      }

      _saveFavorites(currentList);
      emit(FavoritesLoaded(currentList));
    }
  }

  void _saveFavorites(List<Place> places) {
    try {
      final String encoded = jsonEncode(places.map((e) => e.toJson()).toList());
      prefs.setString(_favoritesKey, encoded);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  bool isFavorite(Place place) {
    if (state is FavoritesLoaded) {
      return (state as FavoritesLoaded).favoritePlaces.any(
        (p) => p.id == place.id,
      );
    }
    return false;
  }
}
