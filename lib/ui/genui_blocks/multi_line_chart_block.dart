import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// GenUI block rendering a [MultiLineChartSpec]: 2–4 labelled time series drawn
/// on a single axis with an fl_chart line chart, plus a legend row of colored
/// chips. Each series is assigned a distinct color from a small palette
/// (teal, aqua, warn, danger).
class MultiLineChartBlock extends StatelessWidget {
  const MultiLineChartBlock({super.key, required this.spec});

  final MultiLineChartSpec spec;

  /// Small distinct palette; index wraps if more series than colors arrive.
  static const List<Color> _palette = <Color>[
    AppColors.teal,
    AppColors.aqua,
    AppColors.warn,
    AppColors.danger,
  ];

  Color _colorFor(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
    // Only keep series that actually have points so the chart bounds stay sane.
    final series =
        spec.series.where((s) => s.points.isNotEmpty).toList(growable: false);

    return Container(
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
          ),
          const SizedBox(height: AppSpacing.sm),
          if (series.isEmpty)
            _EmptyState()
          else ...[
            SizedBox(
              height: 240,
              child: _buildChart(series),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Legend(
              labels: [for (final s in series) s.label],
              colorFor: _colorFor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(List<NamedSeries> series) {
    // Compute shared axis bounds across all series.
    double? minX, maxX, minY, maxY;
    for (final s in series) {
      for (final p in s.points) {
        final x = p.t.millisecondsSinceEpoch.toDouble();
        final y = p.v;
        minX = (minX == null || x < minX) ? x : minX;
        maxX = (maxX == null || x > maxX) ? x : maxX;
        minY = (minY == null || y < minY) ? y : minY;
        maxY = (maxY == null || y > maxY) ? y : maxY;
      }
    }

    minX ??= 0;
    maxX ??= 1;
    minY ??= 0;
    maxY ??= 1;

    // Guard against a flat/degenerate range so gridlines and labels render.
    if (maxX == minX) maxX = minX + 1;
    final span = maxY - minY;
    final pad = span == 0 ? (maxY.abs() == 0 ? 1.0 : maxY.abs() * 0.1) : span * 0.1;
    final chartMinY = minY - pad;
    final chartMaxY = maxY + pad;
    final yInterval = ((chartMaxY - chartMinY) / 4).abs();

    final bars = <LineChartBarData>[];
    for (var i = 0; i < series.length; i++) {
      final color = _colorFor(i);
      bars.add(
        LineChartBarData(
          spots: [
            for (final p in series[i].points)
              FlSpot(p.t.millisecondsSinceEpoch.toDouble(), p.v),
          ],
          isCurved: true,
          curveSmoothness: 0.25,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: chartMinY,
        maxY: chartMaxY,
        lineBarsData: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval == 0 ? null : yInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.line,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: yInterval == 0 ? null : yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xxs),
                  child: Text(
                    _formatY(value),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (maxX - minX) <= 0 ? null : (maxX - minX) / 2,
              getTitlesWidget: (value, meta) {
                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    _formatX(dt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  _formatY(s.y),
                  AppTextStyles.caption.copyWith(color: AppColors.card),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatY(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  static String _formatX(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Wrapping row of colored legend chips, one per series.
class _Legend extends StatelessWidget {
  const _Legend({required this.labels, required this.colorFor});

  final List<String> labels;
  final Color Function(int index) colorFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < labels.length; i++)
          _LegendChip(color: colorFor(i), label: labels[i]),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
        ),
      ],
    );
  }
}

/// Shown when no series carries any points.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.show_chart,
              color: AppColors.slate,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'لا توجد بيانات لعرضها',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}
