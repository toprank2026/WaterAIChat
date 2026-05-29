import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/data/models/enums.dart';

/// A small rounded status indicator (طبيعي / تحذير / خطر) tinted by
/// [StationStatus].
///
/// Renders a colored dot plus an Arabic label. When [label] is omitted the
/// default Arabic status label from [statusLabelAr] is used.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.label,
  });

  /// Operational status that determines the pill's color and default label.
  final StationStatus status;

  /// Optional override text; defaults to the Arabic label for [status].
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Solid status hue drives the dot glyph; the pastel-block tint carries the
    // severity as a flat color block, and the label reads in ink mono caption.
    final Color fg = AppColors.statusColor(status);
    final Color bg = AppColors.statusBg(status);
    final String text = label ?? statusLabelAr(status);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
