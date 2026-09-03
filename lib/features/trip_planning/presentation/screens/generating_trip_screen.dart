import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/repositories/place_repository.dart';

class GeneratingTripScreen extends StatefulWidget {
  final Trip trip;
  final Place anchorPlace;

  const GeneratingTripScreen({
    super.key,
    required this.trip,
    required this.anchorPlace,
  });

  @override
  State<GeneratingTripScreen> createState() => _GeneratingTripScreenState();
}

class _GeneratingTripScreenState extends State<GeneratingTripScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchSpots();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchSpots() async {
    try {
      // Simulate slight delay for the UI to show off the loader
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final repo = context.read<PlaceRepository>();
      final destId = widget.trip.destination?.id ?? 'pune';

      // Fetch places
      List<Place> candidates = await repo.getPlacesForDestination(destId);

      if (candidates.isEmpty) {
        candidates = await repo.searchPlaces(
          widget.trip.destination?.name ?? 'Pune',
        );
      }

      // Sort by rating to show the best places first
      candidates.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      // Remove anchor place from candidates if it's there
      candidates.removeWhere((p) => p.id == widget.anchorPlace.id);

      // Limit candidates to avoid overwhelming the user (e.g. 6 spots per day, between 12 and 25 total)
      int limit = (widget.trip.durationInDays * 6).clamp(12, 25);
      if (candidates.length > limit - 1) {
        candidates = candidates.sublist(0, limit - 1);
      }

      // Add anchor place at the very top as the first priority
      candidates.insert(0, widget.anchorPlace);

      // Navigate to Pick Spots screen with candidates
      if (mounted) {
        context.pushReplacement(
          '/pick_spots',
          extra: {'trip': widget.trip, 'candidates': candidates},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load places: $e')));
        context.pop();
      }
    }
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
            top: 100,
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _controller,
                  child: const Icon(
                    Icons.blur_on,
                    size: 80,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Building your ${widget.trip.destination?.name ?? 'Trip'}...',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'We are finding the best spots based on your vibe.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
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
