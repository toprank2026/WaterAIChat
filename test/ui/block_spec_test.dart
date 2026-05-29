import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Verifies that [BlockSpec.fromJson] dispatches each PRD §11.1 block example to
/// the correct sealed subtype and parses its fields. The JSON shapes below are
/// copied verbatim from §11.1 of `docs/PRD.md`.
void main() {
  group('BlockSpec.fromJson dispatch + parsing (PRD §11.1)', () {
    test('stat_card -> StatCardSpec with value, unit, delta, status', () {
      final json = <String, dynamic>{
        'type': 'stat_card',
        'title': 'محطة سد الموصل',
        'value': 319.84,
        'unit': 'م',
        'delta': '+0.42 م خلال 24 ساعة',
        'status': 'normal',
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<StatCardSpec>());
      final stat = spec as StatCardSpec;
      expect(stat.title, 'محطة سد الموصل');
      expect(stat.value, 319.84);
      expect(stat.unit, 'م');
      expect(stat.delta, '+0.42 م خلال 24 ساعة');
      expect(stat.status, StationStatus.normal);
      expect(stat.stationId, isNull);
    });

    test('line_chart -> LineChartSpec with points + danger lines', () {
      final json = <String, dynamic>{
        'type': 'line_chart',
        'title': 'مستوى الماء — سد الموصل (آخر 7 أيام)',
        'station_id': 'STN-001',
        'points': <Map<String, dynamic>>[
          {'t': '2026-05-22T00:00:00Z', 'v': 318.4},
        ],
        'danger_high': 330.0,
        'danger_low': 300.0,
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<LineChartSpec>());
      final chart = spec as LineChartSpec;
      expect(chart.title, 'مستوى الماء — سد الموصل (آخر 7 أيام)');
      expect(chart.stationId, 'STN-001');
      expect(chart.points, hasLength(1));
      expect(chart.points.first.v, 318.4);
      expect(
        chart.points.first.t,
        DateTime.utc(2026, 5, 22, 0, 0, 0),
      );
      expect(chart.dangerHigh, 330.0);
      expect(chart.dangerLow, 300.0);
    });

    test('multi_line_chart -> MultiLineChartSpec with series count', () {
      final json = <String, dynamic>{
        'type': 'multi_line_chart',
        'title': 'مقارنة سد الموصل وسد حديثة',
        'series': <Map<String, dynamic>>[
          {'label': 'سد الموصل', 'points': <dynamic>[]},
          {'label': 'سد حديثة', 'points': <dynamic>[]},
        ],
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<MultiLineChartSpec>());
      final multi = spec as MultiLineChartSpec;
      expect(multi.title, 'مقارنة سد الموصل وسد حديثة');
      expect(multi.series, hasLength(2));
      expect(multi.series[0].label, 'سد الموصل');
      expect(multi.series[1].label, 'سد حديثة');
      expect(multi.series[0].points, isEmpty);
      expect(multi.series[1].points, isEmpty);
    });

    test('ranked_list -> RankedListSpec with items', () {
      final json = <String, dynamic>{
        'type': 'ranked_list',
        'title': 'أعلى 5 محطات اليوم',
        'items': <Map<String, dynamic>>[
          {
            'station_id': 'STN-001',
            'name': 'سد الموصل',
            'value': 319.84,
            'unit': 'م',
          },
        ],
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<RankedListSpec>());
      final ranked = spec as RankedListSpec;
      expect(ranked.title, 'أعلى 5 محطات اليوم');
      expect(ranked.items, hasLength(1));
      final item = ranked.items.first;
      expect(item.stationId, 'STN-001');
      expect(item.name, 'سد الموصل');
      expect(item.value, 319.84);
      expect(item.unit, 'م');
    });

    test('station_map -> StationMapSpec with markers', () {
      final json = <String, dynamic>{
        'type': 'station_map',
        'title': 'حالة المحطات',
        'markers': <Map<String, dynamic>>[
          {
            'station_id': 'STN-001',
            'lat': 36.6307,
            'lng': 42.8233,
            'status': 'normal',
          },
        ],
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<StationMapSpec>());
      final map = spec as StationMapSpec;
      expect(map.title, 'حالة المحطات');
      expect(map.markers, hasLength(1));
      final marker = map.markers.first;
      expect(marker.stationId, 'STN-001');
      expect(marker.lat, 36.6307);
      expect(marker.lng, 42.8233);
      expect(marker.status, StationStatus.normal);
    });

    test('alert_card -> AlertCardSpec with severity', () {
      final json = <String, dynamic>{
        'type': 'alert_card',
        'severity': 'warning',
        'title': 'ارتفاع متسارع — بغداد الجادرية',
        'body': 'احتمال تجاوز حد التحذير خلال 4 ساعات.',
        'station_id': 'STN-018',
        'ai_note': 'النمط يطابق موجة موسمية من العام الماضي.',
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<AlertCardSpec>());
      final alert = spec as AlertCardSpec;
      expect(alert.severity, AlertSeverity.warning);
      expect(alert.title, 'ارتفاع متسارع — بغداد الجادرية');
      expect(alert.body, 'احتمال تجاوز حد التحذير خلال 4 ساعات.');
      expect(alert.stationId, 'STN-018');
      expect(alert.aiNote, 'النمط يطابق موجة موسمية من العام الماضي.');
    });

    test('summary_text -> SummaryTextSpec with text', () {
      final json = <String, dynamic>{
        'type': 'summary_text',
        'text': 'ملخص نصي بسيط.',
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<SummaryTextSpec>());
      expect((spec as SummaryTextSpec).text, 'ملخص نصي بسيط.');
    });

    test('unknown/missing type degrades to SummaryTextSpec', () {
      expect(
        BlockSpec.fromJson(<String, dynamic>{'type': 'totally_unknown'}),
        isA<SummaryTextSpec>(),
      );
      expect(
        BlockSpec.fromJson(<String, dynamic>{}),
        isA<SummaryTextSpec>(),
      );
    });
  });
}
