// Tests for [AnomalyService] (PRD §F5 anomaly detection).
//
// These tests drive the service against an in-memory mock repository that
// synthesises hourly readings deterministically. The goal is contract-level:
//  * detectAll() / detectForStation() return a well-typed List<Alert>;
//  * every emitted alert carries a non-empty Arabic message and valid
//    severity/kind values;
//  * a station whose latest reading breaches its danger-high threshold yields
//    at least one alert (so the "any returned alert" assertions are exercised).
//
// The mock keeps the work bounded: each getHistory() call generates at most a
// couple of weeks of hourly samples (~336 readings), which is fast.

import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/ai/anomaly_service.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

void main() {
  group('AnomalyService.detectAll', () {
    test('returns a type-correct List<Alert>', () async {
      final service = AnomalyService(MockWaterStationRepository());
      final alerts = await service.detectAll();

      expect(alerts, isA<List<Alert>>());
      _assertAllAlertsWellFormed(alerts);
    });

    test('flags a station whose latest level breaches danger-high', () async {
      // The breaching station's latest reading sits above its dangerHighM, so a
      // threshold-breach (critical) alert must be produced.
      final service = AnomalyService(MockWaterStationRepository());
      final alerts = await service.detectAll();

      expect(alerts, isNotEmpty,
          reason: 'a breaching station should yield at least one alert');
      _assertAllAlertsWellFormed(alerts);

      final hasThreshold = alerts.any(
        (a) =>
            a.stationId == _breachingStationId &&
            a.kind == AlertKind.threshold &&
            a.severity == AlertSeverity.critical,
      );
      expect(hasThreshold, isTrue,
          reason: 'threshold breach should surface a critical alert');

      // The calm station never breaches its (wide) thresholds, so it must not
      // surface a threshold-breach alert.
      final calmHasThreshold = alerts.any(
        (a) => a.stationId == _calmStationId && a.kind == AlertKind.threshold,
      );
      expect(calmHasThreshold, isFalse,
          reason: 'the calm station should not trip a threshold breach');
    });

    test('runs reasonably fast', () async {
      final service = AnomalyService(MockWaterStationRepository());
      final sw = Stopwatch()..start();
      await service.detectAll();
      sw.stop();

      // Generous bound; the mock is synthetic and should complete near-instantly.
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('AnomalyService.detectForStation', () {
    test('returns a type-correct List<Alert> for a single station', () async {
      final repo = MockWaterStationRepository();
      final service = AnomalyService(repo);
      final station = (await repo.getStations())
          .firstWhere((s) => s.id == _breachingStationId);

      final alerts = await service.detectForStation(station);

      expect(alerts, isA<List<Alert>>());
      expect(alerts, isNotEmpty);
      _assertAllAlertsWellFormed(alerts);
      expect(alerts.every((a) => a.stationId == _breachingStationId), isTrue);
    });

    test('empty-history station yields an empty (still typed) list', () async {
      final repo = MockWaterStationRepository();
      final service = AnomalyService(repo);
      final station = (await repo.getStations())
          .firstWhere((s) => s.id == _emptyStationId);

      final alerts = await service.detectForStation(station);

      expect(alerts, isA<List<Alert>>());
      expect(alerts, isEmpty);
    });
  });
}

const String _breachingStationId = 'ST-001';
const String _calmStationId = 'ST-002';
const String _emptyStationId = 'ST-003';

/// Asserts the invariants the task requires of every emitted alert.
void _assertAllAlertsWellFormed(List<Alert> alerts) {
  for (final a in alerts) {
    expect(a.messageAr.trim(), isNotEmpty,
        reason: 'alert ${a.id} must carry a non-empty Arabic message');
    expect(AlertSeverity.values, contains(a.severity));
    expect(AlertKind.values, contains(a.kind));
    expect(a.stationId.trim(), isNotEmpty);
    expect(a.id.trim(), isNotEmpty);
  }
}

/// In-memory [WaterStationRepository] that synthesises deterministic hourly
/// readings. Only the methods used by [AnomalyService] do real work; the rest
/// throw [UnimplementedError] so accidental use is loud.
class MockWaterStationRepository implements WaterStationRepository {
  static final List<Station> _stations = [
    _station(
      id: _breachingStationId,
      number: 1,
      baseLevel: 5.0,
      dangerHigh: 6.0,
      dangerLow: 2.0,
    ),
    _station(
      id: _calmStationId,
      number: 2,
      baseLevel: 4.0,
      dangerHigh: 8.0,
      dangerLow: 1.0,
    ),
    _station(
      id: _emptyStationId,
      number: 3,
      baseLevel: 3.0,
      dangerHigh: 9.0,
      dangerLow: 0.5,
    ),
  ];

  @override
  Future<List<Station>> getStations() async => List.unmodifiable(_stations);

  @override
  Future<Station?> getStationById(String id) async {
    for (final s in _stations) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<List<WaterLevelReading>> getHistory({
    required String stationId,
    required DateTime from,
    required DateTime to,
    ReadingInterval interval = ReadingInterval.hour,
  }) async {
    // The "empty" station never has data, so detection short-circuits.
    if (stationId == _emptyStationId) return const <WaterLevelReading>[];

    final station = _stations.firstWhere((s) => s.id == stationId);
    final fromUtc = from.toUtc();
    final toUtc = to.toUtc();
    if (!fromUtc.isBefore(toUtc)) return const <WaterLevelReading>[];

    final step = interval == ReadingInterval.day
        ? const Duration(days: 1)
        : const Duration(hours: 1);

    final readings = <WaterLevelReading>[];
    var t = fromUtc;
    var i = 0;
    // Hard cap to keep synthetic generation bounded regardless of range.
    const maxSamples = 24 * 30;
    while (t.isBefore(toUtc) && i < maxSamples) {
      readings.add(WaterLevelReading(
        stationId: stationId,
        timestamp: t,
        levelM: _level(station, i),
      ));
      t = t.add(step);
      i++;
    }
    return readings;
  }

  /// Deterministic synthetic level for sample index [i].
  ///
  /// The calm station hovers near its base level with mild oscillation. The
  /// breaching station starts near base and ramps above its danger-high so its
  /// latest reading trips the threshold rule.
  double _level(Station s, int i) {
    final wobble = 0.05 * ((i % 7) - 3); // small deterministic noise
    if (s.id == _breachingStationId) {
      // Ramp upward by ~0.01 m/hour; over ~14 days (336h) this climbs ~3.36 m
      // on top of the base 5.0 → comfortably above dangerHigh (6.0).
      return s.baseLevelM + i * 0.01 + wobble;
    }
    return s.baseLevelM + wobble;
  }

  @override
  Future<List<RankedStation>> rankStations({
    String by = 'level',
    String order = 'desc',
    int limit = 5,
    DateTime? at,
  }) =>
      throw UnimplementedError();

  @override
  Future<CurrentLevel> getCurrentLevel(String stationId) =>
      throw UnimplementedError();

  @override
  Future<List<Station>> findStations(String query) =>
      throw UnimplementedError();

  @override
  Future<List<Alert>> listAlerts({bool activeOnly = true}) =>
      throw UnimplementedError();
}

Station _station({
  required String id,
  required int number,
  required double baseLevel,
  required double dangerHigh,
  required double dangerLow,
}) {
  return Station(
    id: id,
    number: number,
    nameAr: 'محطة $number',
    nameEn: 'Station $number',
    waterBodyAr: 'دجلة',
    waterBodyEn: 'Tigris',
    bodyType: WaterBodyType.river,
    governorateAr: 'بغداد',
    governorateEn: 'Baghdad',
    latitude: 33.3 + number * 0.01,
    longitude: 44.4 + number * 0.01,
    baseLevelM: baseLevel,
    dangerHighM: dangerHigh,
    dangerLowM: dangerLow,
    installedAt: DateTime.utc(2020, 1, 1),
    isActive: true,
  );
}
