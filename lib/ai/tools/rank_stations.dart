import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Tool: `rank_stations` (PRD §11.2).
///
/// Returns the top/bottom N stations ranked by a metric. A thin, pure wrapper
/// over [WaterStationRepository.rankStations].
///
/// Parameters: `by: string (default 'level'), order: 'asc'|'desc'
/// (default 'desc'), limit: int (default 5), at: DateTime? (default latest)`.
/// Returns: ranked list.
class RankStationsTool {
  final WaterStationRepository repo;

  const RankStationsTool(this.repo);

  /// Tool name as exposed to the model.
  static const String name = 'rank_stations';

  Future<List<RankedStation>> call({
    String by = 'level',
    String order = 'desc',
    int limit = 5,
    DateTime? at,
  }) =>
      repo.rankStations(by: by, order: order, limit: limit, at: at);
}

/// Functional shorthand for [RankStationsTool.call].
Future<List<RankedStation>> rankStations(
  WaterStationRepository repo, {
  String by = 'level',
  String order = 'desc',
  int limit = 5,
  DateTime? at,
}) =>
    repo.rankStations(by: by, order: order, limit: limit, at: at);
