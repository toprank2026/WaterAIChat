/// Mapping helpers between the Phase 2 Laravel JSON wire format (PRD §9.2)
/// and the app's domain models.
///
/// These functions translate a single decoded JSON object (a `Map`) into a
/// model. Envelope unwrapping (`{"data": [...]}` etc.) is the caller's job —
/// see `ApiWaterStationRepository`. JSON keys are snake_case per PRD §9.2.
///
/// The freezed models already carry `@JsonKey` annotations matching the wire
/// format, so most mappers delegate to the generated `fromJson` factories.
/// The exceptions are objects whose wire shape differs from the model
/// (readings omit `station_id`; `current` nests its reading and adds derived
/// fields).
library;

import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';

/// Maps a `GET /stations` item (PRD §9.2) to a [Station].
///
/// The wire object already matches [Station]'s `@JsonKey` mapping, so this
/// delegates to the generated factory.
Station stationFromApi(Map<String, dynamic> json) => Station.fromJson(json);

/// Maps a `GET /stations/{id}/readings` data item (PRD §9.2) to a
/// [WaterLevelReading].
///
/// The readings envelope carries `station_id` once at the top level, so each
/// data item is just `{ "timestamp": ..., "level_m": ... }`. The owning
/// [stationId] is therefore supplied by the caller rather than read from
/// [json]. Timestamps are ISO 8601 UTC.
WaterLevelReading readingFromApi(
  Map<String, dynamic> json, {
  required String stationId,
}) {
  return WaterLevelReading(
    stationId: stationId,
    timestamp: _parseUtc(json['timestamp'] as String),
    levelM: _toDouble(json['level_m']),
  );
}

/// Maps a `GET /alerts` data item (PRD §9.2) to an [Alert].
///
/// The wire object already matches [Alert]'s `@JsonKey` mapping (including the
/// snake_case `kind` values via the enum's `@JsonValue`s), so this delegates to
/// the generated factory.
Alert alertFromApi(Map<String, dynamic> json) => Alert.fromJson(json);

/// Maps a `GET /stations/{id}/current` response body (PRD §9.2) to a
/// [CurrentLevel].
///
/// Shape:
/// ```json
/// {
///   "station_id": "STN-001",
///   "current": { "timestamp": "...", "level_m": 319.84 },
///   "delta_24h_m": 0.42,
///   "status": "normal"
/// }
/// ```
CurrentLevel currentFromApi(Map<String, dynamic> json) {
  final stationId = json['station_id'] as String;
  final current = json['current'] as Map<String, dynamic>;
  return CurrentLevel(
    current: readingFromApi(current, stationId: stationId),
    delta24hM: _toDouble(json['delta_24h_m']),
    status: _statusFromApi(json['status'] as String),
  );
}

/// Maps the `status` string from `GET /stations/{id}/current` (PRD §9.2)
/// to a [StationStatus]. Wire values are `normal` | `warning` | `danger`.
StationStatus _statusFromApi(String raw) {
  switch (raw) {
    case 'normal':
      return StationStatus.normal;
    case 'warning':
      return StationStatus.warning;
    case 'danger':
      return StationStatus.danger;
    default:
      throw FormatException('Unknown station status: "$raw"');
  }
}

/// Parses an ISO 8601 timestamp and normalizes it to UTC.
///
/// All API timestamps are documented as ISO 8601 UTC (PRD §9.1); this guards
/// against a parser that yields a local `DateTime` for offset-less input.
DateTime _parseUtc(String iso) => DateTime.parse(iso).toUtc();

/// Coerces a JSON number (which may decode as `int` or `double`) to a `double`.
double _toDouble(Object? value) => (value as num).toDouble();
