import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/repositories/user_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository userRepository;

  ProfileCubit(this.userRepository) : super(ProfileInitial()) {
    loadProfile();
  }

  void loadProfile() {
    final profile = userRepository.getUserProfile();
    _emitLoadedState(profile);
  }

  void _emitLoadedState(UserProfile profile) {
    emit(
      ProfileLoaded(
        profile: profile,
        tripsCount: userRepository.getTripsCount(),
        savedCount: userRepository.getSavedCount(),
        reviewsCount: 0,
      ),
    );
  }

  Future<void> updateProfile({String? name, String? username}) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        name: name,
        username: username,
      );
      await userRepository.saveUserProfile(updatedProfile);
      _emitLoadedState(updatedProfile);
    }
  }

  Future<void> pickProfileImage() async {
    if (state is! ProfileLoaded) return;

    final currentProfile = (state as ProfileLoaded).profile;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String uniqueId = const Uuid().v4();
      final String extension = image.name.split('.').last;
      final String newPath = '${directory.path}/profile_$uniqueId.$extension';

      // Save new image
      await File(image.path).copy(newPath);

      // Clean up old image if it exists
      if (currentProfile.profileImagePath != null) {
        final oldFile = File(currentProfile.profileImagePath!);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (e) {
            print('Error deleting old profile image: $e');
          }
        }
      }

      final updatedProfile = currentProfile.copyWith(profileImagePath: newPath);
      await userRepository.saveUserProfile(updatedProfile);
      _emitLoadedState(updatedProfile);
    }
  }
}
