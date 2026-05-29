import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading.freezed.dart';
part 'reading.g.dart';

/// A single water-level sample for a station at a point in time.
///
/// Wire format (snake_case) is defined in PRD §9.2
/// `GET /stations/{id}/readings`.
@freezed
abstract class WaterLevelReading with _$WaterLevelReading {
  const factory WaterLevelReading({
    @JsonKey(name: 'station_id') required String stationId,
    required DateTime timestamp,
    @JsonKey(name: 'level_m') required double levelM,
  }) = _WaterLevelReading;

  factory WaterLevelReading.fromJson(Map<String, dynamic> json) =>
      _$WaterLevelReadingFromJson(json);
}
