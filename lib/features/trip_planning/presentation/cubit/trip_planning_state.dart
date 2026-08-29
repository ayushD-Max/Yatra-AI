import 'package:equatable/equatable.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/models/place.dart';

abstract class TripPlanningState extends Equatable {
  const TripPlanningState();

  @override
  List<Object?> get props => [];
}

class TripPlanningInitial extends TripPlanningState {}

class TripPlanningForm extends TripPlanningState {
  final Destination? selectedDestination;
  final DateTime? startDate;
  final DateTime? endDate;
  final int budget;
  final String travelStyle;
  final List<Place> selectedPlaces;

  const TripPlanningForm({
    this.selectedDestination,
    this.startDate,
    this.endDate,
    this.budget = 1000,
    this.travelStyle = 'Adventure',
    this.selectedPlaces = const [],
  });

  TripPlanningForm copyWith({
    Destination? selectedDestination,
    DateTime? startDate,
    DateTime? endDate,
    int? budget,
    String? travelStyle,
    List<Place>? selectedPlaces,
  }) {
    return TripPlanningForm(
      selectedDestination: selectedDestination ?? this.selectedDestination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      travelStyle: travelStyle ?? this.travelStyle,
      selectedPlaces: selectedPlaces ?? this.selectedPlaces,
    );
  }

  @override
  List<Object?> get props => [
    selectedDestination,
    startDate,
    endDate,
    budget,
    travelStyle,
    selectedPlaces,
  ];
}
