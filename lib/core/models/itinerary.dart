import 'package:equatable/equatable.dart';
import 'place.dart';

class ItineraryItem extends Equatable {
  final String id;
  final Place place;
  final DateTime? startTime;
  final DateTime? endTime;
  final String notes;

  const ItineraryItem({
    this.id = '',
    required this.place,
    this.startTime,
    this.endTime,
    this.notes = '',
  });

  ItineraryItem copyWith({
    String? id,
    Place? place,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      place: place ?? this.place,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String? ?? '',
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place': place.toJson(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, place, startTime, endTime, notes];
}

class ItineraryDay extends Equatable {
  final DateTime date;
  final int dayNumber;
  final List<ItineraryItem> items;

  const ItineraryDay({
    required this.date,
    required this.dayNumber,
    required this.items,
  });

  ItineraryDay copyWith({
    DateTime? date,
    int? dayNumber,
    List<ItineraryItem>? items,
  }) {
    return ItineraryDay(
      date: date ?? this.date,
      dayNumber: dayNumber ?? this.dayNumber,
      items: items ?? this.items,
    );
  }

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      date: DateTime.parse(json['date'] as String),
      dayNumber: json['dayNumber'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayNumber': dayNumber,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [date, dayNumber, items];
}

class Itinerary extends Equatable {
  final String tripId;
  final List<ItineraryDay> days;

  const Itinerary({required this.tripId, required this.days});

  Itinerary copyWith({String? tripId, List<ItineraryDay>? days}) {
    return Itinerary(tripId: tripId ?? this.tripId, days: days ?? this.days);
  }

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      tripId: json['tripId'] as String,
      days: (json['days'] as List<dynamic>)
          .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'tripId': tripId, 'days': days.map((e) => e.toJson()).toList()};
  }

  @override
  List<Object?> get props => [tripId, days];
}
