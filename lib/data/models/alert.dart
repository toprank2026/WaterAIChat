import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:ma_water/data/models/enums.dart';

part 'alert.freezed.dart';
part 'alert.g.dart';

/// An open alert raised against a station.
///
/// Wire format (snake_case) is defined in PRD §9.2 `GET /alerts`.
@freezed
abstract class Alert with _$Alert {
  const factory Alert({
    required String id,
    @JsonKey(name: 'station_id') required String stationId,
    required AlertSeverity severity,
    required AlertKind kind,
    @JsonKey(name: 'message_ar') required String messageAr,
    @JsonKey(name: 'detected_at') required DateTime detectedAt,
    @JsonKey(name: 'trigger_value') required double triggerValue,
  }) = _Alert;

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
}
