import 'package:equatable/equatable.dart';
import '../../../../core/models/place.dart';

abstract class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  final List<Place> places;
  final String selectedCategory;
  final String searchQuery;

  const ExploreLoaded({
    required this.places,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [places, selectedCategory, searchQuery];
}

class ExploreError extends ExploreState {
  final String message;
  const ExploreError(this.message);

  @override
  List<Object?> get props => [message];
}
