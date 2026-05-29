import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/mock_water_station_repository.dart';

void main() {
  const repo = MockWaterStationRepository();

  group('MockWaterStationRepository', () {
    test('getStations returns exactly 100 stations', () async {
      final stations = await repo.getStations();
      expect(stations, hasLength(100));
    });

    test('getStations returns the canonical STN-001..STN-100 ids', () async {
      final stations = await repo.getStations();
      final ids = stations.map((s) => s.id).toSet();
      expect(ids, contains('STN-001'));
      expect(ids, contains('STN-100'));
      // No duplicates.
      expect(ids, hasLength(stations.length));
    });

    test('getStationById returns the matching station (hit)', () async {
      final station = await repo.getStationById('STN-001');
      expect(station, isNotNull);
      expect(station!.id, 'STN-001');
      expect(station.number, 1);
      expect(station.nameAr, isNotEmpty);
    });

    test('getStationById returns null for an unknown id (miss)', () async {
      final station = await repo.getStationById('STN-999');
      expect(station, isNull);
    });

    test('findStations matches by an Arabic substring', () async {
      // Every station name begins with the Arabic word "محطة" (station),
      // so this substring must return all 100 stations.
      final all = await repo.findStations('محطة');
      expect(all, hasLength(100));

      // A water-body substring matches a meaningful subset but not all.
      final tigris = await repo.findStations('نهر دجلة');
      expect(tigris, isNotEmpty);
      expect(tigris.length, lessThan(100));
      expect(
        tigris.every((s) => s.waterBodyAr.contains('نهر دجلة')),
        isTrue,
      );
    });

    test('findStations returns empty for a blank query', () async {
      expect(await repo.findStations(''), isEmpty);
      expect(await repo.findStations('   '), isEmpty);
    });

    test('findStations returns empty for an unmatched substring', () async {
      expect(await repo.findStations('zzz-no-such-station'), isEmpty);
    });

    test(
      'getHistory returns 168 hourly readings for a 7-day window',
      () async {
        // 7-day window, both bounds on the hour. `to` is exclusive, so the
        // expected count is 7 * 24 = 168.
        final from = DateTime(2026, 1, 1);
        final to = from.add(const Duration(days: 7));

        final history = await repo.getHistory(
          stationId: 'STN-001',
          from: from,
          to: to,
          interval: ReadingInterval.hour,
        );

        expect(history, hasLength(7 * 24));
        expect(history.first.stationId, 'STN-001');
        expect(history.first.timestamp, from);
        expect(history.last.timestamp, to.subtract(const Duration(hours: 1)));

        // Readings are ordered and exactly one hour apart.
        for (var i = 1; i < history.length; i++) {
          expect(
            history[i].timestamp.difference(history[i - 1].timestamp),
            const Duration(hours: 1),
          );
        }
      },
    );

    test('getHistory returns empty for an unknown station', () async {
      final from = DateTime(2026, 1, 1);
      final to = from.add(const Duration(days: 7));
      final history = await repo.getHistory(
        stationId: 'STN-999',
        from: from,
        to: to,
      );
      expect(history, isEmpty);
    });

    test('getCurrentLevel returns a CurrentLevel with a status', () async {
      final current = await repo.getCurrentLevel('STN-001');
      expect(current, isA<CurrentLevel>());
      expect(current.current.stationId, 'STN-001');
      expect(current.status, isA<StationStatus>());
      expect(StationStatus.values, contains(current.status));
      expect(current.delta24hM, isA<double>());
    });

    test('rankStations returns <= limit results sorted descending', () async {
      final ranked = await repo.rankStations(limit: 5);
      expect(ranked.length, lessThanOrEqualTo(5));
      expect(ranked, isNotEmpty);
      expect(ranked.first, isA<RankedStation>());

      // Descending by level.
      for (var i = 1; i < ranked.length; i++) {
        expect(
          ranked[i - 1].levelM,
          greaterThanOrEqualTo(ranked[i].levelM),
        );
      }
    });

    test('rankStations ascending order sorts smallest level first', () async {
      final ranked = await repo.rankStations(order: 'asc', limit: 5);
      expect(ranked.length, lessThanOrEqualTo(5));
      for (var i = 1; i < ranked.length; i++) {
        expect(
          ranked[i - 1].levelM,
          lessThanOrEqualTo(ranked[i].levelM),
        );
      }
    });

    test('rankStations honours a larger limit but caps at total', () async {
      final ranked = await repo.rankStations(limit: 1000);
      expect(ranked, hasLength(100));
    });

    test('listAlerts returns a list (mock yields none)', () async {
      final alerts = await repo.listAlerts();
      expect(alerts, isEmpty);
    });

    test('every returned station exposes valid danger thresholds', () async {
      final stations = await repo.getStations();
      for (final Station s in stations) {
        expect(s.dangerHighM, greaterThan(s.dangerLowM));
      }
    });
  });
}
