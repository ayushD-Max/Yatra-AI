import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/place.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../cubit/trip_planning_cubit.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../../../core/models/destination.dart' as import_destination;
import '../../../../core/widgets/app_bottom_navigation.dart';

enum DateSelectionState { start, inRange, unselected }

class PlanTripScreen extends StatefulWidget {
  final Place destinationPlace;

  const PlanTripScreen({super.key, required this.destinationPlace});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _budgetController = TextEditingController(text: '₹15,000.00');
  double _budgetSlider = 15000.0;
  String _selectedStyle = 'Adventure';
  final List<String> _styles = [
    'Adventure',
    'Solo Travel',
    'Road Trip',
    'Family Tour',
  ];

  // The vibrant blue used in the design, since AppColors.primary is dark/black
  static const Color _blueColor = Color(0xFF007AFF);

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 3));
    final placeId = widget.destinationPlace.id;
    final parts = placeId.split('_');
    String destId = 'pune';
    if (parts.length > 1) {
      destId = parts[0] == 'mock'
          ? parts[1].toLowerCase()
          : parts[0].toLowerCase();
    } else {
      destId = placeId.toLowerCase();
    }
    final destName = destId.isNotEmpty
        ? destId[0].toUpperCase() + destId.substring(1)
        : 'Pune';

    context.read<TripPlanningCubit>().setDestination(
      import_destination.Destination(
        id: destId,
        name: destName,
        country: 'India',
        region: 'Asia',
        description: '',
        imageUrl: widget.destinationPlace.imageUrl,
        latitude: widget.destinationPlace.latitude,
        longitude: widget.destinationPlace.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 1.0],
                colors: [
                  Color(0xFFD6EFFF), // Sky blue matching the design
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Plan A Trip',
                        style: AppTextStyles.h2.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (value) {
                            if (value == 'reset') {
                              setState(() {
                                _startDate = DateTime.now();
                                _endDate = DateTime.now().add(
                                  const Duration(days: 3),
                                );
                                _budgetSlider = 15000.0;
                                _budgetController.text = '₹15,000.00';
                                _selectedStyle = 'Adventure';
                              });
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'reset',
                              child: Text('Reset Preferences'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                    children: [
                      // Destination Header Card
                      GlassContainer(
                        borderRadius: 24,
                        color: Colors.white.withValues(alpha: 0.4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        blur: 20,
                        child: Container(
                          height: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            // Map background pattern
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop',
                              ),
                              fit: BoxFit.cover,
                              opacity: 0.15,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    // Show the destination city name, not the individual place name
                                    final placeId = widget.destinationPlace.id;
                                    final parts = placeId.split('_');
                                    String dId = 'pune';
                                    if (parts.length > 1) {
                                      dId = parts[0] == 'mock'
                                          ? parts[1].toLowerCase()
                                          : parts[0].toLowerCase();
                                    } else {
                                      dId = placeId.toLowerCase();
                                    }
                                    final dName = dId.isNotEmpty
                                        ? dId[0].toUpperCase() + dId.substring(1)
                                        : 'Pune';
                                    return Text(
                                      '$dName, India',
                                      style: AppTextStyles.h2.copyWith(
                                        fontSize: 18,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Voice memo icon simulation
                              Row(
                                children: [
                                  _buildAudioBar(12),
                                  _buildAudioBar(18),
                                  _buildAudioBar(10),
                                  _buildAudioBar(24),
                                  _buildAudioBar(14),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date & Budget Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date & Budget',
                                  style: AppTextStyles.h2.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Save',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _blueColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Date Selection row
                            SizedBox(
                              height: 70,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 7,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final date = DateTime.now().add(
                                    Duration(days: index),
                                  );
                                  final dayInitial = _getDayInitial(
                                    date.weekday,
                                  );

                                  DateSelectionState state =
                                      DateSelectionState.unselected;

                                  // Strip time for comparison
                                  final compareDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                  );
                                  final compareStart = DateTime(
                                    _startDate.year,
                                    _startDate.month,
                                    _startDate.day,
                                  );
                                  final compareEnd = DateTime(
                                    _endDate.year,
                                    _endDate.month,
                                    _endDate.day,
                                  );

                                  if (compareDate.isAtSameMomentAs(
                                        compareStart,
                                      ) ||
                                      compareDate.isAtSameMomentAs(
                                        compareEnd,
                                      )) {
                                    state = DateSelectionState.start;
                                  } else if (compareDate.isAfter(
                                        compareStart,
                                      ) &&
                                      compareDate.isBefore(compareEnd)) {
                                    state = DateSelectionState.inRange;
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (compareDate.isBefore(
                                              compareStart,
                                            ) ||
                                            compareDate.isAfter(compareEnd)) {
                                          if (_startDate.isAtSameMomentAs(
                                            _endDate,
                                          )) {
                                            if (compareDate.isAfter(
                                              _startDate,
                                            )) {
                                              _endDate = compareDate;
                                            } else {
                                              _startDate = compareDate;
                                            }
                                          } else {
                                            _startDate = compareDate;
                                            _endDate = compareDate;
                                          }
                                        } else if (compareDate.isAtSameMomentAs(
                                          compareStart,
                                        )) {
                                          if (!_startDate.isAtSameMomentAs(
                                            _endDate,
                                          )) {
                                            _startDate = _endDate;
                                          }
                                        } else if (compareDate.isAtSameMomentAs(
                                          compareEnd,
                                        )) {
                                          _endDate = _startDate;
                                        } else {
                                          // Tapped in middle, start new range
                                          _startDate = compareDate;
                                          _endDate = compareDate;
                                        }
                                      });
                                    },
                                    child: _buildDateItem(
                                      dayInitial,
                                      '${date.day}',
                                      state,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Amount Input
                            Text(
                              'Amount',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                              ),
                              child: TextField(
                                controller: _budgetController,
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Budget Slider
                            Row(
                              children: [
                                Text(
                                  '₹0.00',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: _blueColor,
                                      inactiveTrackColor: _blueColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      thumbColor: _blueColor,
                                      trackHeight: 6,
                                      valueIndicatorColor: _blueColor
                                          .withValues(alpha: 0.2),
                                      valueIndicatorTextStyle: AppTextStyles
                                          .bodySmall
                                          .copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      showValueIndicator:
                                          ShowValueIndicator.onDrag,
                                    ),
                                    child: Slider(
                                      value: _budgetSlider,
                                      min: 0,
                                      max: 50000,
                                      divisions: 50,
                                      label: '₹${_budgetSlider.toInt()}.00',
                                      onChanged: (val) {
                                        setState(() {
                                          _budgetSlider = val;
                                          _budgetController.text =
                                              '₹${val.toStringAsFixed(2)}';
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹50,000.00',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Travel Style Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Travel Style',
                                  style: AppTextStyles.h2.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Save',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFFFDB022),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _styles
                                  .map(
                                    (s) =>
                                        _buildStyleItem(s, s == _selectedStyle),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Generate Button moved into the list so it scrolls
                      SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            final placeId = widget.destinationPlace.id;
                            final parts = placeId.split('_');
                            String destId = 'pune';
                            if (parts.length > 1) {
                              destId = parts[0] == 'mock'
                                  ? parts[1].toLowerCase()
                                  : parts[0].toLowerCase();
                            } else {
                              destId = placeId.toLowerCase();
                            }

                            final destName = destId.isNotEmpty
                                ? destId[0].toUpperCase() + destId.substring(1)
                                : 'Pune';

                            final trip = Trip(
                              id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
                              destination: import_destination.Destination(
                                id: destId,
                                name: destName,
                                country: 'India',
                                region: 'Asia',
                                description: '',
                                imageUrl: widget.destinationPlace.imageUrl,
                                latitude: widget.destinationPlace.latitude,
                                longitude: widget.destinationPlace.longitude,
                              ),
                              startDate: _startDate,
                              endDate: _endDate,
                              preferences: TripPreferences(
                                budget: _budgetSlider.toInt(),
                                travelStyle: _selectedStyle,
                                numberOfDays:
                                    _endDate.difference(_startDate).inDays + 1,
                              ),
                            );

                            context.read<ItineraryCubit>().generateItinerary(
                              trip,
                              [widget.destinationPlace],
                            );
                            context.go('/itinerary');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF8DC6F3,
                            ), // Light blue button color from design
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Generate Itinerary',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.7,
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
          ),

          // Bottom Nav overlay
          const AppBottomNavigation(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildAudioBar(double height) {
    return Container(
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDateItem(String day, String date, DateSelectionState state) {
    return Column(
      children: [
        Text(
          day,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: state == DateSelectionState.start
                ? _blueColor
                : (state == DateSelectionState.unselected
                      ? const Color(0xFFF2F4F7)
                      : Colors.transparent),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: state == DateSelectionState.start
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              if (state == DateSelectionState.start ||
                  state == DateSelectionState.inRange)
                Container(
                  width: 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: state == DateSelectionState.start
                        ? Colors.white
                        : _blueColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleItem(String label, bool isSelected) {
    final emojiMap = {
      'Adventure': '🏕️',
      'Solo Travel': '🎒',
      'Road Trip': '🚗',
      'Family Tour': '👨‍👩‍👧‍👦',
    };

    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFFFDB022).withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFDB022).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(emojiMap[label]!, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayInitial(int weekday) {
    switch (weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }
}
