import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'glass_container.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    if (isKeyboardOpen) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GlassContainer(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white.withValues(alpha: 0.6), // Light glass
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            blur: 15.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_rounded,
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                const SizedBox(width: 6),
                _buildNavItem(
                  context,
                  icon: Icons.grid_view_rounded,
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/explore'),
                ),
                // Only show heart on some screens, but we'll show it generally as requested in UI
                const SizedBox(width: 6),
                _buildNavItem(
                  context,
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/favorites'),
                ),
                // We'll add map/trip icon for the trip planner
                const SizedBox(width: 6),
                _buildNavItem(
                  context,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/itinerary'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    IconData? activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isActive ? (activeIcon ?? icon) : icon,
          color: isActive ? Colors.white : Colors.black.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );
  }
}
