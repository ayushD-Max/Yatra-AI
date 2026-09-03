import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/custom_marker_helper.dart';
import '../../../../core/services/directions_service.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/models/itinerary.dart';
import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../../../../core/services/gemini_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  int _selectedDayIndex = 0;
  final Map<String, BitmapDescriptor> _customMarkers = {};
  final Map<int, List<LatLng>> _dayRoutes = {};

  Future<void> _loadRouteForDay(ItineraryDay day, int dayIndex) async {
    if (_dayRoutes.containsKey(dayIndex)) return;
    if (day.items.length < 2) return;

    final points = day.items.map((i) => LatLng(i.place.latitude, i.place.longitude)).toList();
    final origin = points.first;
    final destination = points.last;
    final waypoints = points.length > 2 ? points.sublist(1, points.length - 1) : null;

    final route = await DirectionsService.getRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );

    if (route != null && mounted) {
      setState(() {
        _dayRoutes[dayIndex] = route;
      });
    }
  }

  Future<void> _loadMarkersForDay(ItineraryDay day) async {
    for (int i = 0; i < day.items.length; i++) {
      final item = day.items[i];
      if (!_customMarkers.containsKey(item.place.id)) {
        final marker = await CustomMarkerHelper.createCustomMarker(
          imageUrl: item.place.imageUrl,
          index: i + 1,
          title: item.place.name,
        );
        if (mounted) {
          setState(() {
            _customMarkers[item.place.id] = marker;
          });
        }
      }
    }
  }
  GoogleMapController? _mapController;

  void _fitMapToDay(ItineraryDay day) {
    if (_mapController == null || day.items.isEmpty) return;

    if (day.items.length == 1) {
      final loc = LatLng(day.items.first.place.latitude, day.items.first.place.longitude);
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(loc, 14));
      return;
    }

    double minLat = day.items.first.place.latitude;
    double maxLat = minLat;
    double minLng = day.items.first.place.longitude;
    double maxLng = minLng;

    for (var item in day.items) {
      if (item.place.latitude < minLat) minLat = item.place.latitude;
      if (item.place.latitude > maxLat) maxLat = item.place.latitude;
      if (item.place.longitude < minLng) minLng = item.place.longitude;
      if (item.place.longitude > maxLng) maxLng = item.place.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60.0, // padding
      ),
    );
  }

  void _centerMapOnSpot(LatLng loc) {
    if (_mapController != null) {
      // Offset latitude slightly so the pin shows above the bottom sheet
      final offsetLoc = LatLng(loc.latitude - 0.005, loc.longitude);
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(offsetLoc, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocConsumer<ItineraryCubit, ItineraryState>(
        listener: (context, state) {
          if (state is ItineraryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ItineraryGenerating) {
            return const Center(child: CircularProgressIndicator());
          }

          List<ItineraryDay> days = [];
          if (state is ItineraryLoaded) {
            days = state.itinerary.days;
          }

          if (days.isEmpty) {
            return _buildEmptyState(context);
          }

          // Ensure selected day is within bounds
          if (_selectedDayIndex >= days.length) {
            _selectedDayIndex = 0;
          }

          final selectedDay = days[_selectedDayIndex];
          // Trigger marker load
          _loadMarkersForDay(selectedDay);
          _loadRouteForDay(selectedDay, _selectedDayIndex);

          return Stack(
            children: [
              // 1. Map Background
              _buildMapBackground(selectedDay),

              // 2. Top App Bar / Back Button Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
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
                        borderRadius: 30,
                        color: Colors.white.withValues(alpha: 0.8),
                        blur: 20,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final trip = context.read<ItineraryCubit>().currentTrip;
                        if (trip != null && trip.generatedItinerary != null) {
                          final allItems = trip.generatedItinerary!.expand((day) => day.items).toList();
                          context.push('/storymode', extra: allItems);
                        }
                      },
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        borderRadius: 24,
                        color: Colors.white.withValues(alpha: 0.8),
                        blur: 20,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_motion, size: 20, color: Color(0xFF007AFF)),
                            const SizedBox(width: 8),
                            Text('Trip Journey', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Static Bottom Sheet for Itinerary
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: GlassContainer(
                    borderRadius: 32,
                    color: Colors.white.withValues(alpha: 0.8), 
                    blur: 25,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                    child: Column(
                      children: [
                        const SizedBox(height: 16), // Top padding

                        // Header Actions (Title + Share/Delete)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${context.read<ItineraryCubit>().currentTrip?.durationInDays ?? 2}-Day Trip',
                                          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${context.read<ItineraryCubit>().currentTrip?.durationInDays ?? 2} Days • ${context.read<ItineraryCubit>().currentTrip?.generatedItinerary?.fold(0, (sum, day) => sum + day.items.length) ?? 0} Spots',
                                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              // Share Button
                              GestureDetector(
                                onTap: () => _showShareModal(context),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(10),
                                  borderRadius: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  blur: 15,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                                  child: const Icon(Icons.ios_share, size: 20, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Delete Button
                              GestureDetector(
                                onTap: () => context.go('/home'),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(10),
                                  borderRadius: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  blur: 15,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                                  child: const Icon(Icons.delete_outline, size: 20, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Day Tabs
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: days.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedDayIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDayIndex = index;
                                  });
                                  if (state is ItineraryLoaded) {
                                    _fitMapToDay(state.itinerary.days[index]);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF007AFF) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Day ${index + 1}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Itinerary List for Selected Day
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                            itemCount: selectedDay.items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final item = selectedDay.items[index];
                              return _buildItineraryItemCard(item, _selectedDayIndex, context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 4. Floating AI Chat/Modify Button
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: GestureDetector(
                  onTap: () => _showAiModifierSheet(context),
                  child: GlassContainer(
                    borderRadius: 30,
                    color: const Color(0xFF007AFF).withValues(alpha: 0.9),
                    blur: 15,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Modify with AI...',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAiModifierSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: GlassContainer(
            borderRadius: 32,
            padding: const EdgeInsets.all(24),
            color: Colors.white.withValues(alpha: 0.75),
            blur: 25,
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF007AFF)),
                    const SizedBox(width: 12),
                    Text(
                      'AI Quick Modifiers',
                      style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Instantly reshape your itinerary with these smart options.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[800]),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildAiChip(context, 'Make it more relaxed', 'assets/icon_img/relaxed_3d.jpg'),
                    _buildAiChip(context, 'More food & cafes', 'assets/icon_img/food_3d.jpg'),
                    _buildAiChip(context, 'Indoor places only', 'assets/icon_img/indoor_3d.jpg'),
                    _buildAiChip(context, 'Make it cheaper', 'assets/icon_img/cheaper_3d.jpg'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiChip(BuildContext context, String text, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.read<ItineraryCubit>().modifyItinerary(text);
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 20,
        color: Colors.white.withValues(alpha: 0.6),
        blur: 15,
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(imagePath, width: 24, height: 24, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF007AFF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground(ItineraryDay selectedDay) {
    if (selectedDay.items.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFE8F0F2),
        ),
      );
    }

    // Create markers for the selected day's places
    final Set<Marker> markers = selectedDay.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return Marker(
        markerId: MarkerId(item.place.id),
        position: LatLng(item.place.latitude, item.place.longitude),
        icon: _customMarkers[item.place.id] ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: item.place.name,
          snippet: item.place.category,
        ),
        onTap: () {
          // Phase 20: Navigate to Place Overview
          context.push('/place_overview/${item.place.id}', extra: item.place);
        },
      );
    }).toSet();

    // Create polyline connecting the spots
    final List<LatLng>? roadRoute = _dayRoutes[_selectedDayIndex];
    
    final List<LatLng> polylinePoints = roadRoute ?? selectedDay.items
        .map((item) => LatLng(item.place.latitude, item.place.longitude))
        .toList();

    final Set<Polyline> polylines = {
      if (polylinePoints.length > 1)
        Polyline(
          polylineId: const PolylineId('day_route'),
          points: polylinePoints,
          color: const Color(0xFF007AFF),
          width: 4,
          patterns: roadRoute != null ? <PatternItem>[] : [PatternItem.dash(20), PatternItem.gap(10)],
        ),
    };

    // Find the center point
    double avgLat = 0;
    double avgLng = 0;
    for (var item in selectedDay.items) {
      avgLat += item.place.latitude;
      avgLng += item.place.longitude;
    }
    avgLat /= selectedDay.items.length;
    avgLng /= selectedDay.items.length;

    final initialCameraPosition = CameraPosition(
      target: LatLng(avgLat, avgLng),
      zoom: 12.5,
    );

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      polylines: polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Small delay to ensure map is ready before fitting bounds
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _fitMapToDay(selectedDay);
          }
        });
      },
    );
  }

  Widget _buildItineraryItemCard(ItineraryItem item, int dayIndex, BuildContext context) {
    return GestureDetector(
      onTap: () {
        _centerMapOnSpot(LatLng(item.place.latitude, item.place.longitude));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Time Indicator (Optional/Mock for now if item.startTime is null)
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  item.startTime != null 
                      ? '${(item.startTime!.hour % 12 == 0 ? 12 : item.startTime!.hour % 12).toString().padLeft(2, '0')}:${item.startTime!.minute.toString().padLeft(2, '0')}'
                      : '09:00',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF007AFF)),
                ),
                Text(
                  item.startTime != null ? (item.startTime!.hour >= 12 ? 'PM' : 'AM') : 'AM',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: AppNetworkImage(imageUrl: item.place.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.place.name,
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.place.category,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${item.place.estimatedVisitDuration} min',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: () {
              context.read<ItineraryCubit>().removePlace(item.place.id, dayIndex);
            },
          ),
        ],
      ),
    ));
  }

  void _showShareModal(BuildContext context) {
    final trip = context.read<ItineraryCubit>().currentTrip;
    if (trip == null || trip.generatedItinerary == null) return;
    
    // Get up to 4 images for the collage
    final allItems = trip.generatedItinerary!.expand((day) => day.items).toList();
    final images = allItems.take(4).map((i) => i.place.imageUrl).toList();
    final GlobalKey boundaryKey = GlobalKey();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: boundaryKey,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Background Image
                          Positioned.fill(
                            child: AppNetworkImage(
                              imageUrl: trip.destination?.imageUrl ?? (images.isNotEmpty ? images.first : ''),
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          // Dark Overlay for readability
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.flight, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text('My Trip', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // 2x2 Image Grid
                              if (images.isNotEmpty)
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: List.generate(images.length, (index) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AppNetworkImage(
                                          imageUrl: images[index],
                                          width: double.infinity,
                                          height: double.infinity,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                
                              const SizedBox(height: 16),
                              
                              // Title and Subtitle
                              Text(
                                trip.destination != null 
                                  ? '${trip.durationInDays}-Day ${trip.destination!.name} Trip'
                                  : '${trip.durationInDays}-Day Trip',
                                style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                              ),
                              Text(
                                trip.destination?.name ?? 'Unknown Destination',
                                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('${trip.durationInDays} days', style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.location_on, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('${allItems.length} spots', style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  Text('Planned with ', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                                  Text('YATRA AI', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                            if (boundary != null) {
                              final image = await boundary.toImage(pixelRatio: 3.0);
                              final byteData = await image.toByteData(format: ImageByteFormat.png);
                              if (byteData != null) {
                                final pngBytes = byteData.buffer.asUint8List();
                                final directory = await getTemporaryDirectory();
                                final imagePath = '${directory.path}/shared_trip.png';
                                final file = File(imagePath);
                                await file.writeAsBytes(pngBytes);
                                await Share.shareXFiles([XFile(imagePath)], text: 'Check out my trip!');
                                if (context.mounted) Navigator.pop(context);
                              }
                            }
                          } catch (e) {
                            debugPrint('Error sharing image: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.send_outlined, size: 20),
                        label: const Text('Share Link', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No itinerary generated yet.',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }
}
