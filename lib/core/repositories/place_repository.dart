import '../models/place.dart';
import '../models/destination.dart';

abstract class PlaceRepository {
  Future<List<Destination>> getTrendingDestinations();
  Future<List<Place>> searchPlaces(String query);
  Future<List<Place>> getPlacesForDestination(String destinationId);
  Future<Place?> getPlaceDetails(String placeId);
}
