import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Tool: `get_current_level` (PRD §11.2).
///
/// Returns the latest reading for a station plus its 24-hour delta and derived
/// status, as a [CurrentLevel]. A thin, pure wrapper over
/// [WaterStationRepository.getCurrentLevel].
///
/// Parameters: `station_id: string`.
/// Returns: latest reading + delta + status.
class GetCurrentLevelTool {
  final WaterStationRepository repo;

  const GetCurrentLevelTool(this.repo);

  /// Tool name as exposed to the model.
  static const String name = 'get_current_level';

  Future<CurrentLevel> call(String stationId) =>
      repo.getCurrentLevel(stationId);
}

/// Functional shorthand for [GetCurrentLevelTool.call].
Future<CurrentLevel> getCurrentLevel(
  WaterStationRepository repo,
  String stationId,
) =>
    repo.getCurrentLevel(stationId);
