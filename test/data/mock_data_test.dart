import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/mock/mock_readings.dart';
import 'package:ma_water/data/mock/mock_stations.dart';

void main() {
  group('mockStations dataset invariants', () {
    test('contains exactly 100 stations', () {
      expect(mockStations.length, 100);
    });

    test('all ids are unique', () {
      final ids = mockStations.map((s) => s.id).toSet();
      expect(ids.length, mockStations.length);
    });

    test('all ids match /^STN-\\d{3}\$/', () {
      final pattern = RegExp(r'^STN-\d{3}$');
      for (final station in mockStations) {
        expect(
          pattern.hasMatch(station.id),
          isTrue,
          reason: 'id "${station.id}" does not match STN-### format',
        );
      }
    });

    test('latitude within Iraq bounds (28..38)', () {
      for (final station in mockStations) {
        expect(
          station.latitude,
          inInclusiveRange(28, 38),
          reason: '${station.id} latitude ${station.latitude} out of 28..38',
        );
      }
    });

    test('longitude within Iraq bounds (38..49)', () {
      for (final station in mockStations) {
        expect(
          station.longitude,
          inInclusiveRange(38, 49),
          reason: '${station.id} longitude ${station.longitude} out of 38..49',
        );
      }
    });

    test('dangerLowM < baseLevelM < dangerHighM for every station', () {
      for (final station in mockStations) {
        expect(
          station.dangerLowM < station.baseLevelM,
          isTrue,
          reason:
              '${station.id}: dangerLowM (${station.dangerLowM}) >= '
              'baseLevelM (${station.baseLevelM})',
        );
        expect(
          station.baseLevelM < station.dangerHighM,
          isTrue,
          reason:
              '${station.id}: baseLevelM (${station.baseLevelM}) >= '
              'dangerHighM (${station.dangerHighM})',
        );
      }
    });
  });

  group('mock_readings determinism', () {
    test(
      'overlapping windows yield identical levelM for the same timestamp',
      () {
        final station = mockStations.first;

        // Two different but overlapping windows.
        // Window A: 2024-01-01 00:00 .. 2024-01-08 00:00 (7 days)
        // Window B: 2024-01-04 00:00 .. 2024-01-11 00:00 (7 days)
        // Overlap:  2024-01-04 00:00 .. 2024-01-08 00:00
        final windowA = generateReadings(
          station: station,
          from: DateTime(2024, 1, 1),
          to: DateTime(2024, 1, 8),
        );
        final windowB = generateReadings(
          station: station,
          from: DateTime(2024, 1, 4),
          to: DateTime(2024, 1, 11),
        );

        final byTimestampA = <DateTime, WaterLevelReading>{
          for (final r in windowA) r.timestamp: r,
        };
        final byTimestampB = <DateTime, WaterLevelReading>{
          for (final r in windowB) r.timestamp: r,
        };

        final overlap = byTimestampA.keys
            .where(byTimestampB.containsKey)
            .toList();

        // Sanity: the windows must actually overlap.
        expect(
          overlap,
          isNotEmpty,
          reason: 'expected the two windows to share timestamps',
        );

        for (final ts in overlap) {
          expect(
            byTimestampA[ts]!.levelM,
            byTimestampB[ts]!.levelM,
            reason:
                'levelM differs at $ts between overlapping windows '
                '(window-dependent output, not deterministic)',
          );
        }
      },
    );

    test('regenerating the same window reproduces identical readings', () {
      final station = mockStations.first;
      final first = generateReadings(
        station: station,
        from: DateTime(2024, 3, 1),
        to: DateTime(2024, 3, 3),
      );
      final second = generateReadings(
        station: station,
        from: DateTime(2024, 3, 1),
        to: DateTime(2024, 3, 3),
      );

      expect(first.length, second.length);
      for (var i = 0; i < first.length; i++) {
        expect(first[i].timestamp, second[i].timestamp);
        expect(first[i].levelM, second[i].levelM);
        expect(first[i].stationId, second[i].stationId);
      }
    });
  });
}
