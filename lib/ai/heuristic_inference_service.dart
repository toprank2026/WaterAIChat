import 'package:ma_water/ai/block_builder.dart';
import 'package:ma_water/ai/inference_service.dart';
import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/ui/chat/chat_models.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// The **default** conversational engine. Pure-Dart keyword heuristics over the
/// Arabic [userText] decide the user's intent, call the [ToolDispatcher] against
/// the repository, and assemble a single [BlockSpec] for the reply.
///
/// It requires no model and runs fully offline. [BlockSpec] instances are built
/// directly (never round-tripped through JSON). When a station cannot be
/// resolved (none found, or ambiguous) the reply is a [SummaryTextSpec] asking
/// the user to clarify.
class HeuristicInferenceService implements InferenceService {
  final ToolDispatcher _tools;

  HeuristicInferenceService(this._tools);

  /// 7-day default history window for time-series questions.
  static const Duration _historyWindow = Duration(days: 7);

  /// Default count for top/bottom ranking questions.
  static const int _defaultRankLimit = 5;

  @override
  Future<ChatMessage> respond({
    required String userText,
    required List<ChatMessage> history,
  }) async {
    final block = await _buildBlock(userText, history);
    return ChatMessage(
      id: _newId(),
      role: MessageRole.assistant,
      block: block,
      createdAt: DateTime.now().toUtc(),
    );
  }

  // --------------------------------------------------------------------------
  // Intent routing
  // --------------------------------------------------------------------------

  Future<BlockSpec> _buildBlock(String userText, List<ChatMessage> history) {
    final intent = _classify(userText);
    switch (intent) {
      case _Intent.compare:
        return _handleCompare(userText);
      case _Intent.statistics:
        return _handleStatistics(userText, history);
      case _Intent.history:
        return _handleHistory(userText, history);
      case _Intent.rank:
        return _handleRank(userText);
      case _Intent.stationList:
        return _handleStationList();
      case _Intent.map:
        return _handleMap();
      case _Intent.alerts:
        return _handleAlerts();
      case _Intent.currentLevel:
        return _handleCurrentLevel(userText, history);
      case _Intent.greeting:
        return Future.value(_guidanceBlock());
    }
  }

  /// Classifies intent from Arabic keywords. Order matters: more specific
  /// intents (compare, history, rank) are checked before the generic
  /// current-level fallback.
  _Intent _classify(String text) {
    final t = _normalize(text);

    if (_containsAny(t, _greetingWords) && !_containsAny(t, _dataWords)) {
      return _Intent.greeting;
    }
    if (_containsAny(t, _alertWords)) return _Intent.alerts;
    // Station-list questions ("كم محطة"، "قائمة/أسماء المحطات"، "وين المحطات")
    // must precede the generic map/rank/current checks, since they share the
    // word "محطات" and the locator "وين". An explicit map word ("خريطة") still
    // wins, so "اعرض المحطات على الخريطة" stays a map request.
    if (_containsAny(t, _stationListWords) &&
        !_containsAny(t, _explicitMapWords)) {
      return _Intent.stationList;
    }
    if (_containsAny(t, _mapWords)) return _Intent.map;
    if (_containsAny(t, _compareWords)) return _Intent.compare;
    // Statistics must precede rank/history: phrases like "أعلى وأقل" or "متوسط"
    // share keywords with those intents but the user wants a numeric summary.
    if (_containsAny(t, _statisticsWords)) return _Intent.statistics;
    if (_containsAny(t, _rankWords)) return _Intent.rank;
    if (_containsAny(t, _historyWords)) return _Intent.history;
    if (_containsAny(t, _currentWords)) return _Intent.currentLevel;

    // If a station name is present but no explicit keyword, treat as a
    // current-level question; otherwise offer guidance.
    if (_nameCandidates(text).isNotEmpty) return _Intent.currentLevel;
    return _Intent.greeting;
  }

  // --------------------------------------------------------------------------
  // Intent handlers
  // --------------------------------------------------------------------------

  Future<BlockSpec> _handleCurrentLevel(
      String userText, List<ChatMessage> history) async {
    final station = await _resolveStationOrLast(userText, history);
    if (station == null) return _clarifyStationBlock();

    final CurrentLevel level = await _tools.getCurrentLevel(station.id);
    return StatCardSpec(
      title: station.nameAr,
      value: level.current.levelM,
      unit: _unitAr,
      delta: '${formatDelta(level.delta24hM)} خلال 24 ساعة',
      status: level.status,
      stationId: station.id,
    );
  }

  Future<BlockSpec> _handleHistory(
      String userText, List<ChatMessage> history) async {
    final station = await _resolveStationOrLast(userText, history);
    if (station == null) return _clarifyStationBlock();

    final window = _historyWindowFor(userText);
    final to = DateTime.now().toUtc();
    final from = to.subtract(window.duration);
    // Hourly resolution for short windows; daily for a month or longer keeps the
    // series light and the chart readable.
    final interval = window.duration.inDays >= 30
        ? ReadingInterval.day
        : ReadingInterval.hour;
    final readings = await _tools.getHistory(
      station.id,
      from,
      to,
      interval: interval,
    );

    return LineChartSpec(
      title: 'مستوى الماء — ${station.nameAr} (${window.labelAr})',
      stationId: station.id,
      points: _toPoints(readings),
      dangerHigh: station.dangerHighM,
      dangerLow: station.dangerLowM,
    );
  }

  Future<BlockSpec> _handleStatistics(
      String userText, List<ChatMessage> history) async {
    final station = await _resolveStationOrLast(userText, history);
    if (station == null) return _clarifyStationBlock();

    // Honour an explicit time phrase ("آخر سنة", "آخر شهر", "N يوم"); otherwise
    // summarise over the last 30 days.
    final window = _statisticsWindowFor(userText);
    final to = DateTime.now().toUtc();
    final from = to.subtract(window.duration);
    final interval = window.duration.inDays >= 30
        ? ReadingInterval.day
        : ReadingInterval.hour;
    final readings = await _tools.getHistory(
      station.id,
      from,
      to,
      interval: interval,
    );

    final stats = BlockBuilder.computeStats(station, readings);
    if (stats == null) {
      return SummaryTextSpec(
        text: 'لا تتوفر بيانات كافية لحساب إحصائيات ${station.nameAr} '
            'خلال ${window.labelAr}.',
      );
    }

    return StatisticsSpec(
      title: 'إحصائيات ${station.nameAr} (${window.labelAr})',
      stationId: station.id,
      stats: stats,
    );
  }

  Future<BlockSpec> _handleCompare(String userText) async {
    final stations = await _resolveStations(userText, max: 4);
    if (stations.length < 2) {
      return const SummaryTextSpec(
        text:
            'للمقارنة أحتاج اسمي محطتين على الأقل. مثال: "قارن سد الموصل وسد حديثة".',
      );
    }

    final to = DateTime.now().toUtc();
    final from = to.subtract(_historyWindow);
    final ids = stations.map((s) => s.id).toList();
    final Map<String, List<WaterLevelReading>> data =
        await _tools.compareStations(ids, from, to);

    final byId = {for (final s in stations) s.id: s};
    final series = <NamedSeries>[];
    for (final id in ids) {
      final station = byId[id];
      series.add(NamedSeries(
        label: station?.nameAr ?? id,
        points: _toPoints(data[id] ?? const <WaterLevelReading>[]),
      ));
    }

    final names = stations.map((s) => s.nameAr).join(' و');
    return MultiLineChartSpec(title: 'مقارنة $names', series: series);
  }

  Future<BlockSpec> _handleRank(String userText) async {
    final t = _normalize(userText);
    final order = _containsAny(t, _bottomWords) ? 'asc' : 'desc';
    final limit = _extractCount(t) ?? _defaultRankLimit;

    final List<RankedStation> ranked = await _tools.rankStations(
      by: 'level',
      order: order,
      limit: limit,
    );

    final qualifier = order == 'asc' ? 'أدنى' : 'أعلى';
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

  /// Builds a [StationListSpec] directory of the whole fleet. Per-item status
  /// is omitted (a live level lookup per station would be too heavy for ~100
  /// stations); `count` is the true total. Delegates to [BlockBuilder] so the
  /// heuristic and Gemini paths produce identical station-list cards.
  Future<BlockSpec> _handleStationList() {
    return BlockBuilder(_tools).stationList();
  }

  Future<BlockSpec> _handleMap() async {
    final stations = await _tools.findStation('');
    final markers = stations
        .map((s) => MapMarker(
              stationId: s.id,
              lat: s.latitude,
              lng: s.longitude,
              status: _statusFromThresholds(s, s.baseLevelM),
            ))
        .toList();
    return StationMapSpec(title: 'حالة المحطات', markers: markers);
  }

  Future<BlockSpec> _handleAlerts() async {
    final List<Alert> alerts = await _tools.listAlerts(activeOnly: true);
    if (alerts.isEmpty) {
      return const SummaryTextSpec(
        text: 'لا توجد تنبيهات نشطة حالياً. جميع المحطات ضمن المعدلات الطبيعية.',
      );
    }

    // Prefer the most severe alert; fall back to the first.
    final alert = _mostSevere(alerts);
    return AlertCardSpec(
      severity: alert.severity,
      title: _alertTitle(alert),
      body: alert.messageAr,
      stationId: alert.stationId,
    );
  }

  // --------------------------------------------------------------------------
  // Station resolution
  // --------------------------------------------------------------------------

  /// Resolves a single station from [userText]. Returns `null` when no
  /// candidate fragment matches a station, or when the match is ambiguous
  /// (the caller then asks the user to clarify).
  Future<Station?> _resolveSingleStation(String userText) async {
    final stations = await _resolveStations(userText, max: 1);
    return stations.isEmpty ? null : stations.first;
  }

  /// Resolves up to [max] distinct stations from the name fragments in
  /// [userText]. Each fragment is looked up via the dispatcher; an unambiguous
  /// single hit per fragment is accepted. Duplicates are removed.
  Future<List<Station>> _resolveStations(String userText,
      {required int max}) async {
    final candidates = _nameCandidates(userText);
    final resolved = <String, Station>{};

    for (final fragment in candidates) {
      if (resolved.length >= max) break;
      final matches = await _tools.findStation(fragment);
      if (matches.isEmpty) continue;
      // An unambiguous fragment matches exactly one station; otherwise prefer
      // an exact Arabic-name hit, else skip as ambiguous.
      final pick = _disambiguate(matches, fragment);
      if (pick != null) resolved[pick.id] = pick;
    }

    // Last resort: try the whole text as a single query.
    if (resolved.isEmpty) {
      final matches = await _tools.findStation(userText);
      final pick = _disambiguate(matches, userText);
      if (pick != null) resolved[pick.id] = pick;
    }

    return resolved.values.take(max).toList();
  }

  /// Picks a station from [matches] for [fragment]: a single match is taken
  /// directly; otherwise an exact normalized Arabic-name match wins; otherwise
  /// the fragment is treated as ambiguous and `null` is returned.
  Station? _disambiguate(List<Station> matches, String fragment) {
    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;

    final f = _normalize(fragment);
    for (final s in matches) {
      if (_normalize(s.nameAr) == f) return s;
    }
    // Prefer a name that fully contains the fragment uniquely.
    final containing =
        matches.where((s) => _normalize(s.nameAr).contains(f)).toList();
    if (containing.length == 1) return containing.first;
    return null;
  }

  // --------------------------------------------------------------------------
  // Conversational context
  // --------------------------------------------------------------------------

  /// Resolves a station from [userText]; if the text names none — e.g. a
  /// follow-up using a pronoun like "لها"/"نفسها" — falls back to the most
  /// recently referenced station in the conversation [history].
  Future<Station?> _resolveStationOrLast(
      String userText, List<ChatMessage> history) async {
    final direct = await _resolveSingleStation(userText);
    if (direct != null) return direct;
    final lastId = _lastStationIdFromHistory(history);
    if (lastId == null) return null;
    return _tools.repo.getStationById(lastId);
  }

  /// Scans [history] newest-first for the last station id carried by an
  /// assistant block (stat card, line chart, or alert card).
  String? _lastStationIdFromHistory(List<ChatMessage> history) {
    for (final message in history.reversed) {
      final block = message.block;
      if (block is StatCardSpec && block.stationId != null) {
        return block.stationId;
      }
      if (block is StatisticsSpec && block.stationId != null) {
        return block.stationId;
      }
      if (block is LineChartSpec && block.stationId != null) {
        return block.stationId;
      }
      if (block is AlertCardSpec && block.stationId != null) {
        return block.stationId;
      }
    }
    return null;
  }

  /// Chooses the history window from time phrases in [text]: a year, one or more
  /// months ("آخر شهر"), an explicit "N يوم", else the default 7 days.
  _HistWindow _historyWindowFor(String text) {
    final t = _normalize(text);
    final count = _extractCount(t);
    if (_containsAny(t, const ['سنه', 'سنة', 'عام', 'سنوات'])) {
      return const _HistWindow(Duration(days: 365), 'آخر سنة');
    }
    if (_containsAny(t, const ['شهر', 'شهور', 'اشهر', 'أشهر'])) {
      final months = (count != null && count >= 1) ? count : 1;
      final days = (months * 30).clamp(30, 365);
      return _HistWindow(
        Duration(days: days),
        months <= 1 ? 'آخر شهر' : 'آخر $months أشهر',
      );
    }
    if (count != null && t.contains('يوم')) {
      return _HistWindow(Duration(days: count), 'آخر $count يوماً');
    }
    return const _HistWindow(Duration(days: 7), 'آخر 7 أيام');
  }

  /// Chooses the statistics window from time phrases in [text], defaulting to
  /// the last 30 days when none is given (a numeric summary is most meaningful
  /// over a longer span). Explicit year/month/"N يوم" phrases are honoured.
  _HistWindow _statisticsWindowFor(String text) {
    final t = _normalize(text);
    final count = _extractCount(t);
    if (_containsAny(t, const ['سنه', 'سنة', 'عام', 'سنوات'])) {
      return const _HistWindow(Duration(days: 365), 'آخر سنة');
    }
    if (_containsAny(t, const ['شهر', 'شهور', 'اشهر', 'أشهر'])) {
      final months = (count != null && count >= 1) ? count : 1;
      final days = (months * 30).clamp(30, 365);
      return _HistWindow(
        Duration(days: days),
        months <= 1 ? 'آخر شهر' : 'آخر $months أشهر',
      );
    }
    if (count != null && t.contains('يوم')) {
      return _HistWindow(Duration(days: count), 'آخر $count يوماً');
    }
    return const _HistWindow(Duration(days: 30), 'آخر 30 يوماً');
  }

  // --------------------------------------------------------------------------
  // Arabic name-candidate extraction
  // --------------------------------------------------------------------------

  /// Extracts station-name candidate fragments from Arabic [text].
  ///
  /// Strategy: strip leading intent/stop words, split on Arabic conjunctions
  /// ("و"/"مع"/"بين"/","/"و بين") so comparison phrases yield two fragments,
  /// then keep fragments that contain a place/structure keyword
  /// ("سد"/"محطة"/"نهر"/"بحيرة"/…) or are otherwise plausible proper nouns.
  List<String> _nameCandidates(String text) {
    final cleaned = _stripQuestionWords(text);

    // Split on conjunctions and separators commonly joining station names.
    final parts = cleaned
        .split(RegExp(r'\s+و\s+|\s+مع\s+|\s+بين\s+|,|،|\bو\b'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final candidates = <String>[];
    final seen = <String>{};
    for (final part in parts) {
      final fragment = _cleanFragment(part);
      if (fragment.isEmpty) continue;
      final norm = _normalize(fragment);
      if (norm.isEmpty || seen.contains(norm)) continue;
      seen.add(norm);
      candidates.add(fragment);
    }

    // If nothing survived but the cleaned text is short, treat it as one name.
    if (candidates.isEmpty) {
      final whole = _cleanFragment(cleaned);
      if (whole.isNotEmpty) candidates.add(whole);
    }
    return candidates;
  }

  /// Removes question/intent/stop words so only the location phrase remains.
  String _stripQuestionWords(String text) {
    var t = ' ${text.trim()} ';
    for (final w in _stopWords) {
      t = t.replaceAll(RegExp('\\s$w\\s'), ' ');
    }
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Trims punctuation and trailing/leading particles from a fragment.
  String _cleanFragment(String fragment) {
    var f = fragment.replaceAll(RegExp(r'[؟?!.…]+'), ' ').trim();
    f = f.replaceAll(RegExp(r'\s+'), ' ');
    return f;
  }

  // --------------------------------------------------------------------------
  // Block helpers
  // --------------------------------------------------------------------------

  /// Helpful Arabic guidance listing example questions, for greeting/unknown.
  SummaryTextSpec _guidanceBlock() {
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

  SummaryTextSpec _clarifyStationBlock() {
    return const SummaryTextSpec(
      text: 'لم أتعرّف على المحطة المقصودة. هلّا حددت اسم المحطة بدقة؟ '
          'مثال: "سد الموصل" أو "بغداد - الجادرية".',
    );
  }

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
    final AlertKind kind = alert.kind;
    switch (kind) {
      case AlertKind.suddenChange:
        return 'تغيّر مفاجئ في المنسوب';
      case AlertKind.threshold:
        return 'تجاوز حد الخطر';
      case AlertKind.trendDeviation:
        return 'انحراف في الاتجاه الموسمي';
    }
  }

  /// Derives a status from a level relative to a station's thresholds. Used for
  /// map markers where only the station and an indicative level are available.
  StationStatus _statusFromThresholds(Station s, double level) {
    if (level >= s.dangerHighM || level <= s.dangerLowM) {
      return StationStatus.danger;
    }
    final highBand = s.dangerHighM - (s.dangerHighM - s.baseLevelM) * 0.2;
    final lowBand = s.dangerLowM + (s.baseLevelM - s.dangerLowM) * 0.2;
    if (level >= highBand || level <= lowBand) return StationStatus.warning;
    return StationStatus.normal;
  }

  // --------------------------------------------------------------------------
  // Text utilities
  // --------------------------------------------------------------------------

  /// Normalizes Arabic text for keyword matching: lowercases, unifies alef and
  /// ya/alef-maqsura forms, strips tatweel/diacritics, collapses whitespace.
  String _normalize(String text) {
    var t = text.toLowerCase();
    t = t.replaceAll(RegExp('[ً-ٰٟ]'), ''); // diacritics
    t = t.replaceAll('ـ', ''); // tatweel
    t = t.replaceAll(RegExp('[آأإٱ]'), 'ا'); // alef
    t = t.replaceAll('ى', 'ي'); // alef maqsura -> ya
    t = t.replaceAll('ة', 'ه'); // ta marbuta -> ha
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  bool _containsAny(String normalizedText, List<String> words) {
    for (final w in words) {
      if (normalizedText.contains(_normalize(w))) return true;
    }
    return false;
  }

  /// Extracts the first integer in [text] (e.g. "أعلى 3 محطات" -> 3).
  int? _extractCount(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    if (match == null) return null;
    final value = int.tryParse(match.group(0)!);
    if (value == null || value <= 0) return null;
    return value;
  }

  String _newId() =>
      'asst-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  // --------------------------------------------------------------------------
  // Keyword sets (matched against normalized text)
  // --------------------------------------------------------------------------

  static const String _unitAr = 'م';

  static const List<String> _greetingWords = [
    'مرحبا',
    'اهلا',
    'أهلا',
    'السلام',
    'هلا',
    'صباح',
    'مساء',
    'شكرا',
    'من انت',
    'مساعدة',
    'ساعدني',
  ];

  static const List<String> _alertWords = [
    'تنبيه',
    'تنبيهات',
    'انذار',
    'إنذار',
    'تحذير',
    'تحذيرات',
    'خطر',
  ];

  static const List<String> _mapWords = [
    'خريطة',
    'خارطة',
    'الخريطة',
    'موقع',
    'مواقع',
    'اين',
    'أين',
    'وين',
  ];

  /// Explicit map keywords that should keep a "المحطات" phrase as a map request
  /// (e.g. "اعرض المحطات على الخريطة"), unlike the ambiguous locators
  /// ("وين"/"اين") which are treated as a station-list question.
  static const List<String> _explicitMapWords = [
    'خريطة',
    'خارطة',
    'الخريطة',
  ];

  /// Words signalling a request for the station directory (count or list).
  /// Checked before [_mapWords]/[_rankWords]/[_currentWords] because the word
  /// "محطات" and the locator "وين" overlap with those intents.
  static const List<String> _stationListWords = [
    'كم محطة',
    'كم محطه',
    'عدد المحطات',
    'قائمة المحطات',
    'المحطات',
    'اعرض المحطات',
    'شنو المحطات',
    'وين المحطات',
    'اسماء المحطات',
    'أسماء المحطات',
  ];

  static const List<String> _compareWords = [
    'قارن',
    'مقارنة',
    'قارني',
    'الفرق بين',
    'مقابل',
  ];

  static const List<String> _rankWords = [
    'اعلى',
    'أعلى',
    'ادنى',
    'أدنى',
    'اكثر',
    'أكثر',
    'اقل',
    'أقل',
    'ترتيب',
    'رتب',
    'افضل',
    'أفضل',
    'top',
  ];

  static const List<String> _bottomWords = [
    'ادنى',
    'أدنى',
    'اقل',
    'أقل',
  ];

  /// Words signalling a request for a numeric summary (min/max/avg/current).
  /// Checked before [_rankWords]/[_historyWords] because phrases like
  /// "أعلى وأقل" overlap with the ranking keywords.
  static const List<String> _statisticsWords = [
    'احصائيات',
    'إحصائيات',
    'احصائية',
    'إحصائية',
    'احصاء',
    'إحصاء',
    'ملخص',
    'متوسط',
    'المعدل',
    'معدل',
    'اعلى واقل',
    'أعلى وأقل',
  ];

  static const List<String> _historyWords = [
    'خلال',
    'اخر',
    'آخر',
    'الاسبوع',
    'الأسبوع',
    'اسبوع',
    'ايام',
    'أيام',
    'تاريخ',
    'سجل',
    'منحنى',
    'تطور',
    'اليومين',
    'الماضية',
    'الماضي',
  ];

  static const List<String> _currentWords = [
    'مستوى',
    'منسوب',
    'شو',
    'كم',
    'ما هو',
    'ماهو',
    'الحالي',
    'الان',
    'الآن',
    'وضع',
    'حالة',
  ];

  /// Words/data terms that signal a real data question (so a greeting word in
  /// the same sentence does not short-circuit to the greeting handler).
  static const List<String> _dataWords = [
    'مستوى',
    'منسوب',
    'محطة',
    'سد',
    'نهر',
    'بحيرة',
    'تنبيه',
    'قارن',
    'خريطة',
    'اعلى',
    'أعلى',
    'ادنى',
    'أدنى',
    'خلال',
  ];

  /// Words removed before extracting station-name candidates.
  static const List<String> _stopWords = [
    'ما',
    'هو',
    'هي',
    'مستوى',
    'منسوب',
    'الماء',
    'المياه',
    'شو',
    'كم',
    'قارن',
    'مقارنة',
    'بين',
    'خلال',
    'اخر',
    'آخر',
    'الاسبوع',
    'الأسبوع',
    'اسبوع',
    'هذا',
    'هذه',
    'في',
    'على',
    'عن',
    'من',
    'الى',
    'إلى',
    'اعرض',
    'أعرض',
    'اظهر',
    'أظهر',
    'اعطني',
    'أعطني',
    'الحالي',
    'الان',
    'الآن',
    'وضع',
    'حالة',
    'ايام',
    'أيام',
    'الماضية',
    'الماضي',
    'هل',
    'يوجد',
    'توجد',
    'كيف',
  ];
}

/// Heuristic intents the engine can route to.
enum _Intent {
  currentLevel,
  statistics,
  history,
  compare,
  rank,
  stationList,
  map,
  alerts,
  greeting,
}

/// A resolved history window: how far back to fetch, and an Arabic label for
/// the chart title.
class _HistWindow {
  final Duration duration;
  final String labelAr;
  const _HistWindow(this.duration, this.labelAr);
}
