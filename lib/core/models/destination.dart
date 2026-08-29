import 'package:equatable/equatable.dart';

class Destination extends Equatable {
  final String id;
  final String name;
  final String country;
  final String region;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String description;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.description,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      region: json['region'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    country,
    region,
    latitude,
    longitude,
    imageUrl,
    description,
  ];
}
