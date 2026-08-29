import 'package:equatable/equatable.dart';

class Place extends Equatable {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final double rating;
  final String source; // e.g. "OpenTripMap", "Mock"
  final bool isOutdoor;
  final int estimatedVisitDuration; // in minutes

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.category,
    this.tags = const [],
    this.rating = 0.0,
    this.source = 'Mock',
    this.isOutdoor = true,
    this.estimatedVisitDuration = 60,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    latitude,
    longitude,
    imageUrl,
    category,
    tags,
    rating,
    source,
    isOutdoor,
    estimatedVisitDuration,
  ];

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'Mock',
      isOutdoor: json['isOutdoor'] as bool? ?? true,
      estimatedVisitDuration: json['estimatedVisitDuration'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'rating': rating,
      'source': source,
      'isOutdoor': isOutdoor,
      'estimatedVisitDuration': estimatedVisitDuration,
    };
  }
}
