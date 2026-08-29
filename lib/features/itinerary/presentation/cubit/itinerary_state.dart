import 'package:equatable/equatable.dart';
import '../../../../core/models/itinerary.dart';

abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

class ItineraryInitial extends ItineraryState {}

class ItineraryGenerating extends ItineraryState {}

class ItineraryLoaded extends ItineraryState {
  final Itinerary itinerary;
  final String? aiExplanation;

  const ItineraryLoaded(this.itinerary, {this.aiExplanation});

  @override
  List<Object?> get props => [itinerary, aiExplanation];
}

class ItineraryError extends ItineraryState {
  final String message;
  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}
