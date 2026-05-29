import 'package:flutter/material.dart';
import 'package:ma_water/ui/genui_blocks/alert_card_block.dart';
import 'package:ma_water/ui/genui_blocks/block_renderer.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/genui_blocks/line_chart_block.dart';
import 'package:ma_water/ui/genui_blocks/multi_line_chart_block.dart';
import 'package:ma_water/ui/genui_blocks/ranked_list_block.dart';
import 'package:ma_water/ui/genui_blocks/stat_card_block.dart';
import 'package:ma_water/ui/genui_blocks/station_list_block.dart';
import 'package:ma_water/ui/genui_blocks/station_map_block.dart';
import 'package:ma_water/ui/genui_blocks/statistics_block.dart';
import 'package:ma_water/ui/genui_blocks/summary_text_block.dart';

/// Single integration seam for Generative UI block rendering.
///
/// This registry intentionally isolates the (future) `genui` package
/// integration behind one thin façade. Per PRD §15 and CLAUDE.md, `genui` is a
/// pre-1.0 dependency with expected API churn; keeping the spec → widget
/// mapping in exactly one place means a version bump (or a swap of the
/// underlying rendering engine) stays localized to this file and
/// [BlockRenderer], never leaking into the chat list or AI layer.
///
/// All eight block widgets are referenced here so the registry is the
/// authoritative list of renderable block types.
class GenUiRegistry {
  GenUiRegistry._();

  /// Builds the Flutter widget for a parsed [BlockSpec].
  ///
  /// [onTapStation] is forwarded to station-aware blocks so the caller can open
  /// the station-detail screen when the user taps a station inside a block.
  ///
  /// [onAskStation] is forwarded to the station-list block so the caller can
  /// continue the chat about the station the user selects (by its name).
  static Widget build(
    BlockSpec spec, {
    void Function(String stationId)? onTapStation,
    void Function(String stationName)? onAskStation,
  }) {
    return BlockRenderer(
      spec: spec,
      onTapStation: onTapStation,
      onAskStation: onAskStation,
    );
  }
}

/// The complete set of block widgets routed through this registry. Referenced
/// here purely to document the registry's coverage and keep the imports live:
/// [StatCardBlock], [StatisticsBlock], [LineChartBlock], [MultiLineChartBlock],
/// [RankedListBlock], [StationListBlock], [StationMapBlock], [AlertCardBlock],
/// [SummaryTextBlock].
const List<Type> kRegisteredBlockWidgets = <Type>[
  StatCardBlock,
  StatisticsBlock,
  LineChartBlock,
  MultiLineChartBlock,
  RankedListBlock,
  StationListBlock,
  StationMapBlock,
  AlertCardBlock,
  SummaryTextBlock,
];
