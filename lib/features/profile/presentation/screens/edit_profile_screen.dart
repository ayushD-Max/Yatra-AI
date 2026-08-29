import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    if (state is ProfileLoaded) {
      _nameController.text = state.profile.name ?? '';
      _usernameController.text = state.profile.username ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    context.read<ProfileCubit>().updateProfile(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.2, 0.4, 1.0],
                colors: [
                  Color(0xFFD6EFFF),
                  Color(0xFFFFF7DD),
                  AppColors.backgroundLight,
                  AppColors.backgroundLight,
                ],
              ),
            ),
          ),

          SafeArea(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state is! ProfileLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = state.profile;
                final initials = profile.name?.isNotEmpty == true
                    ? profile.name!
                          .trim()
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join('')
                          .toUpperCase()
                    : 'G';

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: GlassContainer(
                            borderRadius: 30,
                            color: Colors.white.withValues(alpha: 0.65),
                            border: Border.all(color: Colors.white, width: 1.5),
                            blur: 24,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Edit Profile',
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 40), // spacer
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Avatar Edit
                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            context.read<ProfileCubit>().pickProfileImage(),
                        child: Stack(
                          children: [
                            GlassContainer(
                              borderRadius: 100,
                              color: Colors.white.withValues(alpha: 0.5),
                              border: Border.all(color: Colors.white, width: 4),
                              blur: 24,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.primary,
                                  backgroundImage:
                                      profile.profileImagePath != null
                                      ? FileImage(
                                          File(profile.profileImagePath!),
                                        )
                                      : null,
                                  child: profile.profileImagePath == null
                                      ? Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form Fields
                    _buildTextField('Full Name', _nameController),
                    const SizedBox(height: 24),
                    _buildTextField('Username', _usernameController),
                    const SizedBox(height: 40),

                    // Save Button
                    GestureDetector(
                      onTap: _saveProfile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Save Changes',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: 16,
          color: Colors.white.withValues(alpha: 0.6),
          border: Border.all(color: Colors.white, width: 1.5),
          blur: 16,
          child: TextField(
            controller: controller,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText: 'Enter your $label',
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
