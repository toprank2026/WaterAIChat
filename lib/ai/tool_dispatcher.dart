import 'package:ma_water/ai/tools/compare_stations.dart';
import 'package:ma_water/ai/tools/find_station.dart';
import 'package:ma_water/ai/tools/get_current_level.dart';
import 'package:ma_water/ai/tools/get_history.dart';
import 'package:ma_water/ai/tools/list_alerts.dart';
import 'package:ma_water/ai/tools/rank_stations.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Routes parsed tool calls (PRD §11.2) to the [WaterStationRepository].
///
/// Each method maps one of the six Gemma-facing tools to the corresponding
/// repository operation, delegating through the thin wrappers in
/// `lib/ai/tools/`. The dispatcher is intentionally free of any model/JSON
/// parsing concerns — it operates purely on typed Dart arguments and results so
/// it stays testable and decoupled from the inference layer.
class ToolDispatcher {
  final WaterStationRepository repo;

  ToolDispatcher(this.repo);

  /// `find_station` — resolve free text to matching stations.
  Future<List<Station>> findStation(String query) =>
      FindStationTool(repo).call(query);

  /// `get_current_level` — latest reading + 24h delta + status.
  Future<CurrentLevel> getCurrentLevel(String stationId) =>
      GetCurrentLevelTool(repo).call(stationId);

  /// `get_history` — time-series readings for one station.
  Future<List<WaterLevelReading>> getHistory(
    String stationId,
    DateTime from,
    DateTime to, {
    ReadingInterval interval = ReadingInterval.hour,
  }) =>
      GetHistoryTool(repo).call(stationId, from, to, interval: interval);

  /// `compare_stations` — parallel histories keyed by station id.
  ///
  /// Builds a map id -> readings by calling [getHistory] per id, preserving the
  /// order of [ids] in the resulting insertion-ordered map.
  Future<Map<String, List<WaterLevelReading>>> compareStations(
    List<String> ids,
    DateTime from,
    DateTime to, {
    ReadingInterval interval = ReadingInterval.hour,
  }) =>
      CompareStationsTool(repo).call(ids, from, to, interval: interval);

  /// `rank_stations` — top/bottom N stations by a metric.
  Future<List<RankedStation>> rankStations({
    String by = 'level',
    String order = 'desc',
    int limit = 5,
    DateTime? at,
  }) =>
      RankStationsTool(repo)
          .call(by: by, order: order, limit: limit, at: at);

  /// `list_alerts` — open alerts across the fleet.
  Future<List<Alert>> listAlerts({bool activeOnly = true}) =>
      ListAlertsTool(repo).call(activeOnly: activeOnly);
}
