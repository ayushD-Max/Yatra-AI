class LocationModel {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;

  LocationModel({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      placeId: json['placeId'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
