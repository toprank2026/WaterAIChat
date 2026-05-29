import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Verifies that [BlockSpec.fromJson] dispatches the `statistics` block to a
/// [StatisticsSpec] and parses its title, station id, and list of [StatItem]s
/// (labels, values, units, and optional status). The JSON shape is copied from
/// the STATISTICS BLOCK pinned contract.
void main() {
  group('BlockSpec.fromJson statistics -> StatisticsSpec', () {
    test('parses title, station_id and 4 stats with correct values/labels', () {
      final json = <String, dynamic>{
        'type': 'statistics',
        'title': 'إحصائيات سد الموصل (آخر 30 يوماً)',
        'station_id': 'STN-047',
        'stats': <Map<String, dynamic>>[
          {'label': 'الحالي', 'value': 321.2, 'unit': 'م', 'status': 'normal'},
          {'label': 'الأعلى', 'value': 325.1, 'unit': 'م'},
          {'label': 'الأدنى', 'value': 318.0, 'unit': 'م'},
          {'label': 'المتوسط', 'value': 321.4, 'unit': 'م'},
        ],
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<StatisticsSpec>());
      final stats = spec as StatisticsSpec;
      expect(stats.title, 'إحصائيات سد الموصل (آخر 30 يوماً)');
      expect(stats.stationId, 'STN-047');
      expect(stats.stats, hasLength(4));

      final current = stats.stats[0];
      expect(current.label, 'الحالي');
      expect(current.value, 321.2);
      expect(current.unit, 'م');
      expect(current.status, StationStatus.normal);

      final highest = stats.stats[1];
      expect(highest.label, 'الأعلى');
      expect(highest.value, 325.1);
      expect(highest.unit, 'م');
      expect(highest.status, isNull);

      final lowest = stats.stats[2];
      expect(lowest.label, 'الأدنى');
      expect(lowest.value, 318.0);
      expect(lowest.status, isNull);

      final average = stats.stats[3];
      expect(average.label, 'المتوسط');
      expect(average.value, 321.4);
      expect(average.status, isNull);
    });

    test('missing stats degrades to an empty list, not a throw', () {
      final spec = BlockSpec.fromJson(<String, dynamic>{
        'type': 'statistics',
        'title': 'بدون بيانات',
      });

      expect(spec, isA<StatisticsSpec>());
      final stats = spec as StatisticsSpec;
      expect(stats.title, 'بدون بيانات');
      expect(stats.stationId, isNull);
      expect(stats.stats, isEmpty);
    });

    test('unknown status string on a stat parses to null', () {
      final spec = BlockSpec.fromJson(<String, dynamic>{
        'type': 'statistics',
        'title': 'حالة غير معروفة',
        'stats': <Map<String, dynamic>>[
          {'label': 'الحالي', 'value': 10.0, 'unit': 'م', 'status': 'bogus'},
        ],
      });

      final stats = spec as StatisticsSpec;
      expect(stats.stats, hasLength(1));
      expect(stats.stats.first.status, isNull);
    });
  });
}
