import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/shared/status_pill.dart';

/// Generative-UI block rendering a [StationListSpec] — a titled, selectable
/// directory of stations.
///
/// Renders the "Generative UI card" recipe (PRD §10.6): a white surface with a
/// 1px [AppColors.line] border, [AppRadius.lg] corners and [AppSpacing.md]
/// padding. Layout is RTL-correct (directional padding/alignment only) and all
/// copy is Arabic.
///
/// Header shows the [StationListSpec.title] plus a count chip
/// ("العدد: {count}"). The body is a bounded (max ~320px), internally
/// scrollable list of station rows. Each row shows:
///  - the station [StationListItem.name] ([AppTextStyles.titleMd]),
///  - the water body + governorate ([AppColors.slate] caption),
///  - a trailing [StatusPill] when [StationListItem.status] is non-null,
///  - a trailing info [IconButton] (north-east arrow) that calls [onOpen] with
///    the station id to open the detail screen.
///
/// Tapping the row itself calls [onAskStation] with the station name so the
/// chat conversation continues about the selected station.
class StationListBlock extends StatelessWidget {
  const StationListBlock({
    super.key,
    required this.spec,
    this.onAskStation,
    this.onOpen,
  });

  /// The parsed block specification to render.
  final StationListSpec spec;

  /// Invoked with the station name when a row is tapped — continues the chat
  /// for that station. Ignored (row non-tappable) when null.
  final void Function(String stationName)? onAskStation;

  /// Invoked with the station id when the trailing open button is tapped — used
  /// to open the station detail screen. Ignored (button hidden) when null.
  final void Function(String stationId)? onOpen;

  /// Upper bound for the internally-scrollable list so the card never grows
  /// unbounded inside the chat message column.
  static const double _maxListHeight = 320;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Header(title: spec.title, count: spec.count),
          const SizedBox(height: AppSpacing.sm),
          if (spec.items.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'لا توجد محطات',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _maxListHeight),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: spec.items.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.line),
                itemBuilder: (context, index) {
                  return _StationRow(
                    item: spec.items[index],
                    onAskStation: onAskStation,
                    onOpen: onOpen,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// The card header: title on the leading side, count chip on the trailing side.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleLg,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _CountChip(count: count),
      ],
    );
  }
}

/// A small mint pill showing the total station count ("العدد: {count}").
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'العدد: $count',
        style: AppTextStyles.caption.copyWith(color: AppColors.tealDark),
      ),
    );
  }
}

/// A single station row. The whole row is tappable (continues the chat about
/// the station via [onAskStation]); a trailing open button drills into the
/// detail screen via [onOpen].
class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.item,
    this.onAskStation,
    this.onOpen,
  });

  final StationListItem item;
  final void Function(String stationName)? onAskStation;
  final void Function(String stationId)? onOpen;

  @override
  Widget build(BuildContext context) {
    final askCb = onAskStation;
    final openCb = onOpen;
    final String? subtitle = _subtitle;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: askCb == null ? null : () => askCb(item.name),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    item.name,
                    style: AppTextStyles.titleMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.slate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (item.status != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              StatusPill(status: item.status!),
            ],
            if (openCb != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xxs),
              IconButton(
                onPressed: () => openCb(item.stationId),
                icon: const Icon(Icons.north_east),
                iconSize: 18,
                color: AppColors.teal,
                tooltip: 'فتح التفاصيل',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Combines water body + governorate into a single caption line, omitting
  /// whichever is missing. Returns null when both are absent.
  String? get _subtitle {
    final parts = <String>[
      if (item.waterBody != null && item.waterBody!.trim().isNotEmpty)
        item.waterBody!.trim(),
      if (item.governorate != null && item.governorate!.trim().isNotEmpty)
        item.governorate!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }
}
