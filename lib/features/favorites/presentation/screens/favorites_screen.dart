import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/place_card.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Favorites', style: AppTextStyles.h1),
                ),
                Expanded(
                  child: BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, state) {
                      if (state is FavoritesLoaded) {
                        if (state.favoritePlaces.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.favorite_border,
                                  size: 64,
                                  color: AppColors.divider,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No favorites yet',
                                  style: AppTextStyles.h2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Places you like will appear here.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: state.favoritePlaces.length,
                          itemBuilder: (context, index) {
                            final place = state.favoritePlaces[index];
                            return PlaceCard(
                              place: place,
                              isFavorite: true,
                              onTap: () => context.go(
                                '/place/${place.id}',
                                extra: place,
                              ),
                              onFavoriteToggle: () {
                                context.read<FavoritesCubit>().toggleFavorite(
                                  place,
                                );
                              },
                            );
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavigation(currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}
