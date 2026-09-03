import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/models/place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/search_bar.dart';
import '../../../../core/cubits/location_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/location_selector_sheet.dart';
import '../cubit/home_state.dart';
import '../widgets/location_selector_sheet.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../../itinerary/presentation/cubit/itinerary_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<HomeCubit>();
    if (cubit.state is! HomeLoaded) {
      cubit.loadHomeData();
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
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              final bool isLoading =
                  state is HomeLoading || state is HomeInitial;

              if (state is HomeError) {
                return Center(
                  child: Text(state.message, style: AppTextStyles.bodyLarge),
                );
              }

              // Use mock data when loading to build the skeleton
              final localGems = isLoading
                  ? List.generate(
                      3,
                      (i) => Place(
                        id: '$i',
                        name: 'Loading Gem',
                        category: 'Category',
                        description: '',
                        imageUrl: '',
                        latitude: 0,
                        longitude: 0,
                      ),
                    )
                  : (state as HomeLoaded).localGems;

              return Skeletonizer(
                enabled: isLoading,
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.paddingOf(context).top + 16),
                    // Location Pill & Profile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BlocBuilder<LocationCubit, LocationState>(
                            builder: (context, locationState) {
                              String locationName = 'Pune';
                              if (locationState is LocationLoaded) {
                                locationName = locationState.currentLocation.name;
                              }
                              return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(
                                        top: MediaQuery.paddingOf(context).top + 40,
                                      ),
                                      child: const LocationSelectorSheet(),
                                    ),
                                  );
                                },
                                child: GlassContainer(
                                  borderRadius: 30,
                                  color: Colors.white.withValues(alpha: 0.65),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  blur: 24,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 16,
                                          color: Colors.redAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          locationName,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: AppColors.textPrimary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: GlassContainer(
                              borderRadius: 30,
                              color: Colors.white.withValues(alpha: 0.65),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              blur: 24,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.person_outline,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Header Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travel Smarter',
                            style: AppTextStyles.h1.copyWith(
                              fontWeight: FontWeight.w400,
                              fontSize: 28,
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'With Yatra AI ..',
                            style: AppTextStyles.h1.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 36,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AppSearchBar(
                        readOnly: true,
                        hintText: 'Find places...',
                        onTap: () => context.go('/explore?autofocus=true'),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Scrollable Content
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 120),
                        children: [
                          // AI Insights
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'AI Insights Today',
                              style: AppTextStyles.h2.copyWith(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildInsightCard(
                                    context,
                                    'Trending\nDestination',
                                    'assets/icon_img/3d-red-map.webp',
                                    'Must-See',
                                    isLoading,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInsightCard(
                                    context,
                                    'Weather\nFriendly',
                                    'assets/icon_img/3d-weather-icon.webp',
                                    'Weather Friendly',
                                    isLoading,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInsightCard(
                                    context,
                                    'Hidden Gem\nPlace',
                                    'assets/icon_img/hidden gem.png',
                                    'Hidden Gem',
                                    isLoading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Curated by AI Locals
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Curated by AI Locals',
                              style: AppTextStyles.h2.copyWith(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: localGems.length,
                              itemBuilder: (context, index) {
                                // Alternate colors for local gems
                                final colors = [
                                  const Color(0xFFC7F0F9), // Light cyan
                                  const Color(0xFFFFDAB9), // Peach
                                  const Color(0xFFE6E6FA), // Lavender
                                ];
                                return _buildLocalGemCard(
                                  context,
                                  localGems[index],
                                  colors[index % colors.length],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 40),

                          // My Trips Section (Moved Below)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('My Trips', style: AppTextStyles.h2.copyWith(fontSize: 20)),
                                GestureDetector(
                                  onTap: () => context.push('/plan_trip'),
                                  child: const Icon(Icons.add_circle, color: Color(0xFF007AFF), size: 28),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<ItineraryCubit, ItineraryState>(
                            builder: (context, itineraryState) {
                              final currentTrip = context.read<ItineraryCubit>().currentTrip;
                              
                              if (currentTrip != null) {
                                return GestureDetector(
                                  onTap: () => context.push('/itinerary'),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: currentTrip.destination?.imageUrl != null && currentTrip.destination!.imageUrl.isNotEmpty
                                                ? Image.network(currentTrip.destination!.imageUrl, fit: BoxFit.cover)
                                                : Container(color: const Color(0xFF007AFF)),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(24),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.3),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '${currentTrip.durationInDays} Days',
                                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                currentTrip.destination?.name ?? 'Trip',
                                                style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 24),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return GestureDetector(
                                  onTap: () => context.push('/plan_trip'),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3), style: BorderStyle.none, width: 2),
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          const Icon(Icons.flight_takeoff, color: Color(0xFF007AFF), size: 40),
                                          const SizedBox(height: 12),
                                          Text('Plan your next adventure', style: AppTextStyles.h3),
                                          Text('Tap here to create a new trip', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 40),

                          // Social Import Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GlassContainer(
                              borderRadius: 24,
                              color: Colors.white.withValues(alpha: 0.7),
                              border: Border.all(color: Colors.white, width: 1.5),
                              blur: 20,
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.share, color: Color(0xFF007AFF)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Save places you see', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Import from TikTok, Reels, or YouTube',
                                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const AppBottomNavigation(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String imagePath,
    String category,
    bool isLoading,
  ) {
    return GestureDetector(
      onTap: () {
        if (!isLoading) {
          context.go('/explore?category=$category');
        }
      },
      child: GlassContainer(
        borderRadius: 24,
        color: Colors.white.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white, width: 1.5),
        blur: 30,
        child: Container(
          height: 120,
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Transform.scale(
                  scale: 1.2,
                  child: isLoading
                      ? const Skeleton.replace(
                          child: Icon(Icons.image, size: 40),
                        )
                      : Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalGemCard(BuildContext context, Place place, Color bgColor) {
    final bool isRealPlace =
        place.id != '0' && place.id != '1' && place.id != '2';

    return GestureDetector(
      onTap: () {
        if (isRealPlace) {
          context.push('/place/${place.id}', extra: place);
        }
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image
            if (isRealPlace && place.imageUrl.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    place.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
            // Gradient Overlay for text legibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isRealPlace ? 0.75 : 0.2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    place.name,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 18,
                      color: isRealPlace ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.category,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isRealPlace
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textPrimary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
