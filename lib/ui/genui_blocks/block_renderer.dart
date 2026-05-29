import 'package:flutter/material.dart';
import 'package:ma_water/ui/genui_blocks/alert_card_block.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/genui_blocks/line_chart_block.dart';
import 'package:ma_water/ui/genui_blocks/multi_line_chart_block.dart';
import 'package:ma_water/ui/genui_blocks/ranked_list_block.dart';
import 'package:ma_water/ui/genui_blocks/stat_card_block.dart';
import 'package:ma_water/ui/genui_blocks/station_map_block.dart';
import 'package:ma_water/ui/genui_blocks/statistics_block.dart';
import 'package:ma_water/ui/genui_blocks/summary_text_block.dart';

/// The single mapping point from a [BlockSpec] (the AI's structured output)
/// to its concrete Flutter widget. The chat message list renders every
/// assistant block through this widget.
///
/// Station-aware blocks (stat card, alert, ranked list, map) forward taps
/// through [onTapStation] so the caller can open the station-detail screen.
/// Blocks that have no station context (charts, summary text) ignore it.
class BlockRenderer extends StatelessWidget {
  final BlockSpec spec;

  /// Invoked with a `stationId` when the user taps a station inside a block.
  final void Function(String stationId)? onTapStation;

  const BlockRenderer({
    super.key,
    required this.spec,
    this.onTapStation,
  });

  @override
  Widget build(BuildContext context) {
    final spec = this.spec;
    switch (spec) {
      case StatCardSpec():
        return StatCardBlock(spec: spec, onTap: _stationTap(spec.stationId));
      case StatisticsSpec():
        return StatisticsBlock(spec: spec, onTap: onTapStation);
      case LineChartSpec():
        return LineChartBlock(spec: spec);
      case MultiLineChartSpec():
        return MultiLineChartBlock(spec: spec);
      case RankedListSpec():
        return RankedListBlock(spec: spec, onTapStation: onTapStation);
      case StationMapSpec():
        return StationMapBlock(spec: spec, onTapMarker: onTapStation);
      case AlertCardSpec():
        return AlertCardBlock(spec: spec, onTap: _stationTap(spec.stationId));
      case SummaryTextSpec():
        return SummaryTextBlock(spec: spec);
    }
  }

  /// Builds a zero-arg tap handler for blocks whose station context is a single
  /// id (stat card, alert card). Returns null when there's no callback or no
  /// station to open, so the underlying widget renders as non-tappable.
  VoidCallback? _stationTap(String? stationId) {
    final cb = onTapStation;
    if (cb == null || stationId == null) return null;
    return () => cb(stationId);
  }
}
