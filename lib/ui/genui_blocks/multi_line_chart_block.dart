import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// GenUI block rendering a [MultiLineChartSpec]: 2–4 labelled time series drawn
/// on a single axis with an fl_chart line chart, plus a flat legend row.
///
/// Figma look: a flat white hairline card. The chart is monochrome — the
/// primary series is solid ink over a single low-alpha pastel (lilac) fill, and
/// additional series are distinguished by grayscale tone + dash pattern (weight
/// and rhythm, not hue, carry the difference). The legend mirrors each series
/// with a small flat swatch + label.
class MultiLineChartBlock extends StatelessWidget {
  const MultiLineChartBlock({super.key, required this.spec});

  final MultiLineChartSpec spec;

  /// Monochrome series tones. Index 0 is full ink; later series step down to
  /// slate so overlapping lines stay legible without introducing hues.
  static const List<Color> _palette = <Color>[
    AppColors.ink,
    AppColors.slate,
    AppColors.slate,
    AppColors.ink,
  ];

  /// Dash pattern per series (null = solid). Combined with [_palette] this gives
  /// four readable, distinct strokes in a strictly monochrome system.
  static const List<List<int>?> _dashes = <List<int>?>[
    null, // solid ink
    null, // solid slate
    <int>[6, 4], // dashed slate
    <int>[2, 4], // dotted ink
  ];

  Color _colorFor(int index) => _palette[index % _palette.length];

  List<int>? _dashFor(int index) => _dashes[index % _dashes.length];

  @override
  Widget build(BuildContext context) {
    // Only keep series that actually have points so the chart bounds stay sane.
    final series =
        spec.series.where((s) => s.points.isNotEmpty).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mono uppercase eyebrow taxonomy label above the title.
          Text(
            'MULTI-SERIES',
            style: AppTextStyles.eyebrow,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            spec.title,
            style: AppTextStyles.titleLg,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (series.isEmpty)
            _EmptyState()
          else ...[
            SizedBox(
              height: 240,
              // Light one-shot draw-in: all series grow together from their
              // first sample to full on first build.
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => _buildChart(series, t),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Legend(
              labels: [for (final s in series) s.label],
              colorFor: _colorFor,
              dashFor: _dashFor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(List<NamedSeries> series, double reveal) {
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
      final allSpots = <FlSpot>[
        for (final p in series[i].points)
          FlSpot(p.t.millisecondsSinceEpoch.toDouble(), p.v),
      ];
      final dash = _dashFor(i);
      bars.add(
        LineChartBarData(
          spots: _revealedSpots(allSpots, reveal),
          isCurved: true,
          curveSmoothness: 0.25,
          // Flat monochrome stroke; tone + dash distinguish the series.
          color: _colorFor(i),
          dashArray: dash,
          barWidth: i == 0 ? 2.5 : 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          // ONE pastel block: only the primary (ink) series carries a single
          // low-alpha lilac wash so the lead line reads first; later series
          // stay clean lines so overlapping data does not muddy.
          belowBarData: BarAreaData(
            show: i == 0,
            color: AppColors.blockLilac.withValues(alpha: 0.22),
          ),
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
            color: AppColors.hairline,
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
                // Plain EdgeInsets only — fl_chart crashes on directional insets.
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
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
                  AppTextStyles.caption.copyWith(color: AppColors.canvas),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the subset of [spots] visible at draw-in progress [t] (0..1),
  /// interpolating the final partial segment so each series grows smoothly.
  static List<FlSpot> _revealedSpots(List<FlSpot> spots, double t) {
    if (t >= 1 || spots.length < 2) return spots;
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

/// Wrapping row of flat legend chips, one per series.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.labels,
    required this.colorFor,
    required this.dashFor,
  });

  final List<String> labels;
  final Color Function(int index) colorFor;
  final List<int>? Function(int index) dashFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < labels.length; i++)
          _LegendChip(
            color: colorFor(i),
            dash: dashFor(i),
            label: labels[i],
          ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.dash,
    required this.label,
  });

  final Color color;
  final List<int>? dash;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Flat white hairline pill with a small monochrome swatch echoing the
    // series stroke (solid or dashed) — no gradients, no shadow.
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
        AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 8,
            child: CustomPaint(
              painter: _SwatchPainter(color: color, dash: dash),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// Draws a short horizontal stroke (solid or dashed) matching a series.
class _SwatchPainter extends CustomPainter {
  const _SwatchPainter({required this.color, required this.dash});

  final Color color;
  final List<int>? dash;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;
    final d = dash;
    if (d == null || d.isEmpty) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    // Walk the dash pattern across the swatch width.
    var x = 0.0;
    var di = 0;
    var draw = true;
    while (x < size.width) {
      final len = d[di % d.length].toDouble();
      final next = (x + len).clamp(0.0, size.width);
      if (draw) {
        canvas.drawLine(Offset(x, y), Offset(next, y), paint);
      }
      x = next;
      draw = !draw;
      di++;
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.color != color || old.dash != dash;
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
              color: AppColors.ink,
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
