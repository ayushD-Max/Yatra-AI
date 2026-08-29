import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/models/place.dart';
import 'trip_planning_state.dart';

class TripPlanningCubit extends Cubit<TripPlanningState> {
  TripPlanningCubit() : super(const TripPlanningForm());

  void setDestination(Destination destination) {
    if (state is TripPlanningForm) {
      emit(
        (state as TripPlanningForm).copyWith(selectedDestination: destination),
      );
    }
  }

  void setDates(DateTime start, DateTime end) {
    if (state is TripPlanningForm) {
      emit(
        (state as TripPlanningForm).copyWith(startDate: start, endDate: end),
      );
    }
  }

  void setBudget(int budget) {
    if (state is TripPlanningForm) {
      emit((state as TripPlanningForm).copyWith(budget: budget));
    }
  }

  void setTravelStyle(String style) {
    if (state is TripPlanningForm) {
      emit((state as TripPlanningForm).copyWith(travelStyle: style));
    }
  }

  void addPlace(Place place) {
    if (state is TripPlanningForm) {
      final currentState = state as TripPlanningForm;
      if (!currentState.selectedPlaces.contains(place)) {
        emit(
          currentState.copyWith(
            selectedPlaces: List.from(currentState.selectedPlaces)..add(place),
          ),
        );
      }
    }
  }

  void removePlace(Place place) {
    if (state is TripPlanningForm) {
      final currentState = state as TripPlanningForm;
      emit(
        currentState.copyWith(
          selectedPlaces: List.from(currentState.selectedPlaces)..remove(place),
        ),
      );
    }
  }
}
