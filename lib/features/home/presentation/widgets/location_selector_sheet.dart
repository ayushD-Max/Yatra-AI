import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/cubits/location_cubit.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/repositories/place_repository.dart';
import '../cubit/home_cubit.dart';

class LocationSelectorSheet extends StatefulWidget {
  const LocationSelectorSheet({super.key});

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<LocationModel> _suggestions = [];
  bool _isSearching = false;
  bool _isLocating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final repo = context.read<PlaceRepository>();
      final results = await repo.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      final repo = context.read<PlaceRepository>();
      final locationCubit = context.read<LocationCubit>();
      final homeCubit = context.read<HomeCubit>();
      final nav = Navigator.of(context);

      final location = await repo.getLocationFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (location != null) {
        locationCubit.setLocation(location);
        homeCubit.loadHomeData(locationId: location.name.toLowerCase());
        nav.pop();
      } else {
        throw Exception('Failed to resolve city name.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _onSuggestionTap(LocationModel suggestion) async {
    if (!mounted) return;
    final repo = context.read<PlaceRepository>();
    final locationCubit = context.read<LocationCubit>();
    final homeCubit = context.read<HomeCubit>();
    final nav = Navigator.of(context);

    final details = await repo.getLocationDetails(suggestion.placeId);

    final location = details ?? suggestion;
    locationCubit.setLocation(location);
    homeCubit.loadHomeData(locationId: location.name.toLowerCase());
    nav.pop();
  }

  void _selectLocation(LocationModel location) {
    context.read<LocationCubit>().setLocation(location);
    context.read<HomeCubit>().loadHomeData(
      locationId: location.name.toLowerCase(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: Colors.white.withValues(alpha: 0.75),
      blur: 20,
      borderRadius: 24,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.8),
        width: 1.5,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose destination',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text('Where do you want to explore?', style: AppTextStyles.h2),
            const SizedBox(height: 24),

            // Search Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search city or place...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_searchController.text.isNotEmpty) ...[
              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No places found.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.location_city,
                          color: AppColors.textSecondary,
                        ),
                        title: Text(
                          suggestion.name,
                          style: AppTextStyles.bodyLarge,
                        ),
                        subtitle: Text(
                          suggestion.formattedAddress,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _onSuggestionTap(suggestion),
                      );
                    },
                  ),
                ),
            ] else ...[
              // Current Location Button
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _isLocating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: AppColors.primary),
                title: Text(
                  'Use my current location',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _isLocating ? null : _useCurrentLocation,
              ),
              const Divider(height: 24),

              // Recent Destinations
              Text(
                'Recent destinations',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<LocationCubit, LocationState>(
                builder: (context, state) {
                  if (state is LocationLoaded &&
                      state.recentLocations.isNotEmpty) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.recentLocations.length,
                      itemBuilder: (context, index) {
                        final recent = state.recentLocations[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.history,
                            color: AppColors.textSecondary,
                          ),
                          title: Text(
                            recent.name,
                            style: AppTextStyles.bodyLarge,
                          ),
                          subtitle: Text(
                            recent.formattedAddress,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectLocation(recent),
                        );
                      },
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No recent destinations.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
