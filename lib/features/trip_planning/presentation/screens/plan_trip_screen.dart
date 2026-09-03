import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/place.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../cubit/trip_planning_cubit.dart';
import '../cubit/trip_planning_state.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../../../core/models/destination.dart' as import_destination;
import '../../../../core/cubits/location_cubit.dart';
import 'package:table_calendar/table_calendar.dart';

class PlanTripScreen extends StatefulWidget {
  final Place destinationPlace;

  const PlanTripScreen({super.key, required this.destinationPlace});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 4; // Phase 3 and 4 steps

  // Preferences Data
  final List<Map<String, dynamic>> _preferences = [
    {'label': 'Popular', 'image': 'assets/icons_forwhereinto/popular.jpeg'},
    {'label': 'Museum', 'image': 'assets/icons_forwhereinto/museum.png'},
    {'label': 'Nature', 'image': 'assets/icons_forwhereinto/hiils.jpeg'},
    {'label': 'Foodie', 'image': 'assets/icons_forwhereinto/eat cafes.jpeg'},
    {'label': 'History', 'image': 'assets/icons_forwhereinto/adventure.png'},
    {'label': 'Shopping', 'image': 'assets/icons_forwhereinto/shopping.jpeg'},
  ];

  List<Map<String, dynamic>> get _companions => [
    {'label': 'Solo', 'image': 'assets/travelwith_page/solo.webp'},
    {'label': 'Couple', 'image': 'assets/travelwith_page/couple.png'},
    {'label': 'Family', 'image': 'assets/travelwith_page/family.webp'},
    {'label': 'Friends', 'image': 'assets/travelwith_page/friends.webp'},
  ];

  final List<Map<String, dynamic>> _budgets = [
    {
      'label': 'Budget',
      'image': 'assets/bugets/financial-.webp',
      'value': 2000,
    },
    {
      'label': 'Standard',
      'image': 'assets/bugets/standard.png',
      'value': 10000,
    },
    {'label': 'Luxury', 'image': 'assets/bugets/luxury.webp', 'value': 50000},
  ];

  // Date Selection Data
  bool _isFlexibleDates = false;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _firstDay;
  late DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _firstDay = DateTime.now();
    _lastDay = _firstDay.add(const Duration(days: 365));
    _startDate = _firstDay;
    _endDate = _firstDay.add(const Duration(days: 2));

    final locationState = context.read<LocationCubit>().state;
    String destId = 'pune';
    String destName = 'Pune';
    double lat = 18.5204;
    double lng = 73.8567;

    if (locationState is LocationLoaded) {
      destName = locationState.currentLocation.name.split(',')[0].trim();
      destId = destName.toLowerCase();
      lat = locationState.currentLocation.latitude ?? lat;
      lng = locationState.currentLocation.longitude ?? lng;
    }

    context.read<TripPlanningCubit>().setDestination(
      import_destination.Destination(
        id: destId,
        name: destName,
        country: 'India',
        region: 'Asia',
        description: '',
        imageUrl: widget.destinationPlace.imageUrl,
        latitude: lat,
        longitude: lng,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_endDate.difference(_startDate).inDays == 0) {
        _showOneDayTripOptionsSheet();
      } else {
        _generateTrip();
      }
    }
  }

  void _showOneDayTripOptionsSheet() {
    String selectedTime = 'Morning (9 AM)';
    bool exploreNearby = true;
    final timeOptions = ['Morning (9 AM)', 'Afternoon (1 PM)', 'Evening (5 PM)'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize your 1-Day Trip',
                      style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'What time do you want to start?',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: timeOptions.map((time) {
                        final isSelected = selectedTime == time;
                        return ChoiceChip(
                          label: Text(time),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedTime = time);
                            }
                          },
                          selectedColor: const Color(0xFF007AFF).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF007AFF) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'How do you want to explore?',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<bool>(
                      title: const Text('Explore only this spot'),
                      subtitle: Text('Generate an itinerary focused entirely on ${widget.destinationPlace.name}'),
                      value: false,
                      groupValue: exploreNearby,
                      onChanged: (val) => setSheetState(() => exploreNearby = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<bool>(
                      title: const Text('Explore nearby spots too'),
                      subtitle: Text('Include other popular spots around ${widget.destinationPlace.name}'),
                      value: true,
                      groupValue: exploreNearby,
                      onChanged: (val) => setSheetState(() => exploreNearby = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _generateTrip(startTime: selectedTime, exploreNearby: exploreNearby);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text(
                          'Continue',
                          style: AppTextStyles.h3.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _generateTrip({String? startTime, bool? exploreNearby}) {
    final cubitState =
        context.read<TripPlanningCubit>().state as TripPlanningForm;
    final trip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      destination: cubitState.selectedDestination!,
      startDate: _startDate,
      endDate: _endDate,
      anchorPlaceId: widget.destinationPlace.id,
      preferences: TripPreferences(
        budget: cubitState.budget,
        travelStyle:
            '${cubitState.companion}, ${cubitState.travelStyles.join(', ')}',
        numberOfDays: _endDate.difference(_startDate).inDays + 1,
        startTime: startTime,
        includeNearbyPlaces: exploreNearby,
      ),
    );

    context.go(
      '/generate_trip',
      extra: {'trip': trip, 'anchorPlace': widget.destinationPlace},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBodyBehindAppBar: true,
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
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildPreferencesStep(),
                      _buildCompanionStep(),
                      _buildBudgetStep(),
                      _buildDateSelectionStep(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentPage > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/explore');
              }
            },
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _currentPage + 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: _totalPages - (_currentPage + 1),
                    child: const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return BlocBuilder<TripPlanningCubit, TripPlanningState>(
      builder: (context, state) {
        final formState = state as TripPlanningForm;
        final selectedStyles = formState.travelStyles;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you into?',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a few and we\'ll lean the picks that way.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _preferences.length,
                  itemBuilder: (context, index) {
                    final pref = _preferences[index];
                    final isSelected = selectedStyles.contains(pref['label']);
                    return GestureDetector(
                      onTap: () {
                        context.read<TripPlanningCubit>().toggleTravelStyle(
                          pref['label'],
                        );
                      },
                      child: GlassContainer(
                        borderRadius: 24,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : Colors.white.withValues(alpha: 0.8),
                          width: isSelected ? 2 : 1.5,
                        ),
                        blur: 20,
                        child: Stack(
                          children: [
                            if (isSelected)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF007AFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    pref['image'],
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    pref['label'],
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedStyles.isEmpty ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStyles.isEmpty
                        ? Colors.grey.withValues(alpha: 0.3)
                        : AppColors.textPrimary,
                    foregroundColor: selectedStyles.isEmpty
                        ? Colors.grey
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.h3.copyWith(
                      color: selectedStyles.isEmpty
                          ? Colors.black38
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanionStep() {
    return BlocBuilder<TripPlanningCubit, TripPlanningState>(
      builder: (context, state) {
        final formState = state as TripPlanningForm;
        final selectedCompanion = formState.companion;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who are you traveling with?',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us your companions.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _companions.length,
                  itemBuilder: (context, index) {
                    final comp = _companions[index];
                    final isSelected = selectedCompanion == comp['label'];
                    return GestureDetector(
                      onTap: () {
                        context.read<TripPlanningCubit>().setCompanion(
                          comp['label'],
                        );
                      },
                      child: GlassContainer(
                        borderRadius: 24,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : Colors.white.withValues(alpha: 0.8),
                          width: isSelected ? 2 : 1.5,
                        ),
                        blur: 20,
                        child: Stack(
                          children: [
                            if (isSelected)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF007AFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    comp['image'],
                                    height: 72,
                                    width: 72,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    comp['label'],
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedCompanion.isEmpty ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCompanion.isEmpty
                        ? Colors.grey.withValues(alpha: 0.3)
                        : AppColors.textPrimary,
                    foregroundColor: selectedCompanion.isEmpty
                        ? Colors.grey
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.h3.copyWith(
                      color: selectedCompanion.isEmpty
                          ? Colors.black38
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetStep() {
    return BlocBuilder<TripPlanningCubit, TripPlanningState>(
      builder: (context, state) {
        final formState = state as TripPlanningForm;
        final selectedBudget = formState.budget;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What is your budget?',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us find places that fit your budget.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _budgets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final budget = _budgets[index];
                    final isSelected = selectedBudget == budget['value'];
                    return GestureDetector(
                      onTap: () {
                        context.read<TripPlanningCubit>().setBudget(
                          budget['value'],
                        );
                      },
                      child: GlassContainer(
                        borderRadius: 20,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : Colors.white.withValues(alpha: 0.8),
                          width: isSelected ? 2 : 1.5,
                        ),
                        blur: 20,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              budget['image'],
                              height: 40,
                              width: 40,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    budget['label'],
                                    style: AppTextStyles.h3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Around ₹${budget['value']} total',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF007AFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelectionStep() {
    final days = _endDate.difference(_startDate).inDays + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When are you going?',
            style: AppTextStyles.h1.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick dates or keep it loose.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFlexibleDates = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_isFlexibleDates
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: !_isFlexibleDates
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Dates',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFlexibleDates = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isFlexibleDates
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: _isFlexibleDates
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Flexible',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                  border: Border.all(
                    color: const Color(0xFF007AFF),
                    width: 1.5,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEPARTURE',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF007AFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getMonthStr(_startDate.month)} ${_startDate.day}',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  borderRadius: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                  border: Border.all(
                    color: const Color(0xFF007AFF),
                    width: 1.5,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RETURN',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF007AFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getMonthStr(_endDate.month)} ${_endDate.day}',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$days',
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                    ),
                    Text(
                      'DAYS',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          GlassContainer(
            borderRadius: 24,
            color: Colors.white.withValues(alpha: 0.6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _startDate,
                rangeStartDay: _startDate,
                rangeEndDay: _endDate,
                calendarFormat: CalendarFormat.month,
                rangeSelectionMode: RangeSelectionMode.enforced,
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    if (start != null) {
                      _startDate = start;
                      _endDate = end ?? start;
                    }
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: const Color(
                    0xFF007AFF,
                  ).withValues(alpha: 0.2),
                  rangeStartDecoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Find your spots',
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthStr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
