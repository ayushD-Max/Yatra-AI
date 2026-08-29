import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_network_image.dart';
import 'glass_container.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.isFavorite = false,
    required this.onFavoriteToggle,
    this.width,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton.keep(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width ?? 160,
          height: height ?? 220,
          margin: margin ?? const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              AppNetworkImage(
                imageUrl: place.imageUrl,
                height: double.infinity,
                width: double.infinity,
                borderRadius: BorderRadius.circular(32),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Heart Icon
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onFavoriteToggle,
                  child: GlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(8),
                    blur: 15,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.error : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Text Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.category,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.name,
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
