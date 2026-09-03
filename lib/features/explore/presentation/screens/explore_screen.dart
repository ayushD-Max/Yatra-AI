import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/search_bar.dart';
import '../../../../core/widgets/place_card.dart';
import '../../../../core/widgets/category_chip.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/models/place.dart';
import '../../../../core/cubits/location_cubit.dart';
import '../../../../core/models/place.dart';
import '../../../../core/cubits/location_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';

class ExploreScreen extends StatefulWidget {
  final Destination? destination;
  final String? initialCategory;
  final bool autofocusSearch;

  const ExploreScreen({
    super.key,
    this.destination,
    this.initialCategory,
    this.autofocusSearch = false,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<String> categories = [
    'All',
    'Must-See',
    'Hidden Gem',
    'Food & Cafe',
    'Nature',
    'Weather Friendly',
    'Events',
  ];

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ExploreCubit>();
    if (widget.destination != null) {
      cubit.getPlacesForDestination(
        widget.destination!.id,
        initialCategory: widget.initialCategory,
      );
    } else {
      final locState = context.read<LocationCubit>().state;
      String locationName = 'pune';
      if (locState is LocationLoaded) {
        locationName = locState.currentLocation.name.toLowerCase();
      }
      cubit.getPlacesForDestination(locationName, initialCategory: widget.initialCategory);
    }
    if (widget.autofocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state is LocationLoaded && widget.destination == null) {
          context.read<ExploreCubit>().getPlacesForDestination(
            state.currentLocation.name.toLowerCase(),
            initialCategory: widget.initialCategory,
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: AppColors.backgroundLight),
            SafeArea(
              bottom: false,
              child: BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, favoritesState) {
                  return BlocBuilder<ExploreCubit, ExploreState>(
                    builder: (context, state) {
                    return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    // Search Bar
                    AppSearchBar(
                      focusNode: _searchFocusNode,
                      hintText: 'Search by vibe, place, tag..',
                      onChanged: (val) =>
                          context.read<ExploreCubit>().searchPlaces(val),
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              state is ExploreLoaded &&
                              state.selectedCategory == category;
                          return CategoryChip(
                            label: category,
                            isSelected:
                                isSelected ||
                                (state is ExploreLoaded &&
                                    state.selectedCategory == 'All' &&
                                    index == 0),
                            onTap: () {
                              context.read<ExploreCubit>().filterByCategory(
                                category,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Hero Feature (mock base camp)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Stack(
                        children: [
                          AppNetworkImage(
                            imageUrl:
                                'https://images.unsplash.com/photo-1590142588602-73354f46d6a0?q=80&w=1000&auto=format&fit=crop',
                            borderRadius: BorderRadius.circular(32),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.graphic_eq,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Find the perfect place to visit',
                                    style: AppTextStyles.h2.copyWith(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (state is ExploreLoaded &&
                        state.selectedCategory != 'All') ...[
                      _buildSectionHeader(
                        '${state.selectedCategory} Places',
                        'Clear Filter',
                        onTap: () {
                          context.read<ExploreCubit>().filterByCategory('All');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPlacesGrid(state),
                    ] else ...[
                      // Must-See Today
                      _buildSectionHeader(
                        'Must-See Today',
                        'See All',
                        onTap: () {
                          context.read<ExploreCubit>().filterByCategory(
                            'Must-See',
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI Curated Route',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPlacesList(state, forceCategory: 'Must-See'),

                      const SizedBox(height: 32),
                      // Hidden Gems Nearby
                      _buildSectionHeader(
                        'Hidden Gems Nearby',
                        'See All',
                        onTap: () {
                          context.read<ExploreCubit>().filterByCategory(
                            'Hidden Gem',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPlacesList(state, forceCategory: 'Hidden Gem'),
                    ],
                  ],
                    );
                  },
                );
              },
            ),
          ),
          const AppBottomNavigation(currentIndex: 1),
        ],
      ),
    ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h2.copyWith(fontSize: 20)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.blue[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlacesList(ExploreState state, {String? forceCategory}) {
    final bool isLoading = state is ExploreLoading || state is ExploreInitial;

    if (state is ExploreError) {
      return SizedBox(height: 220, child: Center(child: Text(state.message)));
    }

    if (state is ExploreLoaded && state.places.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No places found.')),
      );
    }

    var displayPlaces = isLoading
        ? List.generate(
            3,
            (index) => Place(
              id: '$index',
              name: 'Loading Place Name',
              category: 'Category',
              description: '',
              imageUrl: '',
              latitude: 0,
              longitude: 0,
            ),
          )
        : (state as ExploreLoaded).places;

    final selectedCategory =
        forceCategory ??
        (state is ExploreLoaded ? state.selectedCategory : 'All');
    if (state is ExploreLoaded && selectedCategory != 'All') {
      final selected = selectedCategory.toLowerCase();
      displayPlaces = displayPlaces.where((place) {
        final categoryLower = place.category.toLowerCase();
        if (selected == 'food & cafe') {
          return categoryLower.contains('food') ||
              categoryLower.contains('cafe');
        }
        return categoryLower.contains(selected) ||
            place.tags.any((tag) => tag.toLowerCase().contains(selected));
      }).toList();
    }

    return Skeletonizer(
      enabled: isLoading,
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: displayPlaces.length,
          itemBuilder: (context, index) {
            final place = displayPlaces[index];
            final isFavorite = context.read<FavoritesCubit>().isFavorite(place);
            return PlaceCard(
              place: place,
              isFavorite: isFavorite,
              onTap: () => !isLoading
                  ? context.go('/place/${place.id}', extra: place)
                  : null,
              onFavoriteToggle: () {
                context.read<FavoritesCubit>().toggleFavorite(place);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlacesGrid(ExploreState state) {
    final bool isLoading = state is ExploreLoading || state is ExploreInitial;

    if (state is ExploreError) {
      return Center(child: Text(state.message));
    }

    var displayPlaces = isLoading
        ? List.generate(
            6,
            (index) => Place(
              id: '$index',
              name: 'Loading Place',
              category: 'Category',
              description: '',
              imageUrl: '',
              latitude: 0,
              longitude: 0,
            ),
          )
        : (state as ExploreLoaded).places;

    if (state is ExploreLoaded && state.selectedCategory != 'All') {
      final selected = state.selectedCategory.toLowerCase();
      displayPlaces = displayPlaces.where((place) {
        final categoryLower = place.category.toLowerCase();
        if (selected == 'food & cafe') {
          return categoryLower.contains('food') ||
              categoryLower.contains('cafe');
        }
        return categoryLower.contains(selected) ||
            place.tags.any((tag) => tag.toLowerCase().contains(selected));
      }).toList();
    }

    if (displayPlaces.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('No places found in this category.')),
      );
    }

    return Skeletonizer(
      enabled: isLoading,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: displayPlaces.length,
        itemBuilder: (context, index) {
          final place = displayPlaces[index];
          final isFavorite = context.read<FavoritesCubit>().isFavorite(place);
          return PlaceCard(
            place: place,
            isFavorite: isFavorite,
            width: double.infinity,
            margin: EdgeInsets.zero,
            onTap: () => !isLoading
                ? context.go('/place/${place.id}', extra: place)
                : null,
            onFavoriteToggle: () {
              context.read<FavoritesCubit>().toggleFavorite(place);
            },
          );
        },
      ),
    );
  }
}
