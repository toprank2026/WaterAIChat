import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Tool: `compare_stations` (PRD §11.2).
///
/// Fetches parallel time-series for 2–4 stations over the same window so the
/// model can emit a `multi_line_chart` block. Returns a map keyed by station id
/// to that station's readings. Each station's history is fetched independently
/// via [WaterStationRepository.getHistory]; order of [ids] is preserved in the
/// resulting (insertion-ordered) map.
///
/// Parameters: `station_ids[], from: DateTime, to: DateTime, interval`.
/// Returns: parallel readings keyed by station id.
class CompareStationsTool {
  final WaterStationRepository repo;

  const CompareStationsTool(this.repo);

  /// Tool name as exposed to the model.
  static const String name = 'compare_stations';

  Future<Map<String, List<WaterLevelReading>>> call(
    List<String> ids,
    DateTime from,
    DateTime to, {
    ReadingInterval interval = ReadingInterval.hour,
  }) async {
    final result = <String, List<WaterLevelReading>>{};
    for (final id in ids) {
      result[id] = await repo.getHistory(
        stationId: id,
        from: from,
        to: to,
        interval: interval,
      );
    }
    return result;
  }
}

/// Functional shorthand for [CompareStationsTool.call].
Future<Map<String, List<WaterLevelReading>>> compareStations(
  WaterStationRepository repo,
  List<String> ids,
  DateTime from,
  DateTime to, {
  ReadingInterval interval = ReadingInterval.hour,
}) =>
    CompareStationsTool(repo).call(ids, from, to, interval: interval);
