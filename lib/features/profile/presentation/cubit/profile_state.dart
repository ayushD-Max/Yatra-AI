import 'package:equatable/equatable.dart';
import '../../../../core/models/user_profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final int tripsCount;
  final int savedCount;
  final int reviewsCount;

  const ProfileLoaded({
    required this.profile,
    required this.tripsCount,
    required this.savedCount,
    required this.reviewsCount,
  });

  @override
  List<Object?> get props => [profile, tripsCount, savedCount, reviewsCount];
}
