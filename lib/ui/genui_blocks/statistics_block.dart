import 'package:flutter/material.dart';

import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// Generative-UI widget for a [StatisticsSpec] — a titled 2-column grid of
/// labelled statistics for one station (e.g. current / max / min / average over
/// a window).
///
/// Renders the "Generative UI card" recipe from PRD §10.6: a white surface with
/// a 1px [AppColors.line] border, [AppRadius.lg] corners, [AppSpacing.md]
/// padding and the soft resting shadow from §10.5. Layout is RTL-correct
/// (directional padding/alignment only) and every string is Arabic.
///
/// Each tile shows:
///  - the [StatItem.label] (caption / [AppColors.slate]),
///  - the big [StatItem.value] + [StatItem.unit] in [AppTextStyles.metric],
///  - a compact horizontal bar whose width is proportional to the value
///    normalized across all stats' min..max, so الحالي/الأعلى/الأدنى/المتوسط
///    can be compared at a glance.
///
/// The primary "الحالي" tile is painted with the Gemini gradient via
/// [GradientText] and its bar is filled with [AppColors.geminiGradient] (or the
/// status colour when a status is present); tiles that carry a
/// [StatItem.status] use the status foreground/background colours; the rest get
/// a subtle mint tint and a teal bar.
///
/// The bars draw in once on first build via a one-shot [TweenAnimationBuilder]
/// (no infinite animation, so the card renders under a single test pump()).
///
/// The whole card is tappable when [onTap] is provided and the spec carries a
/// `stationId` (e.g. to drill into the station detail screen).
class StatisticsBlock extends StatelessWidget {
  const StatisticsBlock({
    super.key,
    required this.spec,
    this.onTap,
  });

  /// The parsed block specification to render.
  final StatisticsSpec spec;

  /// Optional tap handler — invoked with the spec's `stationId` to open the
  /// station detail screen. Ignored when the spec has no station context.
  final void Function(String stationId)? onTap;

  /// The Arabic label for the primary ("current") statistic, which is rendered
  /// with the Gemini gradient.
  static const String _primaryLabel = 'الحالي';

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
    final String? stationId = _stationId;
    final VoidCallback? handler =
        (onTap != null && stationId != null) ? () => onTap!(stationId) : null;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: handler,
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
              Text(
                spec.title,
                style: AppTextStyles.titleMd.copyWith(color: AppColors.slate),
              ),
              if (spec.stats.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                _StatGrid(stats: spec.stats),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Trimmed station id, or null when the model supplied none/empty.
  String? get _stationId {
    final String? raw = spec.stationId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}

/// A responsive 2-column grid of [_StatTile]s built from [LayoutBuilder] +
/// [Wrap] so it sizes naturally inside the chat list's [Column] (no fixed
/// height / nested scroll view).
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<StatItem> stats;

  @override
  Widget build(BuildContext context) {
    const double gap = AppSpacing.xs;
    // The value range shared by every bar so they compare on one scale.
    final double minValue =
        stats.map((s) => s.value).reduce((a, b) => a < b ? a : b);
    final double maxValue =
        stats.map((s) => s.value).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns with a single gap between them.
        final double tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final stat in stats)
              SizedBox(
                width: tileWidth,
                child: _StatTile(
                  stat: stat,
                  primary: _isPrimary(stat.label),
                  fraction: _fraction(stat.value, minValue, maxValue),
                ),
              ),
          ],
        );
      },
    );
  }

  /// The "current" tile gets gradient treatment.
  bool _isPrimary(String label) =>
      label.trim() == StatisticsBlock._primaryLabel;

  /// Maps [value] onto a 0.08..1.0 fill fraction across the [min]..[max] range
  /// shared by all stats. When every value is equal (a flat range) bars are
  /// drawn full so the tiles still read as "equal". A small floor keeps even
  /// the minimum value visible as a sliver rather than an empty track.
  double _fraction(double value, double min, double max) {
    final double span = max - min;
    if (span <= 0) return 1.0;
    final double t = (value - min) / span;
    return 0.08 + 0.92 * t.clamp(0.0, 1.0);
  }
}

/// A single statistic tile: label on top, big value + unit below, on a subtle
/// tinted/gradient background.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.stat,
    required this.primary,
    required this.fraction,
  });

  final StatItem stat;
  final bool primary;

  /// The bar's target fill fraction (0..1) normalized across all stats.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final StationStatus? status = stat.status;

    // Background tint: status tint if present, else mint for the primary tile,
    // else a faint sky neutral.
    final Color background = status != null
        ? AppColors.statusBg(status)
        : (primary ? AppColors.mint : AppColors.sky);

    // Border: status-tinted for status tiles, mint for the primary, line otherwise.
    final Color border = status != null
        ? AppColors.statusColor(status).withValues(alpha: 0.25)
        : (primary ? AppColors.mint2 : AppColors.line);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              stat.label,
              style: AppTextStyles.caption.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.xxs),
            _ValueLine(stat: stat, primary: primary, status: status),
            const SizedBox(height: AppSpacing.xs),
            _StatBar(fraction: fraction, primary: primary, status: status),
          ],
        ),
      ),
    );
  }
}

/// A compact horizontal comparison bar: a rounded [AppColors.line] track with a
/// proportional fill on the directional start (RTL: right) edge.
///
/// The fill is the Gemini gradient for the primary "الحالي" tile (or the status
/// colour when a status is present); every other tile gets a solid teal fill.
/// The bar grows from 0 to [fraction] exactly once via a one-shot
/// [TweenAnimationBuilder] — there is no repeating/infinite animation, so the
/// whole card settles within a single test pump().
class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.fraction,
    required this.primary,
    required this.status,
  });

  /// Target fill fraction in 0..1.
  final double fraction;
  final bool primary;
  final StationStatus? status;

  /// Track height — slim so it reads as an accent under the value, not a chart.
  static const double _height = 6;

  @override
  Widget build(BuildContext context) {
    final double target = fraction.clamp(0.0, 1.0);

    // Solid fill colour for non-gradient bars: status colour when present, else
    // teal for the comparison bars.
    final Color solidFill =
        status != null ? AppColors.statusColor(status!) : AppColors.teal;
    // The primary tile uses the Gemini gradient unless it carries a status.
    final bool useGradient = primary && status == null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.line),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: target),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: useGradient ? null : solidFill,
                      gradient: useGradient ? AppColors.geminiGradient : null,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The big value + unit line. Uses [GradientText] for the primary tile and the
/// status colour otherwise.
class _ValueLine extends StatelessWidget {
  const _ValueLine({
    required this.stat,
    required this.primary,
    required this.status,
  });

  final StatItem stat;
  final bool primary;
  final StationStatus? status;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = AppTextStyles.metric;
    final String valueText = _formatValue(stat.value);

    final Color color = status != null
        ? AppColors.statusColor(status!)
        : AppColors.ink;

    return Row(
      textBaseline: TextBaseline.alphabetic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: <Widget>[
        Flexible(
          child: primary
              ? GradientText(valueText, style: valueStyle)
              : Text(
                  valueText,
                  style: valueStyle.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        if (_hasUnit) ...<Widget>[
          const SizedBox(width: AppSpacing.xxs),
          Text(
            stat.unit.trim(),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
          ),
        ],
      ],
    );
  }

  bool get _hasUnit => stat.unit.trim().isNotEmpty;

  /// Two-decimal Western digits, mirroring [formatLevel] but without an
  /// appended unit (the unit is rendered separately so non-meter units work).
  String _formatValue(double v) =>
      formatLevel(v).replaceAll(' م', '').trim();
}
