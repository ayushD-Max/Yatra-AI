import '../models/place.dart';
import '../models/destination.dart';
import '../models/location_model.dart';

abstract class PlaceRepository {
  Future<List<Destination>> getTrendingDestinations();
  Future<List<Place>> searchPlaces(String query);
  Future<List<Place>> getPlacesForDestination(String destinationId);
  Future<Place?> getPlaceDetails(String placeId);
  Future<List<LocationModel>> getAutocompleteSuggestions(String query);
  Future<LocationModel?> getLocationDetails(String placeId);
  Future<LocationModel?> getLocationFromCoordinates(double lat, double lng);
}
