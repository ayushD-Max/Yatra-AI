import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/place.dart';
import '../models/destination.dart';
import '../models/location_model.dart';
import 'place_repository.dart';
import 'mock_place_repository.dart'; // To fallback or use static destinations

class AiPlaceRepository implements PlaceRepository {
  final Map<String, List<Place>> _cache = {};

  final List<Destination> _staticDestinations = const [
    Destination(
      id: 'mumbai',
      name: 'Mumbai',
      country: 'India',
      region: 'Maharashtra',
      latitude: 19.0760,
      longitude: 72.8777,
      imageUrl: 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?q=80&w=1000&auto=format&fit=crop',
      description: 'The city of dreams, home to Bollywood and historical architecture.',
    ),
    Destination(
      id: 'goa',
      name: 'Goa',
      country: 'India',
      region: 'Goa',
      latitude: 15.2993,
      longitude: 74.1240,
      imageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?q=80&w=1000&auto=format&fit=crop',
      description: 'Famous for its pristine beaches, vibrant nightlife, and Portuguese heritage.',
    ),
    Destination(
      id: 'pune',
      name: 'Pune',
      country: 'India',
      region: 'Maharashtra',
      latitude: 18.5204,
      longitude: 73.8567,
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1000&auto=format&fit=crop',
      description: 'The cultural capital of Maharashtra with a rich historical legacy.',
    ),
    Destination(
      id: 'jaipur',
      name: 'Jaipur',
      country: 'India',
      region: 'Rajasthan',
      latitude: 26.9124,
      longitude: 75.7873,
      imageUrl: 'https://images.unsplash.com/photo-1477587458883-47145ed94245?q=80&w=1000&auto=format&fit=crop',
      description: 'The Pink City, known for its royal palaces and majestic forts.',
    ),
  ];

  @override
  Future<List<Destination>> getTrendingDestinations() async {
    return _staticDestinations;
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) return getPlacesForDestination('pune');
    
    // Pass the raw query directly to Google Places API!
    // This allows the user to search for Delhi, Bangalore, or anywhere else.
    return getPlacesForDestination(query);
  }

  @override
  Future<Place?> getPlaceDetails(String placeId) async {
    for (var places in _cache.values) {
      try {
        return places.firstWhere((p) => p.id == placeId);
      } catch (e) {
        // continue searching
      }
    }
    return null;
  }

  String _mapGoogleTypesToYatraCategory(List<dynamic> types) {
    if (types.isEmpty) return 'Must-See';

    final typesStr = types.join(',').toLowerCase();

    if (typesStr.contains('restaurant') || typesStr.contains('food') || typesStr.contains('bakery')) return 'Food';
    if (typesStr.contains('cafe') || typesStr.contains('coffee')) return 'Cafe';
    if (typesStr.contains('park') || typesStr.contains('beach') || typesStr.contains('lake') || typesStr.contains('natural_feature') || typesStr.contains('campground')) return 'Nature';
    if (typesStr.contains('museum') || typesStr.contains('hindu_temple') || typesStr.contains('place_of_worship') || typesStr.contains('historical_landmark') || typesStr.contains('monument')) return 'Historical';
    if (typesStr.contains('shopping_mall') || typesStr.contains('market') || typesStr.contains('store')) return 'Shopping';
    if (typesStr.contains('amusement_park') || typesStr.contains('zoo') || typesStr.contains('stadium')) return 'Adventure';

    return 'Must-See';
  }

  @override
  Future<List<Place>> getPlacesForDestination(String destinationId) async {
    if (_cache.containsKey(destinationId)) {
      return _cache[destinationId]!;
    }
    
    // Attempt Google Places API (New) First
    if (ApiConstants.hasGoogleMapsKey) {
      try {
        final url = 'https://places.googleapis.com/v1/places:searchText';
        
        // We run 4 parallel queries to ensure EVERY category (Nature, Food, Hidden Gem, Must-See) is heavily populated!
        final queries = [
          "top tourist attractions and historical places in $destinationId",
          "beautiful parks, lakes, and nature spots in $destinationId",
          "hidden gem and offbeat tourist places in $destinationId",
          "best cafes and restaurants in $destinationId",
        ];

        final futures = queries.map((query) => http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': ApiConstants.googleMapsApiKey,
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.photos',
          },
          body: jsonEncode({
            "textQuery": query,
            "pageSize": 20, // Request up to 20 places per query (80 total)
          }),
        ));

        final responses = await Future.wait(futures);
        
        final Map<String, Place> uniquePlaces = {}; // Use Map to prevent duplicates

        for (var response in responses) {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List<dynamic> results = data['places'] ?? [];
            
            for (var item in results) {
              final id = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
              
              if (uniquePlaces.containsKey(id)) continue; // skip duplicates

              final name = item['displayName']?['text'] ?? 'Unknown Place';
              final desc = item['formattedAddress'] ?? 'A fascinating place to visit in $destinationId.';
              
              double lat = 0.0;
              double lng = 0.0;
              if (item['location'] != null) {
                lat = (item['location']['latitude'] ?? 0.0).toDouble();
                lng = (item['location']['longitude'] ?? 0.0).toDouble();
              }

              final rating = (item['rating'] ?? 4.0).toDouble();
              final reviewCount = (item['userRatingCount'] ?? 0).toInt();
              
              // Photo Availability & Fallback
              String imageUrl = 'https://picsum.photos/seed/$id/600/400';
              final List<dynamic>? photos = item['photos'];
              if (photos != null && photos.isNotEmpty) {
                final photoRef = photos.first['name']; // 'places/ChIJ.../photos/...'
                imageUrl = 'https://places.googleapis.com/v1/$photoRef/media?maxHeightPx=400&maxWidthPx=600&key=${ApiConstants.googleMapsApiKey}';
              }

              // Robust Category Mapping
              final List<dynamic> types = item['types'] ?? [];
              final category = _mapGoogleTypesToYatraCategory(types);

              // Hidden Gems (Yatra Logic)
              // A place is a hidden gem if it has an excellent rating but relatively few reviews
              final List<String> tags = [category.toLowerCase(), 'trending'];
              if (rating >= 4.5 && reviewCount < 1000 && reviewCount > 10) {
                tags.add('hidden gem');
              }
              if (category == 'Nature') {
                tags.add('weather friendly');
              }

              uniquePlaces[id] = Place(
                id: id,
                name: name,
                description: desc,
                latitude: lat,
                longitude: lng,
                imageUrl: imageUrl,
                category: category,
                tags: tags,
                rating: rating,
                source: 'Google Places',
                isOutdoor: category == 'Nature' || category == 'Historical',
                estimatedVisitDuration: category == 'Food' || category == 'Cafe' ? 60 : 120,
              );
            }
          } else {
            print('AiPlaceRepository: Google Places API Error: ${response.statusCode} - ${response.body}');
          }
        }

        if (uniquePlaces.isNotEmpty) {
          final placesList = uniquePlaces.values.toList();
          _cache[destinationId] = placesList;
          return placesList;
        }
      } catch (e) {
        print('AiPlaceRepository: Exception fetching from Google Places: $e');
        // Fallthrough to mock data
      }
    }

    // Resilient Fallback to JSON database if Google API fails, quota exhausted, or no key
    try {
      final jsonStr = await rootBundle.loadString('assets/mocks/indian_cities.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      // Fallback works with lowercase/capitalized keys
      final destKey = data.keys.firstWhere(
        (k) => k.toLowerCase() == destinationId.toLowerCase(),
        orElse: () => '',
      );

      if (destKey.isNotEmpty) {
        final List<dynamic> placesJson = data[destKey];
        final places = placesJson.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
        _cache[destinationId] = places;
        return places;
      }
      return [];
    } catch (e) {
      print('AiPlaceRepository: Error loading fallback data: $e');
      return [];
    }
  }
  @override
  Future<List<LocationModel>> getAutocompleteSuggestions(String query) async {
    if (!ApiConstants.hasGoogleMapsKey || query.isEmpty) return [];

    try {
      final url = 'https://places.googleapis.com/v1/places:autocomplete';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': ApiConstants.googleMapsApiKey,
        },
        body: jsonEncode({
          "input": query,
          "includedRegionCodes": ["IN"], // Restrict to India for now, optional
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];
        return suggestions.map((s) {
          final placePrediction = s['placePrediction'];
          return LocationModel(
            placeId: placePrediction['placeId'] ?? '',
            name: placePrediction['structuredFormat']?['mainText']?['text'] ?? placePrediction['text']?['text'] ?? 'Unknown',
            formattedAddress: placePrediction['structuredFormat']?['secondaryText']?['text'] ?? '',
          );
        }).toList();
      }
    } catch (e) {
      print('AiPlaceRepository: Error autocomplete: $e');
    }
    return [];
  }

  @override
  Future<LocationModel?> getLocationDetails(String placeId) async {
    if (!ApiConstants.hasGoogleMapsKey) return null;

    try {
      final url = 'https://places.googleapis.com/v1/places/$placeId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': ApiConstants.googleMapsApiKey,
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LocationModel(
          placeId: data['id'] ?? placeId,
          name: data['displayName']?['text'] ?? 'Unknown',
          formattedAddress: data['formattedAddress'] ?? '',
          latitude: (data['location']?['latitude'] as num?)?.toDouble(),
          longitude: (data['location']?['longitude'] as num?)?.toDouble(),
        );
      }
    } catch (e) {
      print('AiPlaceRepository: Error getting location details: $e');
    }
    return null;
  }

  @override
  Future<LocationModel?> getLocationFromCoordinates(double lat, double lng) async {
    if (!ApiConstants.hasGoogleMapsKey) return null;

    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${ApiConstants.googleMapsApiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        
        if (results.isNotEmpty) {
          final firstResult = results.first;
          
          // Try to find the city name from address components
          String city = 'Unknown City';
          final components = firstResult['address_components'] as List<dynamic>? ?? [];
          for (var comp in components) {
            final types = comp['types'] as List<dynamic>? ?? [];
            if (types.contains('locality')) {
              city = comp['long_name'];
              break;
            }
          }

          return LocationModel(
            placeId: firstResult['place_id'] ?? '',
            name: city,
            formattedAddress: firstResult['formatted_address'] ?? '',
            latitude: lat,
            longitude: lng,
          );
        }
      }
    } catch (e) {
      print('AiPlaceRepository: Error geocoding: $e');
    }
    return null;
  }
}

