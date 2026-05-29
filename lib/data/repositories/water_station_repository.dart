import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';

/// Contract for accessing Iraq water-level station data.
///
/// Implementations may be backed by a mock data source, a local cache, or a
/// remote API. All methods are asynchronous and return immutable model types
/// defined under `lib/data/models/`.
abstract interface class WaterStationRepository {
  /// Returns all known stations.
  Future<List<Station>> getStations();

  /// Returns the station with the given [id], or `null` if none exists.
  Future<Station?> getStationById(String id);

  /// Returns stations matching a free-text [query] (e.g. name, governorate,
  /// or water body), in Arabic or English.
  Future<List<Station>> findStations(String query);

  /// Returns the level readings for [stationId] between [from] and [to],
  /// sampled at the given [interval].
  Future<List<WaterLevelReading>> getHistory({
    required String stationId,
    required DateTime from,
    required DateTime to,
    ReadingInterval interval = ReadingInterval.hour,
  });

  /// Returns the latest level for [stationId], including the 24-hour delta and
  /// derived status.
  Future<CurrentLevel> getCurrentLevel(String stationId);

  /// Returns stations ranked by [by] (e.g. `'level'`) in [order]
  /// (`'asc'` or `'desc'`), limited to [limit] results, evaluated at [at]
  /// (defaults to the latest available time when `null`).
  Future<List<RankedStation>> rankStations({
    String by = 'level',
    String order = 'desc',
    int limit = 5,
    DateTime? at,
  });

  /// Returns alerts. When [activeOnly] is `true`, only currently active alerts
  /// are returned.
  Future<List<Alert>> listAlerts({bool activeOnly = true});
}
