import 'package:ma_water/data/models/enums.dart';

/// Block specification contract consumed by the genui block widgets and the
/// AI layer. The AI emits JSON matching §11.1 of the PRD; [BlockSpec.fromJson]
/// dispatches on the `type` field to the correct sealed subtype.
///
/// All parsing is defensive: missing/invalid fields fall back to sensible
/// defaults rather than throwing, because the JSON originates from an on-device
/// LLM whose output cannot be fully trusted.
sealed class BlockSpec {
  const BlockSpec();

  /// Dispatches on `json['type']`. Unknown or missing types degrade to a
  /// [SummaryTextSpec] so the chat can always render *something*.
  factory BlockSpec.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'stat_card':
        return StatCardSpec.fromJson(json);
      case 'line_chart':
        return LineChartSpec.fromJson(json);
      case 'multi_line_chart':
        return MultiLineChartSpec.fromJson(json);
      case 'ranked_list':
        return RankedListSpec.fromJson(json);
      case 'station_map':
        return StationMapSpec.fromJson(json);
      case 'alert_card':
        return AlertCardSpec.fromJson(json);
      case 'summary_text':
        return SummaryTextSpec.fromJson(json);
      default:
        return SummaryTextSpec.fromJson(json);
    }
  }
}

// ---------------------------------------------------------------------------
// Helper value classes
// ---------------------------------------------------------------------------

/// A single time-series point: `{"t": iso8601, "v": num}`.
class TimePoint {
  final DateTime t;
  final double v;

  const TimePoint({required this.t, required this.v});

  factory TimePoint.fromJson(Map<String, dynamic> json) {
    return TimePoint(
      t: _parseDate(json['t']),
      v: _parseDouble(json['v']),
    );
  }
}

/// A labelled series for multi-line charts: `{"label": str, "points": [...]}`.
class NamedSeries {
  final String label;
  final List<TimePoint> points;

  const NamedSeries({required this.label, required this.points});

  factory NamedSeries.fromJson(Map<String, dynamic> json) {
    return NamedSeries(
      label: _parseString(json['label']),
      points: _parseTimePoints(json['points']),
    );
  }
}

/// An entry in a ranked list:
/// `{"station_id": str, "name": str, "value": num, "unit": str}`.
class RankedItem {
  final String stationId;
  final String name;
  final double value;
  final String unit;

  const RankedItem({
    required this.stationId,
    required this.name,
    required this.value,
    required this.unit,
  });

  factory RankedItem.fromJson(Map<String, dynamic> json) {
    return RankedItem(
      stationId: _parseString(json['station_id']),
      name: _parseString(json['name']),
      value: _parseDouble(json['value']),
      unit: _parseString(json['unit']),
    );
  }
}

/// A map marker:
/// `{"station_id": str, "lat": num, "lng": num, "status": "normal|warning|danger"}`.
class MapMarker {
  final String stationId;
  final double lat;
  final double lng;
  final StationStatus status;

  const MapMarker({
    required this.stationId,
    required this.lat,
    required this.lng,
    required this.status,
  });

  factory MapMarker.fromJson(Map<String, dynamic> json) {
    return MapMarker(
      stationId: _parseString(json['station_id']),
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      status: _parseStationStatus(json['status']),
    );
  }
}

// ---------------------------------------------------------------------------
// Block subtypes
// ---------------------------------------------------------------------------

/// `stat_card` — a single headline metric with optional delta and status.
class StatCardSpec extends BlockSpec {
  final String title;
  final double value;
  final String unit;
  final String? delta;
  final StationStatus status;
  final String? stationId;

  const StatCardSpec({
    required this.title,
    required this.value,
    required this.unit,
    this.delta,
    required this.status,
    this.stationId,
  });

  factory StatCardSpec.fromJson(Map<String, dynamic> json) {
    return StatCardSpec(
      title: _parseString(json['title']),
      value: _parseDouble(json['value']),
      unit: _parseString(json['unit']),
      delta: _parseNullableString(json['delta']),
      status: _parseStationStatus(json['status']),
      stationId: _parseNullableString(json['station_id']),
    );
  }
}

/// `line_chart` — one series with optional danger thresholds.
class LineChartSpec extends BlockSpec {
  final String title;
  final String? stationId;
  final List<TimePoint> points;
  final double? dangerHigh;
  final double? dangerLow;

  const LineChartSpec({
    required this.title,
    this.stationId,
    required this.points,
    this.dangerHigh,
    this.dangerLow,
  });

  factory LineChartSpec.fromJson(Map<String, dynamic> json) {
    return LineChartSpec(
      title: _parseString(json['title']),
      stationId: _parseNullableString(json['station_id']),
      points: _parseTimePoints(json['points']),
      dangerHigh: _parseNullableDouble(json['danger_high']),
      dangerLow: _parseNullableDouble(json['danger_low']),
    );
  }
}

/// `multi_line_chart` — several labelled series compared on one axis.
class MultiLineChartSpec extends BlockSpec {
  final String title;
  final List<NamedSeries> series;

  const MultiLineChartSpec({
    required this.title,
    required this.series,
  });

  factory MultiLineChartSpec.fromJson(Map<String, dynamic> json) {
    final raw = json['series'];
    final series = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => NamedSeries.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <NamedSeries>[];
    return MultiLineChartSpec(
      title: _parseString(json['title']),
      series: series,
    );
  }
}

/// `ranked_list` — ordered list of stations by some metric.
class RankedListSpec extends BlockSpec {
  final String title;
  final List<RankedItem> items;

  const RankedListSpec({
    required this.title,
    required this.items,
  });

  factory RankedListSpec.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => RankedItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <RankedItem>[];
    return RankedListSpec(
      title: _parseString(json['title']),
      items: items,
    );
  }
}

/// `station_map` — a set of geo markers with status colour.
class StationMapSpec extends BlockSpec {
  final String title;
  final List<MapMarker> markers;

  const StationMapSpec({
    required this.title,
    required this.markers,
  });

  factory StationMapSpec.fromJson(Map<String, dynamic> json) {
    final raw = json['markers'];
    final markers = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => MapMarker.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <MapMarker>[];
    return StationMapSpec(
      title: _parseString(json['title']),
      markers: markers,
    );
  }
}

/// `alert_card` — a severity-coded alert with optional AI commentary.
class AlertCardSpec extends BlockSpec {
  final AlertSeverity severity;
  final String title;
  final String body;
  final String? stationId;
  final String? aiNote;

  const AlertCardSpec({
    required this.severity,
    required this.title,
    required this.body,
    this.stationId,
    this.aiNote,
  });

  factory AlertCardSpec.fromJson(Map<String, dynamic> json) {
    return AlertCardSpec(
      severity: _parseAlertSeverity(json['severity']),
      title: _parseString(json['title']),
      body: _parseString(json['body']),
      stationId: _parseNullableString(json['station_id']),
      aiNote: _parseNullableString(json['ai_note']),
    );
  }
}

/// `summary_text` — plain prose fallback when no structured block fits.
class SummaryTextSpec extends BlockSpec {
  final String text;

  const SummaryTextSpec({required this.text});

  factory SummaryTextSpec.fromJson(Map<String, dynamic> json) {
    return SummaryTextSpec(text: _parseString(json['text']));
  }
}

// ---------------------------------------------------------------------------
// Defensive parsing helpers
// ---------------------------------------------------------------------------

String _parseString(Object? value) {
  if (value is String) return value;
  if (value == null) return '';
  return value.toString();
}

String? _parseNullableString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

double? _parseNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime _parseDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

List<TimePoint> _parseTimePoints(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => TimePoint.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  return <TimePoint>[];
}

StationStatus _parseStationStatus(Object? value) {
  switch (value) {
    case 'normal':
      return StationStatus.normal;
    case 'warning':
      return StationStatus.warning;
    case 'danger':
      return StationStatus.danger;
    default:
      return StationStatus.normal;
  }
}

AlertSeverity _parseAlertSeverity(Object? value) {
  switch (value) {
    case 'info':
      return AlertSeverity.info;
    case 'warning':
      return AlertSeverity.warning;
    case 'critical':
      return AlertSeverity.critical;
    default:
      return AlertSeverity.info;
  }
}
