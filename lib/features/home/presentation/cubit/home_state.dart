import 'package:equatable/equatable.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/models/place.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Destination> trendingDestinations;
  final List<Place> aiInsights;
  final List<Place> localGems;

  const HomeLoaded({
    required this.trendingDestinations,
    required this.aiInsights,
    required this.localGems,
  });

  @override
  List<Object?> get props => [trendingDestinations, aiInsights, localGems];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
