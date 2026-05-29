import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';

/// A centered placeholder shown when there is no content to display.
///
/// Composes an [icon], a required [title], and an optional [subtitle], all
/// centered and styled with design tokens.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  /// Leading illustrative icon (use `Icons.*`).
  final IconData icon;

  /// Primary message (Arabic).
  final String title;

  /// Optional supporting message (Arabic).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Flat hairline circle: surfaceSoft fill, 1px hairline border,
            // solid ink glyph. No shadow, no fill color — depth is the border.
            Container(
              width: AppSpacing.xxl + AppSpacing.md,
              height: AppSpacing.xxl + AppSpacing.md,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Icon(
                icon,
                size: AppSpacing.xl,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLg,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                // Weight, not gray, carries hierarchy — body stays ink.
                style: AppTextStyles.bodyMd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
