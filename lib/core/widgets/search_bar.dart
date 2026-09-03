import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass_container.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.hintText = 'Find places, food, trips...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 30,
      color: Colors.white.withValues(alpha: 0.75),
      border: Border.all(color: Colors.white, width: 1.5),
      blur: 30,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        readOnly: readOnly,
        focusNode: focusNode,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textPrimary),
          suffixIcon: const Icon(Icons.mic_none, color: AppColors.textPrimary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
