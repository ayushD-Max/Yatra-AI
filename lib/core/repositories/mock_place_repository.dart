import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/place.dart';
import '../models/destination.dart';
import '../models/location_model.dart';
import 'place_repository.dart';

class MockPlaceRepository implements PlaceRepository {
  final List<Destination> _mockDestinations = [
    const Destination(
      id: 'pune',
      name: 'Pune',
      country: 'India',
      region: 'Maharashtra',
      latitude: 18.5204,
      longitude: 73.8567,
      imageUrl:
          'https://images.unsplash.com/photo-1552820728-8b83bb6b773f?q=80&w=1000&auto=format&fit=crop',
      description:
          'The Oxford of the East, known for its rich history and vibrant culture.',
    ),
    const Destination(
      id: 'mumbai',
      name: 'Mumbai',
      country: 'India',
      region: 'Maharashtra',
      latitude: 19.0760,
      longitude: 72.8777,
      imageUrl:
          'https://images.unsplash.com/photo-1529253355953-2947137f6d2e?q=80&w=1000&auto=format&fit=crop',
      description: 'The City of Dreams, India\'s financial powerhouse.',
    ),
    const Destination(
      id: 'goa',
      name: 'Goa',
      country: 'India',
      region: 'Goa',
      latitude: 15.2993,
      longitude: 74.1240,
      imageUrl:
          'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?q=80&w=1000&auto=format&fit=crop',
      description:
          'Famous for its beaches, nightlife, and Portuguese heritage.',
    ),
    const Destination(
      id: 'jaipur',
      name: 'Jaipur',
      country: 'India',
      region: 'Rajasthan',
      latitude: 26.9124,
      longitude: 75.7873,
      imageUrl:
          'https://images.unsplash.com/photo-1477587458883-47145ed94245?q=80&w=1000&auto=format&fit=crop',
      description: 'The Pink City, known for its royal palaces and forts.',
    ),
    const Destination(
      id: 'delhi',
      name: 'Delhi',
      country: 'India',
      region: 'Delhi',
      latitude: 28.7041,
      longitude: 77.1025,
      imageUrl:
          'https://images.unsplash.com/photo-1587474260584-136574528ed5?q=80&w=1000&auto=format&fit=crop',
      description:
          'India\'s capital territory, offering a massive metropolitan mix of history and modernity.',
    ),
    const Destination(
      id: 'agra',
      name: 'Agra',
      country: 'India',
      region: 'Uttar Pradesh',
      latitude: 27.1767,
      longitude: 78.0081,
      imageUrl:
          'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?q=80&w=1000&auto=format&fit=crop',
      description:
          'Home to the iconic Taj Mahal, a mausoleum built for the Mughal ruler Shah Jahan\'s wife.',
    ),
    const Destination(
      id: 'varanasi',
      name: 'Varanasi',
      country: 'India',
      region: 'Uttar Pradesh',
      latitude: 25.3176,
      longitude: 82.9739,
      imageUrl:
          'https://images.unsplash.com/photo-1561361513-2d000a50f0dc?q=80&w=1000&auto=format&fit=crop',
      description:
          'A city on the banks of the Ganges in Uttar Pradesh, a major religious hub in India.',
    ),
    const Destination(
      id: 'bengaluru',
      name: 'Bengaluru',
      country: 'India',
      region: 'Karnataka',
      latitude: 12.9716,
      longitude: 77.5946,
      imageUrl:
          'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?q=80&w=1000&auto=format&fit=crop',
      description:
          'The Silicon Valley of India, known for its parks and nightlife.',
    ),
    const Destination(
      id: 'chennai',
      name: 'Chennai',
      country: 'India',
      region: 'Tamil Nadu',
      latitude: 13.0827,
      longitude: 80.2707,
      imageUrl:
          'https://images.unsplash.com/photo-1582510003544-4d00b7f7415e?q=80&w=1000&auto=format&fit=crop',
      description:
          'Gateway to South India, famous for its temples and Marina Beach.',
    ),
    const Destination(
      id: 'hyderabad',
      name: 'Hyderabad',
      country: 'India',
      region: 'Telangana',
      latitude: 17.3850,
      longitude: 78.4867,
      imageUrl:
          'https://images.unsplash.com/photo-1605705663738-9580cb421421?q=80&w=1000&auto=format&fit=crop',
      description:
          'City of Pearls, famous for Charminar and rich culinary heritage.',
    ),
    const Destination(
      id: 'kolkata',
      name: 'Kolkata',
      country: 'India',
      region: 'West Bengal',
      latitude: 22.5726,
      longitude: 88.3639,
      imageUrl:
          'https://images.unsplash.com/photo-1558431382-27e303142255?q=80&w=1000&auto=format&fit=crop',
      description:
          'The Cultural Capital of India, known for its colonial architecture and arts.',
    ),
    const Destination(
      id: 'kochi',
      name: 'Kochi',
      country: 'India',
      region: 'Kerala',
      latitude: 9.9312,
      longitude: 76.2673,
      imageUrl:
          'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?q=80&w=1000&auto=format&fit=crop',
      description:
          'Queen of the Arabian Sea, famous for Chinese fishing nets and spice markets.',
    ),
    const Destination(
      id: 'udaipur',
      name: 'Udaipur',
      country: 'India',
      region: 'Rajasthan',
      latitude: 24.5854,
      longitude: 73.7125,
      imageUrl:
          'https://images.unsplash.com/photo-1615836245337-f8b9b113f2cb?q=80&w=1000&auto=format&fit=crop',
      description: 'City of Lakes, often called the Venice of the East.',
    ),
    const Destination(
      id: 'rishikesh',
      name: 'Rishikesh',
      country: 'India',
      region: 'Uttarakhand',
      latitude: 30.0869,
      longitude: 78.2676,
      imageUrl:
          'https://images.unsplash.com/photo-1601614742468-b349d9af7d78?q=80&w=1000&auto=format&fit=crop',
      description:
          'Yoga Capital of the World, situated beside the Ganges River.',
    ),
    const Destination(
      id: 'manali',
      name: 'Manali',
      country: 'India',
      region: 'Himachal Pradesh',
      latitude: 32.2396,
      longitude: 77.1887,
      imageUrl:
          'https://images.unsplash.com/photo-1605649487212-47bdab064df7?q=80&w=1000&auto=format&fit=crop',
      description:
          'A high-altitude Himalayan resort town known for its cool climate and snow.',
    ),
    const Destination(
      id: 'amritsar',
      name: 'Amritsar',
      country: 'India',
      region: 'Punjab',
      latitude: 31.6340,
      longitude: 74.8723,
      imageUrl:
          'https://images.unsplash.com/photo-1589311497259-7b3b4293f0b4?q=80&w=1000&auto=format&fit=crop',
      description:
          'Home to the spectacular Golden Temple, the holiest Gurdwara of Sikhism.',
    ),
    const Destination(
      id: 'mysore',
      name: 'Mysore',
      country: 'India',
      region: 'Karnataka',
      latitude: 12.2958,
      longitude: 76.6394,
      imageUrl:
          'https://images.unsplash.com/photo-1600096238386-8a5627cff818?q=80&w=1000&auto=format&fit=crop',
      description:
          'The City of Palaces, famous for its heritage structures and Dasara festival.',
    ),
    const Destination(
      id: 'shimla',
      name: 'Shimla',
      country: 'India',
      region: 'Himachal Pradesh',
      latitude: 31.1048,
      longitude: 77.1734,
      imageUrl:
          'https://images.unsplash.com/photo-1598165502598-f544ce9ce008?q=80&w=1000&auto=format&fit=crop',
      description:
          'The capital of Himachal Pradesh, known for its colonial architecture and cool climate.',
    ),
    const Destination(
      id: 'darjeeling',
      name: 'Darjeeling',
      country: 'India',
      region: 'West Bengal',
      latitude: 27.0360,
      longitude: 88.2627,
      imageUrl:
          'https://images.unsplash.com/photo-1544253164-8e104e7b87c7?q=80&w=1000&auto=format&fit=crop',
      description:
          'Famous for its tea industry and the scenic views of Kangchenjunga.',
    ),
    const Destination(
      id: 'ooty',
      name: 'Ooty',
      country: 'India',
      region: 'Tamil Nadu',
      latitude: 11.4100,
      longitude: 76.6950,
      imageUrl:
          'https://images.unsplash.com/photo-1582298538104-e35c24eb2913?q=80&w=1000&auto=format&fit=crop',
      description:
          'Queen of the Nilgiris, a popular hill station in South India.',
    ),
    const Destination(
      id: 'munnar',
      name: 'Munnar',
      country: 'India',
      region: 'Kerala',
      latitude: 10.0889,
      longitude: 77.0595,
      imageUrl:
          'https://images.unsplash.com/photo-1579737402633-9fb458ea6198?q=80&w=1000&auto=format&fit=crop',
      description:
          'A town in the Western Ghats known for its sprawling tea estates.',
    ),
    const Destination(
      id: 'jodhpur',
      name: 'Jodhpur',
      country: 'India',
      region: 'Rajasthan',
      latitude: 26.2389,
      longitude: 73.0243,
      imageUrl:
          'https://images.unsplash.com/photo-1616422285623-14bf91295b21?q=80&w=1000&auto=format&fit=crop',
      description: 'The Blue City, known for the majestic Mehrangarh Fort.',
    ),
    const Destination(
      id: 'jaisalmer',
      name: 'Jaisalmer',
      country: 'India',
      region: 'Rajasthan',
      latitude: 26.9157,
      longitude: 70.9083,
      imageUrl:
          'https://images.unsplash.com/photo-1587595431973-160d0d94add1?q=80&w=1000&auto=format&fit=crop',
      description:
          'The Golden City, known for its yellow sandstone architecture and desert.',
    ),
    const Destination(
      id: 'ahmedabad',
      name: 'Ahmedabad',
      country: 'India',
      region: 'Gujarat',
      latitude: 23.0225,
      longitude: 72.5714,
      imageUrl:
          'https://images.unsplash.com/photo-1605705663738-9580cb421421?q=80&w=1000&auto=format&fit=crop',
      description:
          'A rapidly growing metropolis, home to the Sabarmati Ashram.',
    ),
    const Destination(
      id: 'bhopal',
      name: 'Bhopal',
      country: 'India',
      region: 'Madhya Pradesh',
      latitude: 23.2599,
      longitude: 77.4126,
      imageUrl:
          'https://images.unsplash.com/photo-1585135496660-8488e1bb425c?q=80&w=1000&auto=format&fit=crop',
      description:
          'The City of Lakes, known for its various natural and artificial lakes.',
    ),
    const Destination(
      id: 'indore',
      name: 'Indore',
      country: 'India',
      region: 'Madhya Pradesh',
      latitude: 22.7196,
      longitude: 75.8577,
      imageUrl:
          'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop',
      description: 'A cultural and educational hub in central India.',
    ),
    const Destination(
      id: 'lucknow',
      name: 'Lucknow',
      country: 'India',
      region: 'Uttar Pradesh',
      latitude: 26.8467,
      longitude: 80.9462,
      imageUrl:
          'https://images.unsplash.com/photo-1585135496660-8488e1bb425c?q=80&w=1000&auto=format&fit=crop',
      description:
          'The City of Nawabs, known for its culture, art, and cuisine.',
    ),
    const Destination(
      id: 'chandigarh',
      name: 'Chandigarh',
      country: 'India',
      region: 'Chandigarh',
      latitude: 30.7333,
      longitude: 76.7794,
      imageUrl:
          'https://images.unsplash.com/photo-1598324789736-4861f89564a0?q=80&w=1000&auto=format&fit=crop',
      description:
          'The first planned city of India, known for its urban design.',
    ),
    const Destination(
      id: 'puducherry',
      name: 'Puducherry',
      country: 'India',
      region: 'Puducherry',
      latitude: 11.9416,
      longitude: 79.8083,
      imageUrl:
          'https://images.unsplash.com/photo-1601058269781-6789f6b95dd5?q=80&w=1000&auto=format&fit=crop',
      description:
          'A French colonial settlement offering a blend of traditional Indian and French architecture.',
    ),
    const Destination(
      id: 'guwahati',
      name: 'Guwahati',
      country: 'India',
      region: 'Assam',
      latitude: 26.1445,
      longitude: 91.7362,
      imageUrl:
          'https://images.unsplash.com/photo-1566804561054-94c6ee5eb7c0?q=80&w=1000&auto=format&fit=crop',
      description:
          'The Gateway to North East India, situated on the south bank of the Brahmaputra.',
    ),
    const Destination(
      id: 'nashik',
      name: 'Nashik',
      country: 'India',
      region: 'Maharashtra',
      latitude: 20.0110,
      longitude: 73.7903,
      imageUrl:
          'https://images.unsplash.com/photo-1582298538104-e35c24eb2913?q=80&w=1000&auto=format&fit=crop',
      description:
          'An ancient holy city known for its links to the Ramayana epic and vineyards.',
    ),
    const Destination(
      id: 'nagpur',
      name: 'Nagpur',
      country: 'India',
      region: 'Maharashtra',
      latitude: 21.1458,
      longitude: 79.0882,
      imageUrl:
          'https://images.unsplash.com/photo-1629808375812-70df577960fc?q=80&w=1000&auto=format&fit=crop',
      description:
          'The Winter Capital of Maharashtra, famous for Nagpur oranges.',
    ),
    const Destination(
      id: 'lonavala',
      name: 'Lonavala',
      country: 'India',
      region: 'Maharashtra',
      latitude: 18.7515,
      longitude: 73.4042,
      imageUrl:
          'https://images.unsplash.com/photo-1560179406-1c6c60e0dcf6?q=80&w=1000&auto=format&fit=crop',
      description:
          'A popular hill station surrounded by green valleys in western India.',
    ),
    const Destination(
      id: 'mahabaleshwar',
      name: 'Mahabaleshwar',
      country: 'India',
      region: 'Maharashtra',
      latitude: 17.9307,
      longitude: 73.6477,
      imageUrl:
          'https://images.unsplash.com/photo-1596423735880-5f2a689b903e?q=80&w=1000&auto=format&fit=crop',
      description:
          'A hill station in the Western Ghats known for its strawberries and viewpoints.',
    ),
    const Destination(
      id: 'alibaug',
      name: 'Alibaug',
      country: 'India',
      region: 'Maharashtra',
      latitude: 18.6416,
      longitude: 72.8722,
      imageUrl:
          'https://images.unsplash.com/photo-1598324789736-4861f89564a0?q=80&w=1000&auto=format&fit=crop',
      description:
          'A coastal town known for its beaches like Alibaug Beach and Varsoli Beach.',
    ),
    const Destination(
      id: 'aurangabad',
      name: 'Aurangabad',
      country: 'India',
      region: 'Maharashtra',
      latitude: 19.8762,
      longitude: 75.3433,
      imageUrl:
          'https://images.unsplash.com/photo-1549479320-c242ef99bfcc?q=80&w=1000&auto=format&fit=crop',
      description:
          'Tourism capital of Maharashtra, gateway to the Ajanta and Ellora caves.',
    ),
    const Destination(
      id: 'kolhapur',
      name: 'Kolhapur',
      country: 'India',
      region: 'Maharashtra',
      latitude: 16.7050,
      longitude: 74.2433,
      imageUrl:
          'https://images.unsplash.com/photo-1620612450379-38379f8c6b75?q=80&w=1000&auto=format&fit=crop',
      description:
          'An ancient city famous for the Mahalakshmi Temple and Kolhapuri chappals.',
    ),
    const Destination(
      id: 'ratnagiri',
      name: 'Ratnagiri',
      country: 'India',
      region: 'Maharashtra',
      latitude: 16.9902,
      longitude: 73.3120,
      imageUrl:
          'https://images.unsplash.com/photo-1582298538104-e35c24eb2913?q=80&w=1000&auto=format&fit=crop',
      description:
          'A port city known for Alphonso mangoes and the Ratnadurg Fort.',
    ),
    const Destination(
      id: 'matheran',
      name: 'Matheran',
      country: 'India',
      region: 'Maharashtra',
      latitude: 18.9882,
      longitude: 73.2712,
      imageUrl:
          'https://images.unsplash.com/photo-1566804561054-94c6ee5eb7c0?q=80&w=1000&auto=format&fit=crop',
      description: 'An automobile-free hill station with panoramic viewpoints.',
    ),
  ];

  // In-memory cache
  final Map<String, List<Place>> _placeCache = {};

  Future<List<Place>> _loadPlacesFor(String destinationId) async {
    if (_placeCache.containsKey(destinationId)) {
      return _placeCache[destinationId]!;
    }
    try {
      final jsonString = await rootBundle.loadString(
        'assets/mocks/$destinationId.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final places = jsonList
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
      _placeCache[destinationId] = places;
      return places;
    } catch (e) {
      print('MockPlaceRepository: Failed to load mock for $destinationId: $e');
      return [];
    }
  }

  @override
  Future<List<Destination>> getTrendingDestinations() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockDestinations;
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) {
      return await _loadPlacesFor('pune');
    }
    final lowerQuery = query.toLowerCase();

    // Load all caches to search across all destinations
    List<Place> allPlaces = [];
    for (var dest in _mockDestinations) {
      final places = await _loadPlacesFor(dest.id);

      // If the destination name itself matches the query (fuzzy match), include all its places
      // We'll do a simple substring match for the destination name too
      bool matchesDestination =
          dest.name.toLowerCase().contains(lowerQuery) ||
          lowerQuery.contains(dest.name.toLowerCase()) ||
          // Basic typo handling (e.g. chenaai -> chennai)
          (lowerQuery.length >= 4 &&
              dest.name.toLowerCase().substring(0, 3) ==
                  lowerQuery.substring(0, 3));

      if (matchesDestination) {
        allPlaces.addAll(places);
        continue;
      }

      // Otherwise, filter places inside this destination
      final matchingPlaces = places.where((place) {
        return place.name.toLowerCase().contains(lowerQuery) ||
            place.category.toLowerCase().contains(lowerQuery) ||
            place.description.toLowerCase().contains(lowerQuery) ||
            place.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();

      allPlaces.addAll(matchingPlaces);
    }

    return allPlaces.toSet().toList(); // Remove duplicates if any
  }

  @override
  Future<List<Place>> getPlacesForDestination(String destinationId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return await _loadPlacesFor(destinationId.toLowerCase());
  }

  @override
  Future<Place?> getPlaceDetails(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (var dest in _mockDestinations) {
      final places = await _loadPlacesFor(dest.id);
      try {
        return places.firstWhere((place) => place.id == placeId);
      } catch (e) {
        // Not in this destination
      }
    }
    return null;
  }

  @override
  Future<List<LocationModel>> getAutocompleteSuggestions(String query) async {
    return [];
  }

  @override
  Future<LocationModel?> getLocationDetails(String placeId) async {
    return null;
  }

  @override
  Future<LocationModel?> getLocationFromCoordinates(double lat, double lng) async {
    return null;
  }
}
