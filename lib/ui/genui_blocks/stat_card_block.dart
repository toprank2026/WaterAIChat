import 'package:flutter/material.dart';

import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';
import 'package:ma_water/ui/shared/status_pill.dart';

/// Generative-UI widget for a [StatCardSpec] — a single headline metric.
///
/// Renders the editorial "Generative UI card" recipe: a flat white
/// [AppColors.card] surface with a 1px [AppColors.hairline] border and
/// [AppRadius.lg] corners — no shadow, no gradient. Depth comes from the
/// hairline plus a single thin pastel side rule tinted by the station status
/// ([AppColors.statusBg]), the one color block this card is allowed. Layout is
/// RTL-correct (directional padding/alignment only) and every string is Arabic.
///
/// The card shows, top to bottom:
///  - a small mono UPPERCASE eyebrow label,
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

  @override
  Widget build(BuildContext context) {
    // The single pastel block this card carries: a thin status-tinted side
    // rule on the start (RTL right) edge.
    final Color sideRule = AppColors.statusBg(spec.status);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.hairline),
          ),
          // Clip so the leading pastel side rule is rounded with the card.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Thin pastel side rule on the start (RTL right) edge — the
                  // one color block, tinted by status severity.
                  _SideRule(color: sideRule),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Mono uppercase eyebrow taxonomy label.
                          Text(
                            'WATER LEVEL',
                            style: AppTextStyles.eyebrow,
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Title + sparkle + status pill row.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsetsDirectional.only(
                                  top: 2,
                                  end: AppSpacing.xxs,
                                ),
                                child: GradientIcon(
                                  icon: Icons.auto_awesome,
                                  size: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  spec.title,
                                  style: AppTextStyles.titleMd,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              StatusPill(status: spec.status),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Big metric value + unit — ink (weight carries it).
                          Row(
                            textBaseline: TextBaseline.alphabetic,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: <Widget>[
                              Text(
                                formatLevel(spec.value),
                                style: AppTextStyles.metric,
                              ),
                              if (_hasCustomUnit) ...<Widget>[
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  spec.unit,
                                  style: AppTextStyles.titleMd,
                                ),
                              ],
                            ],
                          ),

                          // Optional delta line.
                          if (_deltaText != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              _deltaText!,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.slate),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

/// A slim flat pastel bar drawn on the leading edge of the card — the single
/// status-tinted color block, replacing the old gemini-gradient accent strip.
class _SideRule extends StatelessWidget {
  const _SideRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.xxs,
      child: ColoredBox(color: color),
    );
  }
}
