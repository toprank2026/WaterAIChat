import 'package:ma_water/ui/chat/chat_models.dart';

/// Builds the Arabic system prompt, the tool catalogue, and the few-shot
/// examples that constrain the on-device model (Gemma) to:
///   1. always reply in Arabic,
///   2. pick exactly one of the six tools (PRD §11.2),
///   3. emit exactly one generative-UI block JSON (PRD §11.1).
///
/// This class is intentionally **data-only**: every method returns a [String]
/// (or a list of strings). It has no I/O and no model dependency, so it can be
/// unit-tested in isolation and reused by the real Gemma path
/// (`gemma_service.dart`). The [HeuristicInferenceService] does NOT need this;
/// it derives blocks directly from parsed intent.
class PromptBuilder {
  const PromptBuilder();

  /// The full system prompt: persona + rules + tool catalogue + block schemas.
  ///
  /// Compose this once and prepend it to the conversation sent to Gemma.
  String systemPrompt() {
    final buffer = StringBuffer()
      ..writeln(_persona)
      ..writeln()
      ..writeln(_rules)
      ..writeln()
      ..writeln(toolCatalogue())
      ..writeln()
      ..writeln(blockSchemas())
      ..writeln()
      ..writeln(_protocol);
    return buffer.toString().trim();
  }

  /// The complete prompt = system prompt + few-shot examples, ready to send.
  ///
  /// Use this when the model expects a single flattened instruction string.
  String fullPrompt() {
    final buffer = StringBuffer()
      ..writeln(systemPrompt())
      ..writeln()
      ..writeln('# أمثلة')
      ..writeln();
    for (final example in fewShotExamples()) {
      buffer
        ..writeln(example)
        ..writeln();
    }
    return buffer.toString().trim();
  }

  /// Renders the running [history] as an Arabic transcript the model can read,
  /// terminated with the new [userText] turn awaiting an assistant reply.
  String renderConversation({
    required String userText,
    required List<ChatMessage> history,
  }) {
    final buffer = StringBuffer();
    for (final message in history) {
      final speaker =
          message.role == MessageRole.user ? _userLabel : _assistantLabel;
      final text = message.text;
      if (text != null && text.isNotEmpty) {
        buffer.writeln('$speaker: $text');
      }
    }
    buffer
      ..writeln('$_userLabel: $userText')
      ..write('$_assistantLabel:');
    return buffer.toString();
  }

  // --------------------------------------------------------------------------
  // Tool catalogue (PRD §11.2)
  // --------------------------------------------------------------------------

  /// The six tools the model may call, with parameters and return shape.
  String toolCatalogue() {
    final buffer = StringBuffer()
      ..writeln('# الأدوات المتاحة')
      ..writeln(
          'استدعِ أداة واحدة فقط لجلب البيانات قبل تكوين البطاقة. صيغة الاستدعاء:')
      ..writeln('{"tool": "<name>", "args": { ... }}')
      ..writeln();
    for (final tool in _tools) {
      buffer
        ..writeln('- ${tool.name}: ${tool.descriptionAr}')
        ..writeln('  المعاملات: ${tool.params}')
        ..writeln('  تُعيد: ${tool.returnsAr}');
    }
    return buffer.toString().trim();
  }

  /// The block JSON schemas (PRD §11.1) the model must choose exactly one of.
  String blockSchemas() {
    final buffer = StringBuffer()
      ..writeln('# أنواع البطاقات (أخرج واحدة فقط بصيغة JSON)');
    for (final schema in _blockSchemas) {
      buffer.writeln(schema);
    }
    return buffer.toString().trim();
  }

  /// Curated bilingual few-shot examples: user question -> tool call -> block.
  List<String> fewShotExamples() => List.unmodifiable(_fewShots);

  // --------------------------------------------------------------------------
  // Static prompt fragments
  // --------------------------------------------------------------------------

  static const String _userLabel = 'المستخدم';
  static const String _assistantLabel = 'المساعد';

  static const String _persona = '''
أنت "ماء"، مساعد ذكي لمراقبة مناسيب المياه في العراق (الأنهار والسدود والبحيرات والروافد).
تساعد المشغّلين والمدراء والفنيين على فهم بيانات منسوب الماء بسرعة وبصرياً.''';

  static const String _rules = '''
# القواعد
- أجب دائماً باللغة العربية الفصحى المبسطة.
- لا تخترع أرقاماً أبداً؛ اجلب البيانات عبر الأدوات فقط.
- استدعِ أداة واحدة مناسبة لنية المستخدم، ثم أخرج بطاقة JSON واحدة فقط.
- اختر نوع البطاقة الأنسب للسؤال (منسوب واحد، تاريخ زمني، مقارنة، ترتيب، خريطة، تنبيه، أو نص).
- إن لم تتعرّف على المحطة أو كان السؤال غامضاً، أخرج بطاقة summary_text تطلب التوضيح بلطف.
- وحدة المنسوب دائماً بالأمتار ويُرمز لها بـ "م".''';

  static const String _protocol = '''
# البروتوكول
1) حلّل نية المستخدم.
2) استدعِ أداة واحدة بصيغة: {"tool": "...", "args": {...}}.
3) بعد وصول نتيجة الأداة، أخرج بطاقة JSON واحدة مطابقة لأحد الأنواع أعلاه ولا شيء غيرها.''';

  static const List<_ToolDoc> _tools = <_ToolDoc>[
    _ToolDoc(
      name: 'find_station',
      descriptionAr: 'يبحث عن المحطات بالاسم أو المحافظة أو المسطح المائي.',
      params: '{ "query": "نص" }',
      returnsAr: 'قائمة المحطات المطابقة.',
    ),
    _ToolDoc(
      name: 'get_current_level',
      descriptionAr: 'يجلب أحدث منسوب لمحطة مع التغيّر خلال 24 ساعة وحالتها.',
      params: '{ "station_id": "STN-001" }',
      returnsAr: 'آخر قراءة + الفرق 24س + الحالة.',
    ),
    _ToolDoc(
      name: 'get_history',
      descriptionAr: 'يجلب سلسلة زمنية للمنسوب بين تاريخين.',
      params:
          '{ "station_id": "STN-001", "from": "ISO", "to": "ISO", "interval": "hour|day" }',
      returnsAr: 'مصفوفة قراءات.',
    ),
    _ToolDoc(
      name: 'compare_stations',
      descriptionAr: 'يجلب قراءات متوازية لعدة محطات للمقارنة.',
      params: '{ "station_ids": ["STN-001","STN-045"], "from": "ISO", "to": "ISO" }',
      returnsAr: 'قراءات لكل محطة.',
    ),
    _ToolDoc(
      name: 'rank_stations',
      descriptionAr: 'يرتّب المحطات حسب المنسوب تصاعدياً أو تنازلياً.',
      params:
          '{ "by": "level", "order": "desc|asc", "limit": 5, "at": "ISO|now" }',
      returnsAr: 'قائمة مرتّبة.',
    ),
    _ToolDoc(
      name: 'list_alerts',
      descriptionAr: 'يجلب التنبيهات النشطة عبر الأسطول.',
      params: '{ "active": true }',
      returnsAr: 'مصفوفة تنبيهات.',
    ),
  ];

  static const List<String> _blockSchemas = <String>[
    '''
// stat_card — منسوب واحد
{ "type": "stat_card", "title": "محطة سد الموصل", "value": 319.84, "unit": "م",
  "delta": "+0.42 م خلال 24 ساعة", "status": "normal", "station_id": "STN-001" }''',
    '''
// line_chart — سلسلة زمنية لمحطة
{ "type": "line_chart", "title": "مستوى الماء — سد الموصل (آخر 7 أيام)",
  "station_id": "STN-001",
  "points": [{"t": "2026-05-22T00:00:00Z", "v": 318.4}],
  "danger_high": 330.0, "danger_low": 300.0 }''',
    '''
// multi_line_chart — مقارنة محطتين أو أكثر
{ "type": "multi_line_chart", "title": "مقارنة سد الموصل وسد حديثة",
  "series": [ {"label": "سد الموصل", "points": []}, {"label": "سد حديثة", "points": []} ] }''',
    '''
// ranked_list — أعلى/أدنى N محطة
{ "type": "ranked_list", "title": "أعلى 5 محطات اليوم",
  "items": [ {"station_id": "STN-001", "name": "سد الموصل", "value": 319.84, "unit": "م"} ] }''',
    '''
// station_map — توزيع جغرافي مع الحالة
{ "type": "station_map", "title": "حالة المحطات",
  "markers": [ {"station_id": "STN-001", "lat": 36.6307, "lng": 42.8233, "status": "normal"} ] }''',
    '''
// alert_card — تنبيه/تجاوز حد
{ "type": "alert_card", "severity": "warning", "title": "ارتفاع متسارع — بغداد الجادرية",
  "body": "احتمال تجاوز حد التحذير خلال 4 ساعات.", "station_id": "STN-018",
  "ai_note": "النمط يطابق موجة موسمية من العام الماضي." }''',
    '''
// summary_text — نص احتياطي (تحية، تعريف، طلب توضيح)
{ "type": "summary_text", "text": "..." }''',
  ];

  static const List<String> _fewShots = <String>[
    '''
$_userLabel: شو مستوى الماء في سد الموصل؟
$_assistantLabel: {"tool": "find_station", "args": {"query": "سد الموصل"}}
[نتيجة: STN-001]
$_assistantLabel: {"tool": "get_current_level", "args": {"station_id": "STN-001"}}
[نتيجة: {"level_m": 319.84, "delta_24h_m": 0.42, "status": "normal"}]
$_assistantLabel: {"type": "stat_card", "title": "محطة سد الموصل", "value": 319.84, "unit": "م", "delta": "+0.42 م خلال 24 ساعة", "status": "normal", "station_id": "STN-001"}''',
    '''
$_userLabel: كيف مستوى الماء في سد الموصل خلال هذا الأسبوع؟
$_assistantLabel: {"tool": "find_station", "args": {"query": "سد الموصل"}}
[نتيجة: STN-001]
$_assistantLabel: {"tool": "get_history", "args": {"station_id": "STN-001", "from": "2026-05-22T00:00:00Z", "to": "2026-05-29T00:00:00Z", "interval": "hour"}}
[نتيجة: مصفوفة قراءات]
$_assistantLabel: {"type": "line_chart", "title": "مستوى الماء — سد الموصل (آخر 7 أيام)", "station_id": "STN-001", "points": [{"t": "2026-05-22T00:00:00Z", "v": 318.4}], "danger_high": 330.0, "danger_low": 300.0}''',
    '''
$_userLabel: قارن سد الموصل وسد حديثة هذا الأسبوع
$_assistantLabel: {"tool": "compare_stations", "args": {"station_ids": ["STN-001", "STN-045"], "from": "2026-05-22T00:00:00Z", "to": "2026-05-29T00:00:00Z"}}
[نتيجة: قراءات لكل محطة]
$_assistantLabel: {"type": "multi_line_chart", "title": "مقارنة سد الموصل وسد حديثة", "series": [{"label": "سد الموصل", "points": []}, {"label": "سد حديثة", "points": []}]}''',
    '''
$_userLabel: أعطني أعلى 5 محطات اليوم
$_assistantLabel: {"tool": "rank_stations", "args": {"by": "level", "order": "desc", "limit": 5, "at": "now"}}
[نتيجة: قائمة مرتّبة]
$_assistantLabel: {"type": "ranked_list", "title": "أعلى 5 محطات اليوم", "items": [{"station_id": "STN-001", "name": "سد الموصل", "value": 319.84, "unit": "م"}]}''',
    '''
$_userLabel: اعرض المحطات على الخريطة
$_assistantLabel: {"tool": "find_station", "args": {"query": ""}}
[نتيجة: قائمة المحطات]
$_assistantLabel: {"type": "station_map", "title": "حالة المحطات", "markers": [{"station_id": "STN-001", "lat": 36.6307, "lng": 42.8233, "status": "normal"}]}''',
    '''
$_userLabel: في أي تنبيهات؟
$_assistantLabel: {"tool": "list_alerts", "args": {"active": true}}
[نتيجة: مصفوفة تنبيهات]
$_assistantLabel: {"type": "alert_card", "severity": "warning", "title": "ارتفاع متسارع — بغداد الجادرية", "body": "احتمال تجاوز حد التحذير خلال 4 ساعات.", "station_id": "STN-018", "ai_note": "النمط يطابق موجة موسمية من العام الماضي."}''',
    '''
$_userLabel: مرحبا
$_assistantLabel: {"type": "summary_text", "text": "أهلاً بك في ماء. يمكنك سؤالي عن منسوب محطة، أو تاريخ منسوبها، أو مقارنة محطتين، أو أعلى المحطات، أو عرض الخريطة، أو التنبيهات."}''',
  ];
}

/// Internal description of a single tool for the prompt catalogue.
class _ToolDoc {
  final String name;
  final String descriptionAr;
  final String params;
  final String returnsAr;

  const _ToolDoc({
    required this.name,
    required this.descriptionAr,
    required this.params,
    required this.returnsAr,
  });
}
