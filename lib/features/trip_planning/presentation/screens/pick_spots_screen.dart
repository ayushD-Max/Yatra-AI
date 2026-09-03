import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';

class PickSpotsScreen extends StatefulWidget {
  final Trip trip;
  final List<Place> candidates;

  const PickSpotsScreen({
    super.key,
    required this.trip,
    required this.candidates,
  });

  @override
  State<PickSpotsScreen> createState() => _PickSpotsScreenState();
}

class _PickSpotsScreenState extends State<PickSpotsScreen> {
  final Set<String> _selectedPlaceIds = {};
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Pre-select all by default to make it easy for the user
    for (var place in widget.candidates) {
      _selectedPlaceIds.add(place.id);
    }
  }

  Future<void> _generateFinalItinerary() async {
    setState(() => _isGenerating = true);
    final selectedPlaces = widget.candidates
        .where((p) => _selectedPlaceIds.contains(p.id))
        .toList();

    // Call the Cubit to actually build the itinerary and save it
    await context.read<ItineraryCubit>().generateItinerary(
      widget.trip,
      selectedPlaces,
    );

    if (mounted) {
      setState(() => _isGenerating = false);
      _showSuccessModal();
    }
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF007AFF), size: 80),
            const SizedBox(height: 24),
            Text('Nice work!', style: AppTextStyles.h1.copyWith(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              'Your trip to ${widget.trip.destination?.name} is ready. We\'ve mapped out the best spots for you.',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.pop(); // close modal
                  context.go('/itinerary');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'View Itinerary',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/plan_trip');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16),
            ),
          ),
        ),
        title: const Text('Pick your spots'),
        centerTitle: true,
      ),
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
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 250,
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
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    itemCount: widget.candidates.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final place = widget.candidates[index];
                      final isSelected = _selectedPlaceIds.contains(place.id);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPlaceIds.remove(place.id);
                            } else {
                              _selectedPlaceIds.add(place.id);
                            }
                          });
                        },
                        child: GlassContainer(
                          borderRadius: 20,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.5),
                          blur: 15,
                          border: Border.all(color: Colors.white, width: 1.5),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: AppNetworkImage(
                                      imageUrl: place.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        style: AppTextStyles.h3.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        place.category,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textPrimary
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            place.rating?.toStringAsFixed(1) ??
                                                '4.5',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Checkbox
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF007AFF)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF007AFF)
                                          : Colors.grey.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom Floating CTA
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_selectedPlaceIds.isEmpty || _isGenerating)
                          ? null
                          : _generateFinalItinerary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPlaceIds.isEmpty
                            ? Colors.grey.withValues(alpha: 0.3)
                            : AppColors.textPrimary,
                        foregroundColor: _selectedPlaceIds.isEmpty
                            ? Colors.grey
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Build my trip (${_selectedPlaceIds.length})',
                              style: AppTextStyles.h3.copyWith(
                                color: _selectedPlaceIds.isEmpty
                                    ? Colors.black38
                                    : Colors.white,
                              ),
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
}
