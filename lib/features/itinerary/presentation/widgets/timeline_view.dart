import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/itinerary.dart';
import '../../../../core/widgets/app_network_image.dart';

class TimelineView extends StatefulWidget {
  final List<ItineraryDay> days;
  final bool isLoading;

  const TimelineView({super.key, required this.days, this.isLoading = false});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Plan Your Adventure',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Type in the chat bar below to create your trip.\n'
                'Try: "Plan a 2-day trip to Pune with ₹5000 budget"\n'
                'or: "I have 1 day for Rajgad Fort"',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_downward_rounded,
                color: AppColors.textPrimary.withValues(alpha: 0.3),
                size: 32,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
      itemCount: widget.days.length,
      itemBuilder: (context, dayIndex) {
        final day = widget.days[dayIndex];
        return TweenAnimationBuilder<double>(
          key: ValueKey('day_${dayIndex}_${day.items.length}'),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _buildDaySection(day, dayIndex + 1),
        );
      },
    );
  }

  Widget _buildDaySection(ItineraryDay day, int dayNumber) {
    // Collect unique categories for subtitle
    final categories = day.items
        .map((e) => e.place.category)
        .toSet()
        .take(2)
        .join(' & ');
    final subtitle = categories.isNotEmpty ? categories : 'Explore & Enjoy';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Header
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DAY $dayNumber',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Items with timeline line
        ...day.items.asMap().entries.map((entry) {
          final isLast = entry.key == day.items.length - 1;
          return _buildTimelineItem(entry.value, isLast, entry.key);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(ItineraryItem item, bool isLast, int index) {
    // Format times correctly using padLeft
    final startStr =
        '${item.startTime?.hour.toString().padLeft(2, '0')}:${item.startTime?.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${item.endTime?.hour.toString().padLeft(2, '0')}:${item.endTime?.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line & Dot
          SizedBox(
            width: 30,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Card Content
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 500 + (index * 150)),
              curve: Curves.easeOutQuint,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(50 * (1 - value), 0),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: AppNetworkImage(
                                imageUrl: item.place.imageUrl,
                                width: 100,
                                height: 100,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.place.name,
                                    style: AppTextStyles.h3.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$startStr - $endStr',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.place.category,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.notes.isNotEmpty && !isLast)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          bottom: 8,
                          left: 8,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.notes,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
