import 'package:flutter/material.dart';

import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/shared/status_pill.dart';

/// Generative-UI widget for a [StatCardSpec] — a single headline metric.
///
/// Renders the "Generative UI card" recipe from PRD §10.6: a white surface
/// with a 1px [AppColors.line] border, [AppRadius.lg] corners, [AppSpacing.md]
/// padding and the soft resting shadow from §10.5. Layout is RTL-correct
/// (directional padding/alignment only) and every string is Arabic.
///
/// The card shows, top to bottom:
///  - the [StatCardSpec.title] alongside a [StatusPill] colored by status,
///  - the big [StatCardSpec.value] + [StatCardSpec.unit] using the metric style,
///  - an optional delta line (the model-supplied [StatCardSpec.delta] string).
///
/// The whole card is tappable when [onTap] is provided (e.g. to drill into the
/// station detail screen).
class StatCardBlock extends StatelessWidget {
  const StatCardBlock({
    super.key,
    required this.spec,
    this.onTap,
  });

  /// The parsed block specification to render.
  final StatCardSpec spec;

  /// Optional tap handler — typically opens the station detail screen.
  final VoidCallback? onTap;

  /// Soft resting card shadow per PRD §10.5.
  static const List<BoxShadow> _restingShadow = <BoxShadow>[
    BoxShadow(
      blurRadius: 30,
      offset: Offset(0, 10),
      color: Color(0x0F0D2B3E), // rgba(13,43,62,0.06)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Color statusColor = AppColors.statusColor(spec.status);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
            boxShadow: _restingShadow,
          ),
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Title + status pill row.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      spec.title,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusPill(status: spec.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Big metric value + unit.
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: <Widget>[
                  Text(
                    formatLevel(spec.value),
                    style: AppTextStyles.metric.copyWith(color: statusColor),
                  ),
                  if (_hasCustomUnit) ...<Widget>[
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      spec.unit,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ],
              ),

              // Optional delta line.
              if (_deltaText != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _deltaText!,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// `formatLevel` already appends the Arabic meters unit ("م"). Only show the
  /// spec's own unit when it differs from that default, to avoid duplicating
  /// "م م" for the common water-level case.
  bool get _hasCustomUnit {
    final String unit = spec.unit.trim();
    return unit.isNotEmpty && unit != 'م';
  }

  /// Trimmed delta text, or null when the model supplied no/empty delta.
  String? get _deltaText {
    final String? raw = spec.delta?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}
