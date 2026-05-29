import 'package:json_annotation/json_annotation.dart';

/// Type of water body a station monitors.
///
/// Serializes to the snake_case strings used by the §9 API
/// (`river` | `dam` | `lake` | `tributary`).
enum WaterBodyType {
  @JsonValue('river')
  river,
  @JsonValue('dam')
  dam,
  @JsonValue('lake')
  lake,
  @JsonValue('tributary')
  tributary,
}

/// Severity of an alert.
///
/// Serializes as `info` | `warning` | `critical`.
enum AlertSeverity {
  @JsonValue('info')
  info,
  @JsonValue('warning')
  warning,
  @JsonValue('critical')
  critical,
}

/// What triggered an alert.
///
/// Serializes as snake_case (`sudden_change` | `threshold` | `trend_deviation`).
enum AlertKind {
  @JsonValue('sudden_change')
  suddenChange,
  @JsonValue('threshold')
  threshold,
  @JsonValue('trend_deviation')
  trendDeviation,
}

/// Sampling interval for time-series readings.
///
/// Serializes as `hour` | `day`.
enum ReadingInterval {
  @JsonValue('hour')
  hour,
  @JsonValue('day')
  day,
}

/// Operational status of a station relative to its danger thresholds.
///
/// Serializes as `normal` | `warning` | `danger`.
enum StationStatus {
  @JsonValue('normal')
  normal,
  @JsonValue('warning')
  warning,
  @JsonValue('danger')
  danger,
}
