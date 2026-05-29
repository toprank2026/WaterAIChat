import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// The trustworthy **data layer** for the Gemini engine.
///
/// Gemini decides *which* block to render and *which* stations/parameters are
/// involved, but it never invents numbers. [BlockBuilder] takes those resolved
/// intents and fetches the real data through the [ToolDispatcher], assembling a
/// [BlockSpec] directly (never round-tripped through JSON).
///
/// The data -> block logic here mirrors [HeuristicInferenceService] so both
/// engines render identical, consistent cards.
class BlockBuilder {
  final ToolDispatcher tools;

  BlockBuilder(this.tools);

  /// The Arabic unit symbol for meters.
  static const String _unitAr = 'م';

  // --------------------------------------------------------------------------
  // Station resolution
  // --------------------------------------------------------------------------

  /// Resolves a free-text [query] to the single best-matching [Station], or
  /// `null` when nothing matches.
  ///
  /// Preference order: an exact normalized Arabic-name match, then a unique
  /// name that contains the query, then the first match.
  Future<Station?> resolve(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final matches = await tools.findStation(trimmed);
    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;

    final q = _normalize(trimmed);
    for (final s in matches) {
      if (_normalize(s.nameAr) == q) return s;
    }

    final containing =
        matches.where((s) => _normalize(s.nameAr).contains(q)).toList();
    if (containing.length == 1) return containing.first;

    // Ambiguous but non-empty: fall back to the first match so the engine can
    // still render something rather than silently dropping the request.
    return matches.first;
  }

  // --------------------------------------------------------------------------
  // Block builders
  // --------------------------------------------------------------------------

  /// Builds a [StatCardSpec] with the latest level, 24h delta and status for [s].
  Future<BlockSpec> currentLevel(Station s) async {
    final CurrentLevel level = await tools.getCurrentLevel(s.id);
    return StatCardSpec(
      title: s.nameAr,
      value: level.current.levelM,
      unit: _unitAr,
      delta: '${formatDelta(level.delta24hM)} خلال 24 ساعة',
      status: level.status,
      stationId: s.id,
    );
  }

  /// Builds a [LineChartSpec] of [s] over [window]. Uses a daily sampling
  /// interval for windows of a month or longer, hourly otherwise.
  Future<BlockSpec> history(Station s, Duration window, String labelAr) async {
    final to = DateTime.now().toUtc();
    final from = to.subtract(window);
    final interval =
        window.inDays >= 30 ? ReadingInterval.day : ReadingInterval.hour;
    final readings = await tools.getHistory(
      s.id,
      from,
      to,
      interval: interval,
    );

    return LineChartSpec(
      title: 'مستوى الماء — ${s.nameAr} ($labelAr)',
      stationId: s.id,
      points: _toPoints(readings),
      dangerHigh: s.dangerHighM,
      dangerLow: s.dangerLowM,
    );
  }

  /// Builds a [StatisticsSpec] for [s] over [window]: current (last reading),
  /// highest, lowest and average level. Uses a daily sampling interval for
  /// windows of a month or longer, hourly otherwise. The current value carries a
  /// status derived from the station's thresholds; the aggregates omit status.
  ///
  /// [labelAr] is an Arabic window label embedded in the title (e.g. "آخر 30
  /// يوماً"). Returns a [SummaryTextSpec] when no readings are available.
  Future<BlockSpec> statistics(
      Station s, Duration window, String labelAr) async {
    final to = DateTime.now().toUtc();
    final from = to.subtract(window);
    final interval =
        window.inDays >= 30 ? ReadingInterval.day : ReadingInterval.hour;
    final readings = await tools.getHistory(
      s.id,
      from,
      to,
      interval: interval,
    );

    final stats = computeStats(s, readings);
    if (stats == null) {
      return SummaryTextSpec(
        text: 'لا تتوفر بيانات كافية لحساب إحصائيات ${s.nameAr} خلال $labelAr.',
      );
    }

    return StatisticsSpec(
      title: 'إحصائيات ${s.nameAr} ($labelAr)',
      stationId: s.id,
      stats: stats,
    );
  }

  /// Computes the four summary [StatItem]s (current/highest/lowest/average) from
  /// [readings] for station [s], or `null` when [readings] is empty.
  ///
  /// Shared by both engines so the heuristic and Gemini paths produce identical
  /// statistics cards. Only the current (latest) value carries a threshold
  /// status; the aggregates intentionally omit it.
  static List<StatItem>? computeStats(
      Station s, List<WaterLevelReading> readings) {
    if (readings.isEmpty) return null;

    final values = readings.map((r) => r.levelM).toList();
    final current = values.last;
    var max = values.first;
    var min = values.first;
    var sum = 0.0;
    for (final v in values) {
      if (v > max) max = v;
      if (v < min) min = v;
      sum += v;
    }
    final avg = sum / values.length;

    return <StatItem>[
      StatItem(
        label: 'الحالي',
        value: current,
        unit: _unitAr,
        status: statusFromThresholds(s, current),
      ),
      StatItem(label: 'الأعلى', value: max, unit: _unitAr),
      StatItem(label: 'الأدنى', value: min, unit: _unitAr),
      StatItem(label: 'المتوسط', value: avg, unit: _unitAr),
    ];
  }

  /// Builds a [MultiLineChartSpec] comparing the stations [s] over [window].
  Future<BlockSpec> compare(List<Station> s, Duration window) async {
    final to = DateTime.now().toUtc();
    final from = to.subtract(window);
    final ids = s.map((station) => station.id).toList();
    final Map<String, List<WaterLevelReading>> data =
        await tools.compareStations(ids, from, to);

    final byId = {for (final station in s) station.id: station};
    final series = <NamedSeries>[];
    for (final id in ids) {
      final station = byId[id];
      series.add(NamedSeries(
        label: station?.nameAr ?? id,
        points: _toPoints(data[id] ?? const <WaterLevelReading>[]),
      ));
    }

    final names = s.map((station) => station.nameAr).join(' و');
    return MultiLineChartSpec(title: 'مقارنة $names', series: series);
  }

  /// Builds a [RankedListSpec] of the top/bottom [count] stations by level.
  /// [order] is `'desc'` (highest first) or `'asc'` (lowest first).
  Future<BlockSpec> rank({required int count, required String order}) async {
    final normalizedOrder = order == 'asc' ? 'asc' : 'desc';
    final limit = count > 0 ? count : 5;

    final List<RankedStation> ranked = await tools.rankStations(
      by: 'level',
      order: normalizedOrder,
      limit: limit,
    );

    final qualifier = normalizedOrder == 'asc' ? 'أدنى' : 'أعلى';
    final items = ranked
        .map((r) => RankedItem(
              stationId: r.station.id,
              name: r.station.nameAr,
              value: r.levelM,
              unit: _unitAr,
            ))
        .toList();

    return RankedListSpec(
      title: '$qualifier $limit محطات',
      items: items,
    );
  }

  /// Builds a [StationMapSpec] with a marker per station (status from its base
  /// level relative to thresholds).
  Future<BlockSpec> map() async {
    final stations = await tools.findStation('');
    final all = stations.isNotEmpty ? stations : await tools.repo.getStations();
    final markers = all
        .map((s) => MapMarker(
              stationId: s.id,
              lat: s.latitude,
              lng: s.longitude,
              status: statusFromThresholds(s, s.baseLevelM),
            ))
        .toList();
    return StationMapSpec(title: 'حالة المحطات', markers: markers);
  }

  /// Builds an [AlertCardSpec] for the most severe active alert, or a
  /// [SummaryTextSpec] when there are none.
  Future<BlockSpec> alerts() async {
    final List<Alert> alerts = await tools.listAlerts(activeOnly: true);
    if (alerts.isEmpty) {
      return const SummaryTextSpec(
        text: 'لا توجد تنبيهات نشطة حالياً. جميع المحطات ضمن المعدلات الطبيعية.',
      );
    }

    final alert = _mostSevere(alerts);
    return AlertCardSpec(
      severity: alert.severity,
      title: _alertTitle(alert),
      body: alert.messageAr,
      stationId: alert.stationId,
    );
  }

  // --------------------------------------------------------------------------
  // Text fallbacks
  // --------------------------------------------------------------------------

  /// Asks the user to specify a station when one could not be resolved.
  SummaryTextSpec clarify() {
    return const SummaryTextSpec(
      text: 'لم أتعرّف على المحطة المقصودة. هلّا حددت اسم المحطة بدقة؟ '
          'مثال: "سد الموصل" أو "بغداد - الجادرية".',
    );
  }

  /// Helpful Arabic guidance listing example questions, for greetings/unknowns.
  SummaryTextSpec guidance() {
    return const SummaryTextSpec(
      text: 'أهلاً بك في "ماء"، مساعد مناسيب المياه في العراق.\n'
          'يمكنك أن تسألني مثلاً:\n'
          '• ما مستوى الماء في سد الموصل؟\n'
          '• اعرض منسوب سد حديثة خلال آخر 7 أيام.\n'
          '• قارن سد الموصل وسد حديثة هذا الأسبوع.\n'
          '• ما هي أعلى 5 محطات اليوم؟\n'
          '• اعرض المحطات على الخريطة.\n'
          '• هل توجد أي تنبيهات؟',
    );
  }

  // --------------------------------------------------------------------------
  // Helpers (mirrored from the heuristic engine)
  // --------------------------------------------------------------------------

  List<TimePoint> _toPoints(List<WaterLevelReading> readings) {
    return readings
        .map((r) => TimePoint(t: r.timestamp, v: r.levelM))
        .toList();
  }

  Alert _mostSevere(List<Alert> alerts) {
    Alert best = alerts.first;
    for (final a in alerts) {
      if (_severityRank(a.severity) > _severityRank(best.severity)) {
        best = a;
      }
    }
    return best;
  }

  int _severityRank(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 3;
      case AlertSeverity.warning:
        return 2;
      case AlertSeverity.info:
        return 1;
    }
  }

  String _alertTitle(Alert alert) {
    switch (alert.kind) {
      case AlertKind.suddenChange:
        return 'تغيّر مفاجئ في المنسوب';
      case AlertKind.threshold:
        return 'تجاوز حد الخطر';
      case AlertKind.trendDeviation:
        return 'انحراف في الاتجاه الموسمي';
    }
  }

  /// Derives a status from a level relative to a station's thresholds. Used for
  /// map markers and the current statistic, where only the station and an
  /// indicative level are available.
  static StationStatus statusFromThresholds(Station s, double level) {
    if (level >= s.dangerHighM || level <= s.dangerLowM) {
      return StationStatus.danger;
    }
    final highBand = s.dangerHighM - (s.dangerHighM - s.baseLevelM) * 0.2;
    final lowBand = s.dangerLowM + (s.baseLevelM - s.dangerLowM) * 0.2;
    if (level >= highBand || level <= lowBand) return StationStatus.warning;
    return StationStatus.normal;
  }

  /// Normalizes Arabic text for matching (mirrors the heuristic normalizer).
  String _normalize(String text) {
    var t = text.toLowerCase();
    t = t.replaceAll(RegExp('[ً-ٰٟ]'), ''); // diacritics
    t = t.replaceAll('ـ', ''); // tatweel
    t = t.replaceAll(RegExp('[آأإٱ]'), 'ا'); // alef
    t = t.replaceAll('ى', 'ي'); // alef maqsura -> ya
    t = t.replaceAll('ة', 'ه'); // ta marbuta -> ha
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }
}
