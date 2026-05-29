import 'package:ma_water/data/mock/mock_readings.dart';
import 'package:ma_water/data/mock/mock_stations.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// In-memory [WaterStationRepository] backed by the deterministic mock dataset
/// (`mockStations` / `mockStationsById`) and the synthetic reading generator
/// (`generateReadings` / `levelAt`).
///
/// Every method is asynchronous to match the contract; synchronous results are
/// wrapped with [Future.value].
class MockWaterStationRepository implements WaterStationRepository {
  const MockWaterStationRepository();

  @override
  Future<List<Station>> getStations() => Future.value(mockStations);

  @override
  Future<Station?> getStationById(String id) =>
      Future.value(mockStationsById[id]);

  @override
  Future<List<Station>> findStations(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return Future.value(<Station>[]);
    }
    final matches = mockStations.where((s) {
      return s.nameAr.toLowerCase().contains(q) ||
          s.nameEn.toLowerCase().contains(q) ||
          s.waterBodyAr.toLowerCase().contains(q) ||
          s.governorateAr.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q);
    }).toList();
    return Future.value(matches);
  }

  @override
  Future<List<WaterLevelReading>> getHistory({
    required String stationId,
    required DateTime from,
    required DateTime to,
    ReadingInterval interval = ReadingInterval.hour,
  }) {
    final station = mockStationsById[stationId];
    if (station == null) {
      return Future.value(<WaterLevelReading>[]);
    }

    final hourly = generateReadings(station: station, from: from, to: to);
    if (interval == ReadingInterval.hour) {
      return Future.value(hourly);
    }

    // Downsample to one reading per day, taking the midday (hour == 12) sample
    // where present, otherwise the first reading seen for that day.
    final byDay = <DateTime, WaterLevelReading>{};
    for (final r in hourly) {
      final dayKey = DateTime(
        r.timestamp.year,
        r.timestamp.month,
        r.timestamp.day,
      );
      final existing = byDay[dayKey];
      if (existing == null) {
        byDay[dayKey] = r;
      } else if (r.timestamp.hour == 12 && existing.timestamp.hour != 12) {
        byDay[dayKey] = r;
      }
    }
    final daily = byDay.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Future.value(daily);
  }

  @override
  Future<CurrentLevel> getCurrentLevel(String stationId) {
    final station = mockStationsById[stationId];
    if (station == null) {
      throw StateError('Unknown station: $stationId');
    }

    final now = DateTime.now();
    final nowHour = _startOfHour(now);
    final currentLevel = levelAt(station, nowHour);
    final prevLevel = levelAt(station, nowHour.subtract(const Duration(hours: 24)));
    final delta = double.parse((currentLevel - prevLevel).toStringAsFixed(3));

    final reading = WaterLevelReading(
      stationId: station.id,
      timestamp: nowHour,
      levelM: currentLevel,
    );

    return Future.value(
      CurrentLevel(
        current: reading,
        delta24hM: delta,
        status: _statusFor(station, currentLevel),
      ),
    );
  }

  @override
  Future<List<RankedStation>> rankStations({
    String by = 'level',
    String order = 'desc',
    int limit = 5,
    DateTime? at,
  }) {
    final when = _startOfHour(at ?? DateTime.now());
    final ranked = mockStations
        .map((s) => RankedStation(station: s, levelM: levelAt(s, when)))
        .toList();

    // Only 'level' is supported; any other key falls back to level ordering.
    final ascending = order.toLowerCase() == 'asc';
    ranked.sort((a, b) {
      final cmp = a.levelM.compareTo(b.levelM);
      return ascending ? cmp : -cmp;
    });

    final capped = limit < 0 ? 0 : limit;
    final result = ranked.take(capped).toList();
    return Future.value(result);
  }

  @override
  Future<List<Alert>> listAlerts({bool activeOnly = true}) {
    // The mock repository is not the source of alerts. Alerts are produced by
    // AnomalyService (PRD §8/§9), which consumes readings from this repository.
    // Returning an empty list keeps the contract satisfied without duplicating
    // that logic here.
    return Future.value(<Alert>[]);
  }

  /// Truncates [t] to the top of its hour.
  DateTime _startOfHour(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour);

  /// Derives a [StationStatus] from a level relative to the station's danger
  /// thresholds.
  ///
  /// Rule:
  /// - `danger`  when level > dangerHighM, or level < dangerLowM.
  /// - `warning` when level sits within the top 10% of the safe band below
  ///   the high threshold (i.e. >= dangerHighM - 0.1 * band).
  /// - `normal`  otherwise.
  StationStatus _statusFor(Station station, double level) {
    if (level > station.dangerHighM || level < station.dangerLowM) {
      return StationStatus.danger;
    }
    final band = station.dangerHighM - station.dangerLowM;
    final warningFloor = station.dangerHighM - (band * 0.1);
    if (level >= warningFloor) {
      return StationStatus.warning;
    }
    return StationStatus.normal;
  }
}
