import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/station.dart';

/// The latest reading for a station plus its 24-hour delta and status.
///
/// Derived value object returned by the repository (PRD §9.2
/// `GET /stations/{id}/current`). Not part of the persisted/wire model,
/// so it is a plain immutable class rather than a freezed type.
class CurrentLevel {
  final WaterLevelReading current;
  final double delta24hM;
  final StationStatus status;

  const CurrentLevel({
    required this.current,
    required this.delta24hM,
    required this.status,
  });
}

/// A station paired with a level used for ranking
/// (PRD §9.2 `GET /stations/rank`).
class RankedStation {
  final Station station;
  final double levelM;

  const RankedStation({
    required this.station,
    required this.levelM,
  });
}
