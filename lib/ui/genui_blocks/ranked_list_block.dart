import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// GenUI block rendering a [RankedListSpec]: a flat white hairline card with an
/// ordered list of stations. Each row shows a 1..N rank index in a small solid
/// black circle, the station name, and the metric value + unit in ink. Rows are
/// separated by hairline dividers, are tappable, and report the tapped station
/// id via [onTapStation].
class RankedListBlock extends StatelessWidget {
  final RankedListSpec spec;
  final void Function(String stationId)? onTapStation;

  const RankedListBlock({
    super.key,
    required this.spec,
    this.onTapStation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // FLAT white card: no shadow, hairline border, radius lg.
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mono uppercase eyebrow taxonomy label above the title.
          Text(
            'RANKING',
            style: AppTextStyles.eyebrow,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            spec.title,
            style: AppTextStyles.titleLg,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (spec.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'لا توجد بيانات',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
              ),
            )
          else
            for (var i = 0; i < spec.items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, thickness: 1, color: AppColors.hairline),
              _RankedRow(
                rank: i + 1,
                item: spec.items[i],
                onTap: onTapStation,
              ),
            ],
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  final int rank;
  final RankedItem item;
  final void Function(String stationId)? onTap;

  const _RankedRow({
    required this.rank,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap == null ? null : () => onTap!(item.stationId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                item.name,
                style: AppTextStyles.titleMd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ValueLabel(value: item.value, unit: item.unit),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    // Rank index in a small solid black circle, white mono numeral.
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: AppTextStyles.caption.copyWith(color: AppColors.canvas),
      ),
    );
  }
}

class _ValueLabel extends StatelessWidget {
  final double value;
  final String unit;

  const _ValueLabel({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _formatValue(value),
          style: AppTextStyles.metric,
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xxs),
          Text(
            unit,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
          ),
        ],
      ],
    );
  }

  /// Drops a trailing `.0` for whole numbers so e.g. `4.0` renders as `4`.
  String _formatValue(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }
}
