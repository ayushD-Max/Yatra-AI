import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/itinerary.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/models/place.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';

class StorymodeView extends StatelessWidget {
  final List<ItineraryItem> items;
  final bool isLoading;

  const StorymodeView({super.key, required this.items, this.isLoading = false});

  Future<void> _showPlaceInsights(BuildContext context, Place place) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final insights = await GeminiService().getPlaceInsights(
        place.name,
        place.category,
      );
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: GlassContainer(
            borderRadius: 32,
            padding: const EdgeInsets.all(24),
            color: Colors.white.withValues(alpha: 0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(' AI Insights', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      insights,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Awesome!'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load insights')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading && items.isEmpty) {
      return const Center(child: Text('Itinerary is empty.'));
    }

    return Skeletonizer(
      enabled: isLoading,
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 0),
            decoration: const BoxDecoration(
              // No border radius needed for full screen feel
            ),
            child: Stack(
              children: [
                isLoading
                    ? const Skeleton.replace(
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : AppNetworkImage(
                        imageUrl: item.place.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.zero,
                      ),
                // Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),

                // Text Content
                Positioned(
                  bottom: 80, // Safe padding for bottom navigation
                  left: 24,
                  right: 80,
                  top: 100, // Constrain top to prevent overflow
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // AI Voiceover UI removed
                          const SizedBox(height: 12),
                          Text(
                            item.place.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.place.name,
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 32,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.place.category} • ${item.place.tags.isNotEmpty ? item.place.tags.first : "Must See"}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.startTime?.hour ?? 9}:00 - ${item.endTime?.hour ?? 11}:00',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Chips
                          Row(
                            children: [
                              _buildTagChip('Mountain'),
                              const SizedBox(width: 8),
                              _buildTagChip('Spiritual'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Side thumbnails & Heart
                Positioned(
                  right: 16,
                  top: 100,
                  bottom: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildThumbnail(item.place.imageUrl, isLoading),
                      const SizedBox(height: 8),
                      _buildThumbnail(item.place.imageUrl, isLoading),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+10',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showPlaceInsights(context, item.place),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 30,
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<FavoritesCubit, FavoritesState>(
                        builder: (context, state) {
                          final isFavorite = context.read<FavoritesCubit>().isFavorite(item.place);
                          return GestureDetector(
                            onTap: () {
                              context.read<FavoritesCubit>().toggleFavorite(item.place);
                            },
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 30,
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildThumbnail(String url, bool isLoading) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isLoading
            ? const Skeleton.replace(child: Icon(Icons.image, size: 24))
            : AppNetworkImage(imageUrl: url),
      ),
    );
  }
}
