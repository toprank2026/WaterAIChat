import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Tool: `list_alerts` (PRD §11.2).
///
/// Returns alerts across the fleet. When [activeOnly] is `true` (the default),
/// only currently active alerts are returned. A thin, pure wrapper over
/// [WaterStationRepository.listAlerts].
///
/// Parameters: `active: bool (default true)`.
/// Returns: alerts array.
class ListAlertsTool {
  final WaterStationRepository repo;

  const ListAlertsTool(this.repo);

  /// Tool name as exposed to the model.
  static const String name = 'list_alerts';

  Future<List<Alert>> call({bool activeOnly = true}) =>
      repo.listAlerts(activeOnly: activeOnly);
}

/// Functional shorthand for [ListAlertsTool.call].
Future<List<Alert>> listAlerts(
  WaterStationRepository repo, {
  bool activeOnly = true,
}) =>
    repo.listAlerts(activeOnly: activeOnly);
