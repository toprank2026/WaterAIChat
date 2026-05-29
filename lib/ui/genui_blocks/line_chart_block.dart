import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Renders a [LineChartSpec] as a single-series water-level chart inside a
/// GenUI card. The x-axis is time (timestamp ms), the y-axis is level. Optional
/// [LineChartSpec.dangerHigh] / [LineChartSpec.dangerLow] thresholds are drawn
/// as dashed horizontal lines (danger / warn colours).
///
/// The chart is RTL-aware: it renders inside a [Directionality] of
/// [TextDirection.rtl] so dates/labels read naturally for the Arabic UI, and
/// the line walks from the most recent point (right) back through history.
class LineChartBlock extends StatelessWidget {
  const LineChartBlock({super.key, required this.spec});

  final LineChartSpec spec;

  /// Fixed plot height per the design (~220 including title/padding).
  static const double _chartHeight = 220;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              spec.title,
              style: AppTextStyles.titleMd,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: _chartHeight,
              child: spec.points.isEmpty
                  ? const _EmptyChart()
                  : _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Sort defensively: the AI may emit points out of chronological order.
    final points = List<TimePoint>.from(spec.points)
      ..sort((a, b) => a.t.compareTo(b.t));

    final spots = <FlSpot>[
      for (final p in points)
        FlSpot(p.t.millisecondsSinceEpoch.toDouble(), p.v),
    ];

    final minX = spots.first.x;
    final maxX = spots.last.x;

    final bounds = _yBounds(points);

    // Subtle one-shot draw-in: the line and its area fill grow from the first
    // point to the full series on first build. We interpolate the revealed
    // spots so the curve "writes itself" left-to-right. A single point can't
    // be drawn-in meaningfully, so it skips straight to full.
    if (spots.length < 2) {
      return _chart(spots, minX, maxX, bounds);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return _chart(_revealedSpots(spots, t), minX, maxX, bounds);
      },
    );
  }

  /// Returns the subset of [spots] visible at draw-in progress [t] (0..1),
  /// interpolating the final partial segment so the line grows smoothly rather
  /// than snapping point-to-point.
  static List<FlSpot> _revealedSpots(List<FlSpot> spots, double t) {
    if (t >= 1) return spots;
    if (t <= 0) return <FlSpot>[spots.first];
    final segments = spots.length - 1;
    final scaled = t * segments;
    final whole = scaled.floor();
    final frac = scaled - whole;
    final revealed = <FlSpot>[for (var i = 0; i <= whole; i++) spots[i]];
    if (whole < segments && frac > 0) {
      final a = spots[whole];
      final b = spots[whole + 1];
      revealed.add(
        FlSpot(a.x + (b.x - a.x) * frac, a.y + (b.y - a.y) * frac),
      );
    }
    return revealed;
  }

  Widget _chart(
    List<FlSpot> spots,
    double minX,
    double maxX,
    _YBounds bounds,
  ) {
    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: bounds.min,
        maxY: bounds.max,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: bounds.gridInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.line,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: bounds.gridInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) {
                  // Avoid clipping at the very edges.
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  child: Text(
                    _formatLevel(value),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate,
                    ),
                    textAlign: TextAlign.end,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _xLabelInterval(minX, maxX),
              getTitlesWidget: (value, meta) {
                final date =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    _formatDate(date),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: _thresholdLines(),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date =
                    DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                return LineTooltipItem(
                  '${_formatLevel(spot.y)}\n${_formatDate(date)}',
                  AppTextStyles.caption.copyWith(color: AppColors.card),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            // Gemini-tinted stroke: teal flowing into aqua/blue for a lively,
            // brand-aligned line rather than a flat single colour.
            gradient: const LinearGradient(
              colors: <Color>[
                AppColors.teal,
                AppColors.aqua,
                Color(0xFF4F8CFF),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            // Only show end dots once the draw-in has revealed the full series,
            // and only for sparse series so dense charts stay clean.
            dotData: FlDotData(
              show: spec.points.length <= 12 &&
                  spots.length == spec.points.length,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: AppColors.card,
                strokeWidth: 2,
                strokeColor: AppColors.aqua,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              // Faded gemini-palette wash under the curve for depth.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.geminiColors[2].withValues(alpha: 0.20),
                  AppColors.teal.withValues(alpha: 0.12),
                  AppColors.teal.withValues(alpha: 0.01),
                ],
                stops: const <double>[0.0, 0.45, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dashed threshold lines for danger high / low when present.
  List<HorizontalLine> _thresholdLines() {
    final lines = <HorizontalLine>[];
    final high = spec.dangerHigh;
    if (high != null) {
      lines.add(
        HorizontalLine(
          y: high,
          color: AppColors.danger,
          strokeWidth: 1.5,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            // fl_chart casts this to EdgeInsets at paint time, so it must NOT be
            // EdgeInsetsDirectional (that throws a runtime type-cast error).
            padding: const EdgeInsets.only(
              right: AppSpacing.xs,
              bottom: AppSpacing.xxs,
            ),
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            labelResolver: (_) => 'حد الخطر',
          ),
        ),
      );
    }
    final low = spec.dangerLow;
    if (low != null) {
      lines.add(
        HorizontalLine(
          y: low,
          color: AppColors.warn,
          strokeWidth: 1.5,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.bottomRight,
            // fl_chart casts this to EdgeInsets at paint time, so it must NOT be
            // EdgeInsetsDirectional (that throws a runtime type-cast error).
            padding: const EdgeInsets.only(
              right: AppSpacing.xs,
              top: AppSpacing.xxs,
            ),
            style: AppTextStyles.caption.copyWith(color: AppColors.warn),
            labelResolver: (_) => 'الحد الأدنى',
          ),
        ),
      );
    }
    return lines;
  }

  /// Computes padded y-bounds that also encompass any threshold lines, plus a
  /// sensible grid interval.
  _YBounds _yBounds(List<TimePoint> points) {
    var minV = points.first.v;
    var maxV = points.first.v;
    for (final p in points) {
      if (p.v < minV) minV = p.v;
      if (p.v > maxV) maxV = p.v;
    }
    final high = spec.dangerHigh;
    final low = spec.dangerLow;
    if (high != null) maxV = high > maxV ? high : maxV;
    if (high != null) minV = high < minV ? high : minV;
    if (low != null) maxV = low > maxV ? low : maxV;
    if (low != null) minV = low < minV ? low : minV;

    var range = maxV - minV;
    if (range <= 0) {
      // Flat series: synthesise a small range around the value.
      range = maxV.abs() > 0 ? maxV.abs() * 0.1 : 1;
    }
    final pad = range * 0.12;
    final min = minV - pad;
    final max = maxV + pad;
    final interval = ((max - min) / 4).clamp(0.0001, double.infinity);
    return _YBounds(min: min, max: max, gridInterval: interval.toDouble());
  }

  /// Roughly 4 date labels across the axis.
  double _xLabelInterval(double minX, double maxX) {
    final span = maxX - minX;
    if (span <= 0) return 1;
    return span / 3;
  }

  static String _formatLevel(double v) {
    // One decimal is plenty for water-level metres.
    return v.toStringAsFixed(v.abs() >= 100 ? 0 : 1);
  }

  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd/$mm';
  }
}

/// Padded y-axis bounds plus a grid interval.
class _YBounds {
  const _YBounds({
    required this.min,
    required this.max,
    required this.gridInterval,
  });

  final double min;
  final double max;
  final double gridInterval;
}

/// Friendly placeholder when there is nothing to plot.
class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.show_chart,
            color: AppColors.line,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'لا توجد بيانات لعرضها',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}
