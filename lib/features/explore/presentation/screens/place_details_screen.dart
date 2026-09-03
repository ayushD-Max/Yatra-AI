import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Full Screen Image
          AppNetworkImage(
            imageUrl: place.imageUrl,
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
          // Gradient overlays to make text readable
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.6, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.4), // Top bar shadow
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                  AppColors.primary.withValues(alpha: 0.95), // Bottom very dark
                ],
              ),
            ),
          ),

          // Header Actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: 30,
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'Place Overview',
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, favoritesState) {
                      final isFav = context.read<FavoritesCubit>().isFavorite(
                        place,
                      );
                      return GestureDetector(
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black.withValues(alpha: 0.1),
                            transitionDuration: const Duration(
                              milliseconds: 200,
                            ),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return SafeArea(
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 60,
                                      right: 24,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: GlassContainer(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        borderRadius: 20,
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        blur: 15,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 1.5,
                                        ),
                                        child: IntrinsicWidth(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildMenuItem(
                                                icon: isFav
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                label: isFav
                                                    ? 'Remove Favorite'
                                                    : 'Add to Favorites',
                                                iconColor: isFav
                                                    ? AppColors.error
                                                    : Colors.white,
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  context
                                                      .read<FavoritesCubit>()
                                                      .toggleFavorite(place);
                                                },
                                              ),
                                              _buildMenuItem(
                                                icon: Icons.map_outlined,
                                                label: 'Open in Maps',
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  final encodedName =
                                                      Uri.encodeComponent(
                                                        place.name,
                                                      );
                                                  final uri = Uri.parse(
                                                    'https://www.google.com/maps/search/?api=1&query=$encodedName',
                                                  );
                                                  try {
                                                    await launchUrl(
                                                      uri,
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Could not open maps',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                              _buildMenuItem(
                                                icon: Icons.share_outlined,
                                                label: 'Share Place',
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  final encodedName =
                                                      Uri.encodeComponent(
                                                        place.name,
                                                      );
                                                  final shareText =
                                                      'Check out ${place.name} in Pune!\n\n${place.description}\n\n📍 https://www.google.com/maps/search/?api=1&query=$encodedName';
                                                  await Share.share(
                                                    shareText,
                                                    subject:
                                                        'Explore ${place.name} with YatraAI',
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: 30,
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        place.description.isNotEmpty
                            ? place.description
                            : 'Absolutely breathtaking views! The hike was challenging but rewarding. Highly recommend visiting during the autumn for the vibrant foliage...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Bottom Glass Panel
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: BackdropFilter(
                    filter: _getBlur(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reviews',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    place.rating.toStringAsFixed(1),
                                    style: AppTextStyles.h2.copyWith(
                                      color: Colors.white,
                                      fontSize: 32,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  Icon(
                                    Icons.star_half,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 14,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1.2k reviews',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // Action to Add to trip / continue
                              context.go('/plan_trip', extra: place);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'CONTINUE',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_outward,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Workaround for backdrop filter
  dynamic _getBlur() {
    return ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0);
  }
}
