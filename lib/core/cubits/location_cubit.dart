import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoaded extends LocationState {
  final LocationModel currentLocation;
  final List<LocationModel> recentLocations;

  LocationLoaded({
    required this.currentLocation,
    required this.recentLocations,
  });
}

class LocationCubit extends Cubit<LocationState> {
  static const _recentLocationsKey = 'recent_locations';
  static const _currentLocationKey = 'current_location';
  final SharedPreferences prefs;

  LocationCubit(this.prefs) : super(LocationInitial()) {
    _loadLocations();
  }

  void _loadLocations() {
    List<LocationModel> recent = [];
    final recentStrList = prefs.getStringList(_recentLocationsKey);
    if (recentStrList != null) {
      recent = recentStrList
          .map((e) => LocationModel.fromJson(jsonDecode(e)))
          .toList();
    }

    // Default to Pune if nothing is saved
    LocationModel current = LocationModel(
      placeId: 'pune_default',
      name: 'Pune',
      formattedAddress: 'Pune, Maharashtra, India',
    );

    final currentStr = prefs.getString(_currentLocationKey);
    if (currentStr != null) {
      current = LocationModel.fromJson(jsonDecode(currentStr));
    }

    emit(LocationLoaded(currentLocation: current, recentLocations: recent));
  }

  Future<void> setLocation(LocationModel location) async {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      
      // Update recent locations (keep max 3, remove duplicates)
      List<LocationModel> updatedRecent = List.from(currentState.recentLocations);
      updatedRecent.removeWhere((loc) => loc.name == location.name);
      updatedRecent.insert(0, location);
      if (updatedRecent.length > 3) {
        updatedRecent = updatedRecent.take(3).toList();
      }

      // Save to SharedPreferences
      await prefs.setString(_currentLocationKey, jsonEncode(location.toJson()));
      await prefs.setStringList(
        _recentLocationsKey, 
        updatedRecent.map((e) => jsonEncode(e.toJson())).toList()
      );

      emit(LocationLoaded(
        currentLocation: location,
        recentLocations: updatedRecent,
      ));
    }
  }
}
