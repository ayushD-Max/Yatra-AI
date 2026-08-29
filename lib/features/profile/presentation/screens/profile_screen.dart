import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  Color(0xFFD6EFFF), // Sky blue
                  Color(0xFFFFF7DD), // Sun yellow
                  AppColors.backgroundLight,
                  AppColors.backgroundLight,
                ],
              ),
            ),
          ),
          // Sun glow effect
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFEEAA).withValues(alpha: 0.6),
                    const Color(0xFFFFEEAA).withValues(alpha: 0.0),
                  ],
                ),
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
                final name = profile.name ?? 'Guest User';
                final username = profile.username ?? '@guest';
                final initials = name.isNotEmpty
                    ? name
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
                          'Profile',
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/edit-profile');
                          },
                          child: GlassContainer(
                            borderRadius: 30,
                            color: Colors.white.withValues(alpha: 0.65),
                            border: Border.all(color: Colors.white, width: 1.5),
                            blur: 24,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Avatar & Name
                    Center(
                      child: Column(
                        children: [
                          GlassContainer(
                            borderRadius: 100,
                            color: Colors.white.withValues(alpha: 0.5),
                            border: Border.all(color: Colors.white, width: 4),
                            blur: 24,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary,
                                backgroundImage:
                                    profile.profileImagePath != null
                                    ? FileImage(File(profile.profileImagePath!))
                                    : null,
                                child: profile.profileImagePath == null
                                    ? Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: AppTextStyles.h1.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            username,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard('${state.tripsCount}', 'Trips'),
                        _buildStatCard('${state.savedCount}', 'Saved'),
                        _buildStatCard('${state.reviewsCount}', 'Reviews'),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Settings List
                    Text(
                      'Account Settings',
                      style: AppTextStyles.h2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsOption(
                      Icons.person_outline,
                      'Personal Information',
                    ),
                    _buildSettingsOption(
                      Icons.favorite_border_rounded,
                      'Travel Preferences',
                    ),
                    _buildSettingsOption(
                      Icons.notifications_none_rounded,
                      'Notifications',
                    ),
                    _buildSettingsOption(
                      Icons.payment_rounded,
                      'Payment Methods',
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Support',
                      style: AppTextStyles.h2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsOption(
                      Icons.help_outline_rounded,
                      'Help Center',
                    ),
                    _buildSettingsOption(
                      Icons.info_outline_rounded,
                      'About Yatra AI',
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    Center(
                      child: Text(
                        'Log Out',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GlassContainer(
          borderRadius: 20,
          color: Colors.white.withValues(alpha: 0.65),
          border: Border.all(color: Colors.white, width: 1.5),
          blur: 24,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Text(
                  value,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        borderRadius: 20,
        color: Colors.white.withValues(alpha: 0.4),
        border: Border.all(color: Colors.white, width: 1.0),
        blur: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppColors.textPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
