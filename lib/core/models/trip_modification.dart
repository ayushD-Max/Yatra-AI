import 'package:equatable/equatable.dart';

class TripModification extends Equatable {
  final List<String>? preferredCategories;
  final List<String>? excludedCategories;
  final String? travelStyle;
  final String? budgetDirection; // 'increase' or 'decrease'
  final int? budget;
  final int? duration;
  final double? indoorOutdoorPreference; // -1.0 to 1.0
  final List<String>? addSpecificPlaces; // Place names from natural language
  final List<String>? removeSpecificPlaces; // Place names from natural language
  final String? aiExplanation; // Conversational response explaining change or answering questions

  const TripModification({
    this.preferredCategories,
    this.excludedCategories,
    this.travelStyle,
    this.budgetDirection,
    this.budget,
    this.duration,
    this.indoorOutdoorPreference,
    this.addSpecificPlaces,
    this.removeSpecificPlaces,
    this.aiExplanation,
  });

  @override
  List<Object?> get props => [
    preferredCategories,
    excludedCategories,
    travelStyle,
    budgetDirection,
    budget,
    duration,
    indoorOutdoorPreference,
    addSpecificPlaces,
    removeSpecificPlaces,
    aiExplanation,
  ];
}
