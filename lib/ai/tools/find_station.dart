import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Tool: `find_station` (PRD §11.2).
///
/// Resolves a free-text [query] (Arabic or English name, governorate, or water
/// body) to matching [Station]s. A thin, pure wrapper over
/// [WaterStationRepository.findStations] used by the [ToolDispatcher] and by
/// future Gemma tool-calling.
///
/// Parameters: `query: string`.
/// Returns: matched stations.
class FindStationTool {
  final WaterStationRepository repo;

  const FindStationTool(this.repo);

  /// Tool name as exposed to the model.
  static const String name = 'find_station';

  Future<List<Station>> call(String query) => repo.findStations(query);
}

/// Functional shorthand for [FindStationTool.call].
Future<List<Station>> findStation(
  WaterStationRepository repo,
  String query,
) =>
    repo.findStations(query);
