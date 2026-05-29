import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/genui_blocks/line_chart_block.dart';

/// Regression test for the fl_chart `HorizontalLineLabel.padding` crash:
/// passing EdgeInsetsDirectional there threw "type 'EdgeInsetsDirectional' is
/// not a subtype of type 'EdgeInsets' in type cast" at paint time. This renders
/// the chart WITH danger lines (the crashing path) and asserts it paints clean.
void main() {
  testWidgets('LineChartBlock paints with danger lines without throwing',
      (tester) async {
    final base = DateTime.utc(2026, 5, 1);
    final spec = LineChartSpec(
      title: 'مستوى الماء — اختبار',
      stationId: 'STN-001',
      points: List<TimePoint>.generate(
        24,
        (i) => TimePoint(t: base.add(Duration(hours: i)), v: 318.0 + i % 5),
      ),
      dangerHigh: 330.0,
      dangerLow: 300.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 320,
              child: LineChartBlock(spec: spec),
            ),
          ),
        ),
      ),
    );
    // Let the one-shot draw-in animation advance and force a paint.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
