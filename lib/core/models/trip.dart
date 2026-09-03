import 'package:equatable/equatable.dart';
import 'destination.dart';
import 'itinerary.dart';

class TripPreferences extends Equatable {
  final int? budget;
  final int? numberOfDays;
  final String travelStyle;
  final List<String> excludedCategories;
  final List<String> preferredCategories;
  final double indoorOutdoorPreference; // -1.0 (Indoor) to 1.0 (Outdoor)
  final double foodPreference; // 0.0 to 1.0
  final double culturePreference; // 0.0 to 1.0
  final double adventurePreference; // 0.0 to 1.0
  final double relaxationPreference; // 0.0 to 1.0
  final double familyPreference; // 0.0 to 1.0
  final int? availableTimeMinutes;
  final bool? includeNearbyPlaces;
  final String? startTime;

  const TripPreferences({
    this.budget,
    this.numberOfDays,
    this.travelStyle = 'Adventure',
    this.excludedCategories = const [],
    this.preferredCategories = const [],
    this.indoorOutdoorPreference = 0.0,
    this.foodPreference = 0.5,
    this.culturePreference = 0.5,
    this.adventurePreference = 0.5,
    this.relaxationPreference = 0.5,
    this.familyPreference = 0.5,
    this.availableTimeMinutes,
    this.includeNearbyPlaces,
    this.startTime,
  });

  TripPreferences copyWith({
    int? budget,
    bool clearBudget = false,
    int? numberOfDays,
    String? travelStyle,
    List<String>? excludedCategories,
    List<String>? preferredCategories,
    double? indoorOutdoorPreference,
    double? foodPreference,
    double? culturePreference,
    double? adventurePreference,
    double? relaxationPreference,
    double? familyPreference,
    int? availableTimeMinutes,
    bool? includeNearbyPlaces,
    String? startTime,
  }) {
    return TripPreferences(
      budget: clearBudget ? null : (budget ?? this.budget),
      numberOfDays: numberOfDays ?? this.numberOfDays,
      travelStyle: travelStyle ?? this.travelStyle,
      excludedCategories: excludedCategories ?? this.excludedCategories,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      indoorOutdoorPreference:
          indoorOutdoorPreference ?? this.indoorOutdoorPreference,
      foodPreference: foodPreference ?? this.foodPreference,
      culturePreference: culturePreference ?? this.culturePreference,
      adventurePreference: adventurePreference ?? this.adventurePreference,
      relaxationPreference: relaxationPreference ?? this.relaxationPreference,
      familyPreference: familyPreference ?? this.familyPreference,
      availableTimeMinutes: availableTimeMinutes ?? this.availableTimeMinutes,
      includeNearbyPlaces: includeNearbyPlaces ?? this.includeNearbyPlaces,
      startTime: startTime ?? this.startTime,
    );
  }

  factory TripPreferences.fromJson(Map<String, dynamic> json) {
    return TripPreferences(
      budget: json['budget'] as int?,
      numberOfDays: json['numberOfDays'] as int?,
      travelStyle: json['travelStyle'] as String? ?? 'Adventure',
      excludedCategories:
          (json['excludedCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferredCategories:
          (json['preferredCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      indoorOutdoorPreference:
          (json['indoorOutdoorPreference'] as num?)?.toDouble() ?? 0.0,
      foodPreference: (json['foodPreference'] as num?)?.toDouble() ?? 0.5,
      culturePreference: (json['culturePreference'] as num?)?.toDouble() ?? 0.5,
      adventurePreference:
          (json['adventurePreference'] as num?)?.toDouble() ?? 0.5,
      relaxationPreference:
          (json['relaxationPreference'] as num?)?.toDouble() ?? 0.5,
      familyPreference: (json['familyPreference'] as num?)?.toDouble() ?? 0.5,
      availableTimeMinutes: json['availableTimeMinutes'] as int?,
      includeNearbyPlaces: json['includeNearbyPlaces'] as bool?,
      startTime: json['startTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'numberOfDays': numberOfDays,
      'travelStyle': travelStyle,
      'excludedCategories': excludedCategories,
      'preferredCategories': preferredCategories,
      'indoorOutdoorPreference': indoorOutdoorPreference,
      'foodPreference': foodPreference,
      'culturePreference': culturePreference,
      'adventurePreference': adventurePreference,
      'relaxationPreference': relaxationPreference,
      'familyPreference': familyPreference,
      'availableTimeMinutes': availableTimeMinutes,
      'includeNearbyPlaces': includeNearbyPlaces,
      'startTime': startTime,
    };
  }

  @override
  List<Object?> get props => [
    budget,
    numberOfDays,
    travelStyle,
    excludedCategories,
    preferredCategories,
    indoorOutdoorPreference,
    foodPreference,
    culturePreference,
    adventurePreference,
    relaxationPreference,
    familyPreference,
    availableTimeMinutes,
    includeNearbyPlaces,
    startTime,
  ];
}

class Trip extends Equatable {
  final String id;
  final Destination? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final TripPreferences preferences;
  final List<ItineraryDay>? generatedItinerary;
  final String? anchorPlaceId;

  const Trip({
    required this.id,
    this.destination,
    this.startDate,
    this.endDate,
    this.preferences = const TripPreferences(),
    this.generatedItinerary,
    this.anchorPlaceId,
  });

  Trip copyWith({
    String? id,
    Destination? destination,
    DateTime? startDate,
    DateTime? endDate,
    TripPreferences? preferences,
    List<ItineraryDay>? generatedItinerary,
    String? anchorPlaceId,
  }) {
    return Trip(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      preferences: preferences ?? this.preferences,
      generatedItinerary: generatedItinerary ?? this.generatedItinerary,
      anchorPlaceId: anchorPlaceId ?? this.anchorPlaceId,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      destination: json['destination'] != null
          ? Destination.fromJson(json['destination'] as Map<String, dynamic>)
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      preferences: json['preferences'] != null
          ? TripPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : const TripPreferences(),
      generatedItinerary: json['generatedItinerary'] != null
          ? (json['generatedItinerary'] as List<dynamic>)
                .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      anchorPlaceId: json['anchorPlaceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination?.toJson(), // Assuming destination has toJson
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'preferences': preferences.toJson(),
      'generatedItinerary': generatedItinerary?.map((e) => e.toJson()).toList(),
      'anchorPlaceId': anchorPlaceId,
    };
  }

  int get durationInDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  @override
  List<Object?> get props => [
    id,
    destination,
    startDate,
    endDate,
    preferences,
    generatedItinerary,
    anchorPlaceId,
  ];
}
