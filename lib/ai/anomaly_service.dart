import 'dart:math' as math;

import 'package:ma_water/core/utils/date_utils.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Runs the three anomaly-detection rules from PRD §F5 across station readings
/// and produces [Alert]s with Arabic messages.
///
/// Rules:
///  1. **Sudden change** — the magnitude of the most recent 6-hour level change
///     exceeds `3 × σ`, where `σ` is the standard deviation of the 6-hour
///     deltas observed over a recent ~14-day window. Maps to
///     [AlertSeverity.warning], escalating to [AlertSeverity.critical] when the
///     resulting level also breaches a danger threshold.
///  2. **Threshold breach** — the latest level is above `dangerHigh` or below
///     `dangerLow`. Always [AlertSeverity.critical].
///  3. **Trend deviation** — the mean of a recent 7-day window diverges from the
///     mean of the same calendar week one year earlier by more than 15%. Maps
///     to [AlertSeverity.info], escalating to [AlertSeverity.warning] beyond
///     [_trendWarnRatio].
///
/// All timestamps on emitted alerts are UTC. Alert ids are generated as
/// `ALR-<n>` with a monotonically increasing counter per [detectAll] /
/// [detectForStation] run.
class AnomalyService {
  AnomalyService(this.repo);

  final WaterStationRepository repo;

  /// Lookback window (days) used for the sudden-change std-dev baseline and the
  /// threshold check. ~14 days of hourly readings is enough to characterise the
  /// noise floor without scanning the full year.
  static const int _lookbackDays = 14;

  /// Recent window length (days) for the trend-deviation moving average.
  static const int _trendWindowDays = 7;

  /// Sudden-change trigger: |Δ6h| must exceed this multiple of the std-dev.
  static const double _suddenSigma = 3.0;

  /// Trend deviation must exceed this fraction (15%) to flag at all.
  static const double _trendInfoRatio = 0.15;

  /// Above this fraction (25%) the trend deviation escalates to a warning.
  static const double _trendWarnRatio = 0.25;

  /// Cap on the number of stations processed by [detectAll].
  ///
  /// Each station triggers a ~14-day hourly history fetch plus two 7-day fetches
  /// for the trend rule. Processing all ~100 stations on every app open would be
  /// wasteful for a proactive scan, so [detectAll] caps the heavy work to the
  /// first [_maxStations] *active* stations (ordered by [Station.number]). This
  /// keeps the open-time scan bounded while still surfacing alerts across a
  /// representative slice of the fleet. On-demand, per-station detection via
  /// [detectForStation] is never capped.
  static const int _maxStations = 30;

  /// Detects anomalies across (a bounded slice of) all active stations.
  ///
  /// Stations are processed in ascending [Station.number] order and the scan is
  /// capped at [_maxStations] active stations to keep the proactive open-time
  /// run fast (see [_maxStations]). Returns all alerts found, ordered by
  /// severity (critical first) then detection time (newest first).
  Future<List<Alert>> detectAll() async {
    final stations = await repo.getStations();
    final active = stations.where((s) => s.isActive).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final scanned =
        active.length > _maxStations ? active.sublist(0, _maxStations) : active;

    final counter = _AlertIdCounter();
    final alerts = <Alert>[];
    for (final station in scanned) {
      alerts.addAll(await _detect(station, counter));
    }

    _sortBySeverityThenTime(alerts);
    return alerts;
  }

  /// Detects anomalies for a single [station]. Never capped.
  Future<List<Alert>> detectForStation(Station s) async {
    final counter = _AlertIdCounter();
    final alerts = await _detect(s, counter);
    _sortBySeverityThenTime(alerts);
    return alerts;
  }

  /// Runs all three rules for one station, appending alert ids from [counter].
  Future<List<Alert>> _detect(Station station, _AlertIdCounter counter) async {
    final now = nowUtc();
    final from = startOfHour(now.subtract(const Duration(days: _lookbackDays)));
    final to = startOfHour(now);

    final readings = await repo.getHistory(
      stationId: station.id,
      from: from,
      to: to,
    );
    if (readings.isEmpty) return <Alert>[];

    // Repositories are expected to return chronological data, but sort
    // defensively so the delta / latest computations are correct regardless.
    final sorted = List<WaterLevelReading>.of(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final alerts = <Alert>[];

    final threshold = _checkThreshold(station, sorted, counter);
    if (threshold != null) alerts.add(threshold);

    final sudden = _checkSuddenChange(station, sorted, counter);
    if (sudden != null) alerts.add(sudden);

    final trend = await _checkTrendDeviation(station, sorted, counter);
    if (trend != null) alerts.add(trend);

    return alerts;
  }

  // --- Rule 2: threshold breach -------------------------------------------

  Alert? _checkThreshold(
    Station station,
    List<WaterLevelReading> sorted,
    _AlertIdCounter counter,
  ) {
    final latest = sorted.last;
    final level = latest.levelM;
    if (level > station.dangerHighM) {
      return Alert(
        id: counter.next(),
        stationId: station.id,
        severity: AlertSeverity.critical,
        kind: AlertKind.threshold,
        messageAr: 'تجاوز حد الخطر الأعلى في ${station.nameAr} — '
            'المستوى ${_fmt(level)} م يفوق الحد ${_fmt(station.dangerHighM)} م.',
        detectedAt: latest.timestamp.toUtc(),
        triggerValue: _round(level),
      );
    }
    if (level < station.dangerLowM) {
      return Alert(
        id: counter.next(),
        stationId: station.id,
        severity: AlertSeverity.critical,
        kind: AlertKind.threshold,
        messageAr: 'انخفاض دون حد الخطر الأدنى في ${station.nameAr} — '
            'المستوى ${_fmt(level)} م أقل من الحد ${_fmt(station.dangerLowM)} م.',
        detectedAt: latest.timestamp.toUtc(),
        triggerValue: _round(level),
      );
    }
    return null;
  }

  // --- Rule 1: sudden change ----------------------------------------------

  Alert? _checkSuddenChange(
    Station station,
    List<WaterLevelReading> sorted,
    _AlertIdCounter counter,
  ) {
    // Need at least 7 hourly samples to form one 6-hour delta plus a baseline.
    if (sorted.length < 7) return null;

    // Build the series of 6-hour deltas across the window.
    final deltas = <double>[];
    for (var i = 6; i < sorted.length; i++) {
      deltas.add(sorted[i].levelM - sorted[i - 6].levelM);
    }
    if (deltas.length < 2) return null;

    final std = _stdDev(deltas);
    // A flat/synthetic series can yield ~0 std; nothing meaningful to flag.
    if (std <= 0) return null;

    final latest = sorted.last;
    final recentDelta = latest.levelM - sorted[sorted.length - 7].levelM;
    if (recentDelta.abs() <= _suddenSigma * std) return null;

    final level = latest.levelM;
    final breaches =
        level > station.dangerHighM || level < station.dangerLowM;
    final severity =
        breaches ? AlertSeverity.critical : AlertSeverity.warning;

    final direction = recentDelta >= 0 ? 'ارتفاع' : 'انخفاض';
    return Alert(
      id: counter.next(),
      stationId: station.id,
      severity: severity,
      kind: AlertKind.suddenChange,
      messageAr: '$direction متسارع لمستوى الماء في ${station.nameAr} — '
          'تغيّر ${_fmt(recentDelta.abs())} م خلال 6 ساعات.',
      detectedAt: latest.timestamp.toUtc(),
      triggerValue: _round(recentDelta),
    );
  }

  // --- Rule 3: trend deviation --------------------------------------------

  Future<Alert?> _checkTrendDeviation(
    Station station,
    List<WaterLevelReading> recentWindow,
    _AlertIdCounter counter,
  ) async {
    final now = nowUtc();
    final recentFrom =
        startOfHour(now.subtract(const Duration(days: _trendWindowDays)));
    final recentTo = startOfHour(now);

    // Reuse the already-fetched window for the recent mean (it spans the last
    // ~14 days, which covers the recent 7-day window) to avoid a redundant
    // fetch.
    final recentMean = _meanInRange(recentWindow, recentFrom, recentTo);
    if (recentMean == null) return null;

    // Same calendar week, one year earlier.
    final priorFrom = _shiftBackOneYear(recentFrom);
    final priorTo = _shiftBackOneYear(recentTo);
    final priorReadings = await repo.getHistory(
      stationId: station.id,
      from: priorFrom,
      to: priorTo,
    );
    if (priorReadings.isEmpty) return null;

    final priorMean = _meanInRange(priorReadings, priorFrom, priorTo);
    if (priorMean == null || priorMean == 0) return null;

    final ratio = (recentMean - priorMean).abs() / priorMean.abs();
    if (ratio <= _trendInfoRatio) return null;

    final severity =
        ratio > _trendWarnRatio ? AlertSeverity.warning : AlertSeverity.info;
    final pct = (ratio * 100).round();
    final direction = recentMean >= priorMean ? 'أعلى' : 'أدنى';

    return Alert(
      id: counter.next(),
      stationId: station.id,
      severity: severity,
      kind: AlertKind.trendDeviation,
      messageAr: 'انحراف في الاتجاه الموسمي لـ${station.nameAr} — '
          'المعدل الأسبوعي $direction بنسبة %$pct مقارنةً بالعام الماضي.',
      detectedAt: now,
      triggerValue: _round(recentMean),
    );
  }

  // --- helpers -------------------------------------------------------------

  /// Mean level of readings whose timestamp falls within `[from, to)`.
  /// Returns `null` when no reading falls in the range.
  double? _meanInRange(
    List<WaterLevelReading> readings,
    DateTime from,
    DateTime to,
  ) {
    var sum = 0.0;
    var count = 0;
    for (final r in readings) {
      final t = r.timestamp.toUtc();
      if (!t.isBefore(from) && t.isBefore(to)) {
        sum += r.levelM;
        count++;
      }
    }
    if (count == 0) return null;
    return sum / count;
  }

  /// Population standard deviation of [values].
  double _stdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    var variance = 0.0;
    for (final v in values) {
      final d = v - mean;
      variance += d * d;
    }
    variance /= values.length;
    return math.sqrt(variance);
  }

  /// Shifts [t] back by one calendar year, keeping it UTC. Falls back to the
  /// preceding valid day when the target date does not exist (e.g. Feb 29).
  DateTime _shiftBackOneYear(DateTime t) {
    final u = t.toUtc();
    final year = u.year - 1;
    final lastDay = _daysInMonth(year, u.month);
    final day = u.day > lastDay ? lastDay : u.day;
    return DateTime.utc(year, u.month, day, u.hour, u.minute);
  }

  int _daysInMonth(int year, int month) {
    final firstOfNext =
        month == 12 ? DateTime.utc(year + 1, 1, 1) : DateTime.utc(year, month + 1, 1);
    return firstOfNext.subtract(const Duration(days: 1)).day;
  }

  void _sortBySeverityThenTime(List<Alert> alerts) {
    alerts.sort((a, b) {
      final s = _severityRank(b.severity).compareTo(_severityRank(a.severity));
      if (s != 0) return s;
      return b.detectedAt.compareTo(a.detectedAt);
    });
  }

  int _severityRank(AlertSeverity s) => switch (s) {
        AlertSeverity.critical => 2,
        AlertSeverity.warning => 1,
        AlertSeverity.info => 0,
      };

  /// Rounds to 3 decimals to match the precision of mock readings (PRD §8.3).
  double _round(double v) => double.parse(v.toStringAsFixed(3));

  /// Formats a level for Arabic messages (2 decimals).
  String _fmt(double v) => v.toStringAsFixed(2);
}

/// Generates sequential `ALR-<n>` ids within a single detection run.
class _AlertIdCounter {
  int _n = 0;
  String next() => 'ALR-${++_n}';
}
