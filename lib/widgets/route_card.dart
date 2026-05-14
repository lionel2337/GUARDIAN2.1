/// Route card — displays a route summary with duration, distance, and safety score.
library;

import 'package:flutter/material.dart';

import '../utils/constants.dart';

class RouteCard extends StatelessWidget {
  final String routeName;
  final int durationMinutes;
  final double distanceKm;
  final double safetyScore; // 0.0 to 1.0
  final bool isSelected;
  final bool isSafest;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.routeName,
    required this.durationMinutes,
    required this.distanceKm,
    required this.safetyScore,
    required this.isSelected,
    required this.isSafest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : AppColors.card,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSafest
                ? AppColors.success
                : (isSelected ? AppColors.accent : AppColors.divider),
            width: isSafest ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Safety score indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _safetyColor.withOpacity(0.15),
                border: Border.all(color: _safetyColor, width: 2),
              ),
              child: Center(
                child: Text(
                  '${(safetyScore * 100).round()}',
                  style: TextStyle(
                    color: _safetyColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Route info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(routeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      if (isSafest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 12, color: AppColors.success),
                              SizedBox(width: 2),
                              Text('SAFEST',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('$durationMinutes min',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.straighten_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('${distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 24),
          ],
        ),
      ),
    );
  }

  Color get _safetyColor {
    if (safetyScore >= 0.75) return AppColors.success;
    if (safetyScore >= 0.50) return AppColors.warning;
    return AppColors.danger;
  }
}
