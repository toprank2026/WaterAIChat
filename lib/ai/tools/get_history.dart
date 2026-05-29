import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Tool: `get_history` (PRD §11.2).
///
/// Returns the time-series readings for a station between [from] and [to],
/// sampled at the given [interval]. A thin, pure wrapper over
/// [WaterStationRepository.getHistory].
///
/// Parameters: `station_id: string, from: DateTime, to: DateTime,
/// interval: hour|day`.
/// Returns: readings array.
class GetHistoryTool {
  final WaterStationRepository repo;

  const GetHistoryTool(this.repo);

  /// Tool name as exposed to the model.
  static const String name = 'get_history';

  Future<List<WaterLevelReading>> call(
    String stationId,
    DateTime from,
    DateTime to, {
    ReadingInterval interval = ReadingInterval.hour,
  }) =>
      repo.getHistory(
        stationId: stationId,
        from: from,
        to: to,
        interval: interval,
      );
}

/// Functional shorthand for [GetHistoryTool.call].
Future<List<WaterLevelReading>> getHistory(
  WaterStationRepository repo,
  String stationId,
  DateTime from,
  DateTime to, {
  ReadingInterval interval = ReadingInterval.hour,
}) =>
    repo.getHistory(
      stationId: stationId,
      from: from,
      to: to,
      interval: interval,
    );
