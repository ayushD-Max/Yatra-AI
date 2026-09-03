import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/models/place.dart' as import_place;
import '../../../../core/models/itinerary.dart';
import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../widgets/timeline_view.dart';
import '../widgets/storymode_view.dart';
import '../../../../core/services/gemini_service.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  bool _isTimeline = true;
  final TextEditingController _modifyController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void dispose() {
    _modifyController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
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
        title: const Text('Trip Journal'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Dismiss',
                    barrierColor: Colors.black.withValues(alpha: 0.1),
                    transitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return SafeArea(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60, right: 16),
                            child: Material(
                              color: Colors.transparent,
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                borderRadius: 20,
                                color: Colors.white.withValues(alpha: 0.4),
                                blur: 15,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                child: IntrinsicWidth(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildMenuItem(
                                        icon: Icons.backpack_outlined,
                                        label: 'AI Packing List ✨',
                                        iconColor: Colors.blue,
                                        textColor: Colors.blue,
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showPackingListDialog(context);
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.refresh,
                                        label: 'Refresh Itinerary',
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Refresh logic
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.restore,
                                        label: 'Reset Modifications',
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Reset modifications
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.delete_outline,
                                        label: 'Clear Trip',
                                        iconColor: Colors.red,
                                        textColor: Colors.red,
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Clear Trip?'),
                                              content: const Text(
                                                'Are you sure you want to delete this itinerary? This cannot be undone.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    context
                                                        .read<ItineraryCubit>()
                                                        .clearTrip();
                                                    context
                                                        .pop(); // Pop the itinerary screen
                                                  },
                                                  child: const Text(
                                                    'Clear',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (context) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final isKeyboardOpen = keyboardHeight > 0;

          return Stack(
            children: [
              Column(
                children: [
                  // Toggle
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTimeline = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isTimeline
                                    ? AppColors.backgroundWarm
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '📜',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Timeline',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTimeline = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isTimeline
                                    ? AppColors.backgroundWarm
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '📖',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Storymode',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: BlocConsumer<ItineraryCubit, ItineraryState>(
                      listener: (context, state) {
                        if (state is ItineraryLoaded &&
                            state.aiExplanation != null &&
                            state.aiExplanation!.isNotEmpty) {
                          _showAiResponseBottomSheet(
                            context,
                            state.aiExplanation!,
                          );
                        }
                      },
                      builder: (context, state) {
                        final bool isLoading = state is ItineraryGenerating;

                        if (state is ItineraryError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Try typing a new request below',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is ItineraryPreChat) {
                          return ListView.builder(
                            controller: _chatScrollController,
                            reverse: true,
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 24,
                              bottom: isKeyboardOpen
                                  ? keyboardHeight + 80
                                  : 180,
                            ),
                            itemCount: state.chatHistory.length,
                            itemBuilder: (context, index) {
                              // Access reversed since list is reversed
                              final msg =
                                  state.chatHistory[state.chatHistory.length -
                                      1 -
                                      index];
                              final isUser = msg['role'] == 'user';
                              return Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: index == 0 ? 0 : 12,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser ? Colors.blue : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    msg['text'] ?? '',
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        List<ItineraryDay> days = [];
                        if (state is ItineraryLoaded) {
                          days = state.itinerary.days;
                        }

                        if (_isTimeline) {
                          return TimelineView(days: days, isLoading: isLoading);
                        } else {
                          // Flatten days for Storymode
                          final List<ItineraryItem> allItems = isLoading
                              ? List.generate(
                                  3,
                                  (index) => ItineraryItem(
                                    place: import_place.Place(
                                      id: '$index',
                                      name: 'Loading Incredible Place',
                                      category: 'Must See',
                                      tags: ['Adventure'],
                                      description: '',
                                      imageUrl: '',
                                      latitude: 0,
                                      longitude: 0,
                                    ),
                                  ),
                                )
                              : days.expand((day) => day.items).toList();
                          return StorymodeView(
                            items: allItems,
                            isLoading: isLoading,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              // AI Chat Bar — moves up with keyboard
              if (_isTimeline)
                Positioned(
                  bottom: isKeyboardOpen ? keyboardHeight + 8 : 100,
                  left: 24,
                  right: 24,
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    borderRadius: 30,
                    color: Colors.white.withValues(alpha: 0.8),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BlocBuilder<ItineraryCubit, ItineraryState>(
                            builder: (context, state) {
                              final bool isModifying =
                                  state is ItineraryGenerating ||
                                  (state is ItineraryPreChat && state.isTyping);
                              final bool hasTrip =
                                  state is ItineraryLoaded ||
                                  state is ItineraryPreChat;
                              return TextField(
                                controller: _modifyController,
                                enabled: !isModifying,
                                decoration: InputDecoration(
                                  hintText: isModifying
                                      ? 'Thinking...'
                                      : hasTrip
                                      ? 'Type your message...'
                                      : 'e.g. "Plan 2-day Pune trip, ₹5000"',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (val) {
                                  if (val.isNotEmpty && !isModifying) {
                                    if (state is ItineraryPreChat) {
                                      context
                                          .read<ItineraryCubit>()
                                          .sendPreChatMessage(val);
                                    } else {
                                      context
                                          .read<ItineraryCubit>()
                                          .modifyItinerary(val);
                                    }
                                    _modifyController.clear();
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        BlocBuilder<ItineraryCubit, ItineraryState>(
                          builder: (context, state) {
                            final bool isModifying =
                                state is ItineraryGenerating ||
                                (state is ItineraryPreChat && state.isTyping);
                            return isModifying
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.send,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      if (_modifyController.text.isNotEmpty) {
                                        if (state is ItineraryPreChat) {
                                          context
                                              .read<ItineraryCubit>()
                                              .sendPreChatMessage(
                                                _modifyController.text,
                                              );
                                        } else {
                                          context
                                              .read<ItineraryCubit>()
                                              .modifyItinerary(
                                                _modifyController.text,
                                              );
                                        }
                                        _modifyController.clear();
                                      }
                                    },
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              // Hide bottom nav when keyboard is open or in Storymode
              if (!isKeyboardOpen && _isTimeline)
                const AppBottomNavigation(currentIndex: 3),
            ],
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

  Future<void> _showPackingListDialog(BuildContext context) async {
    final cubit = context.read<ItineraryCubit>();
    final trip = cubit.currentTrip;
    if (trip == null || trip.destination == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final packingList = await GeminiService().generatePackingList(
        trip.destination!.name,
        trip.durationInDays,
        trip.preferences.travelStyle,
      );
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading
      _showAiResponseBottomSheet(context, packingList);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate packing list: $e')),
      );
    }
  }

  void _showAiResponseBottomSheet(BuildContext context, String explanation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GlassContainer(
          borderRadius: 32,
          color: Colors.white.withValues(alpha: 0.95),
          blur: 20,
          border: Border.all(color: Colors.white, width: 1.5),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Yatra AI Assistant',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    explanation,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Awesome, Thanks!'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
