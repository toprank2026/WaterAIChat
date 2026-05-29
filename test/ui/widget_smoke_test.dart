import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/genui_blocks/ranked_list_block.dart';
import 'package:ma_water/ui/genui_blocks/stat_card_block.dart';
import 'package:ma_water/ui/genui_blocks/summary_text_block.dart';

/// Wraps [child] in the minimal app scaffolding the GenUI blocks expect: a
/// [MaterialApp] (for theme/Material ancestors) forced to RTL via an explicit
/// [Directionality]. The app itself is `ar_IQ`/RTL, so tests must mirror that
/// so directional widgets resolve correctly.
Widget _host(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  group('GenUI block smoke tests', () {
    testWidgets('StatCardBlock renders title, value and status without throwing',
        (WidgetTester tester) async {
      const spec = StatCardSpec(
        title: 'منسوب نهر دجلة',
        value: 319.84,
        unit: 'م',
        delta: '+0.42 م',
        status: StationStatus.danger,
        stationId: 'st-001',
      );

      await tester.pumpWidget(_host(const StatCardBlock(spec: spec)));

      // The widget tree built and laid out with no exceptions.
      expect(tester.takeException(), isNull);
      expect(find.byType(StatCardBlock), findsOneWidget);

      // Arabic title and the danger status pill label are visible.
      expect(find.textContaining('منسوب نهر دجلة'), findsOneWidget);
      expect(find.textContaining('خطر'), findsOneWidget);
    });

    testWidgets('SummaryTextBlock renders its Arabic prose without throwing',
        (WidgetTester tester) async {
      const spec = SummaryTextSpec(
        text: 'مستويات المياه ضمن المعدل الطبيعي اليوم.',
      );

      await tester.pumpWidget(_host(const SummaryTextBlock(spec: spec)));

      expect(tester.takeException(), isNull);
      expect(find.byType(SummaryTextBlock), findsOneWidget);
      expect(
        find.textContaining('ضمن المعدل الطبيعي'),
        findsOneWidget,
      );
    });

    testWidgets('RankedListBlock renders title and items without throwing',
        (WidgetTester tester) async {
      const spec = RankedListSpec(
        title: 'أعلى المحطات منسوباً',
        items: <RankedItem>[
          RankedItem(
            stationId: 'st-001',
            name: 'سد الموصل',
            value: 4.0,
            unit: 'م',
          ),
          RankedItem(
            stationId: 'st-002',
            name: 'سد حديثة',
            value: 3.2,
            unit: 'م',
          ),
        ],
      );

      await tester.pumpWidget(_host(const RankedListBlock(spec: spec)));

      expect(tester.takeException(), isNull);
      expect(find.byType(RankedListBlock), findsOneWidget);
      expect(find.textContaining('أعلى المحطات'), findsOneWidget);
      expect(find.textContaining('سد الموصل'), findsOneWidget);
      expect(find.textContaining('سد حديثة'), findsOneWidget);
    });

    testWidgets('RankedListBlock renders the empty-state fallback gracefully',
        (WidgetTester tester) async {
      const spec = RankedListSpec(
        title: 'قائمة فارغة',
        items: <RankedItem>[],
      );

      await tester.pumpWidget(_host(const RankedListBlock(spec: spec)));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('لا توجد بيانات'), findsOneWidget);
    });
  });
}
