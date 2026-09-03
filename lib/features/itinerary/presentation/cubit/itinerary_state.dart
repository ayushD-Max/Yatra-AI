import 'package:equatable/equatable.dart';
import '../../../../core/models/itinerary.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/place.dart';

abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

class ItineraryInitial extends ItineraryState {}

class ItineraryGenerating extends ItineraryState {}

class ItineraryPreChat extends ItineraryState {
  final Trip trip;
  final Place anchorPlace;
  final List<Map<String, String>> chatHistory;
  final bool isTyping;

  const ItineraryPreChat(
    this.trip,
    this.anchorPlace,
    this.chatHistory,
    this.isTyping,
  );

  ItineraryPreChat copyWith({
    Trip? trip,
    Place? anchorPlace,
    List<Map<String, String>>? chatHistory,
    bool? isTyping,
  }) {
    return ItineraryPreChat(
      trip ?? this.trip,
      anchorPlace ?? this.anchorPlace,
      chatHistory ?? this.chatHistory,
      isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [trip, anchorPlace, chatHistory, isTyping];
}

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
