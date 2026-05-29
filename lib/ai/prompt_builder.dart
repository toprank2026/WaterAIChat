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
  // Gemini engine (function-calling)
  // --------------------------------------------------------------------------

  /// The Arabic system prompt for the Gemini engine.
  ///
  /// Unlike [systemPrompt] (which describes six data tools + JSON block
  /// schemas for the on-device model), the Gemini path exposes a single
  /// function — `render_water_ui` — and lets the app fetch the real data. The
  /// persona therefore emphasises: understanding Iraqi/dialectal Arabic,
  /// resolving pronouns from prior turns, ALWAYS calling `render_water_ui`,
  /// NEVER inventing numbers, and picking the best block type.
  String geminiSystemPrompt() {
    return '''
أنت "ماء"، مساعد ذكي لمراقبة مناسيب المياه في العراق (الأنهار والسدود والبحيرات والروافد).
تساعد المشغّلين والمدراء والفنيين على فهم بيانات منسوب الماء بسرعة وبصرياً.

# القواعد
- افهم اللهجة العراقية والعربية الدارجة كما تفهم الفصحى (مثل: "شكد"، "شلون"، "وين"، "هسه").
- استعمل سياق المحادثة السابقة لحلّ الضمائر والإشارات (مثل: "لها"، "نفسها", "هذي المحطة", "وياها") وأرجِعها إلى المحطة المذكورة آخر مرة.
- في كل ردّ يجب أن تستدعي الدالة render_water_ui؛ لا تُجب بنص حر إلا عند التحية أو طلب التوضيح وعندها مرّر النص في summary_text.
- لا تخترع أرقاماً أو مناسيب أو إحصاءات أبداً؛ التطبيق هو من يجلب البيانات الحقيقية بناءً على اختيارك. أنت تختار نوع البطاقة وأسماء المحطات والمعاملات فقط.
- اختر نوع البطاقة الأنسب لسؤال المستخدم:
  • stat_card: منسوب محطة واحدة الآن.
  • statistics: ملخص رقمي لمحطة واحدة عبر مدة (الأدنى والأعلى والمتوسط والحالي) — استعمله عند طلب "إحصائيات" أو "متوسط" أو "المعدل" أو "أعلى وأقل" أو "ملخص" لمحطة.
  • line_chart: تطوّر منسوب محطة واحدة عبر الزمن.
  • multi_line_chart: مقارنة محطتين أو أكثر.
  • ranked_list: أعلى/أدنى عدد من المحطات.
  • station_list: عند السؤال عن عدد المحطات أو قائمتها أو "ما هي المحطات" أو التصفية حسب نهر/محافظة استعمل station_list ومرّر filter في summary_text إن وُجد (مثل اسم نهر أو محافظة).
  • station_map: عرض المحطات على الخريطة.
  • alert_card: التنبيهات والإنذارات النشطة.
  • summary_text: تحية أو تعريف أو طلب توضيح (ضع النص في summary_text).
- مرّر أسماء المحطات في station_names كما ذكرها المستخدم (يمكن أن تكون عربية).
- وحدة المنسوب دائماً بالأمتار ويُرمز لها بـ "م".
- لأسئلة قدراتك (مثل "ماذا يمكنك أن تفعل" أو "شنو تسوّي") استعمل summary_text واذكر باختصار ما تقدر عليه: منسوب محطة، تاريخ المنسوب، المقارنة، الإحصائيات، أعلى/أدنى المحطات، الخريطة، والتنبيهات.
- الشبكة تضم نحو 100 محطة موزّعة على نهري دجلة والفرات وشط العرب والسدود الكبرى (الموصل، حديثة، دوكان، دربنديخان...) والبحيرات والروافد (الزاب الكبير والصغير، ديالى، العظيم، الخابور). إذا سُئلت عن عدد المحطات أو قائمتها أو أسمائها فاستعمل station_list (لا summary_text).
- إذا كان السؤال خارج نطاق مناسيب المياه (سياحة، طقس، معلومة عامة، رياضة...) فأجب بإيجاز ومفيد عبر summary_text من معرفتك العامة وبلباقة، ولا ترفض الإجابة.
- إذا لم يحدّد المستخدم محطة في سؤال يتطلّبها، اطلب التوضيح عبر summary_text بدل تخمين محطة عشوائية.''';
  }

  /// The Gemini function declaration for `render_water_ui`.
  ///
  /// Returns an OpenAPI-ish schema (object with typed properties + enums) that
  /// is embedded under `tools[].function_declarations[]` in the request. The
  /// app reads the returned arguments and fetches real data to build the block.
  Map<String, dynamic> renderFunctionDeclaration() {
    return <String, dynamic>{
      'name': 'render_water_ui',
      'description':
          'يعرض بطاقة واجهة مناسبة لسؤال المستخدم عن مناسيب المياه في العراق. '
              'التطبيق يجلب الأرقام الحقيقية؛ أنت تختار نوع البطاقة ومعاملاتها فقط.',
      'parameters': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'block_type': <String, dynamic>{
            'type': 'string',
            'description': 'نوع البطاقة المطلوب عرضها.',
            'enum': <String>[
              'stat_card',
              'statistics',
              'line_chart',
              'multi_line_chart',
              'ranked_list',
              'station_list',
              'station_map',
              'alert_card',
              'summary_text',
            ],
          },
          'station_names': <String, dynamic>{
            'type': 'array',
            'description':
                'أسماء المحطات المعنية كما ذكرها المستخدم (واحدة لبطاقة منسوب أو مخطط، اثنتان أو أكثر للمقارنة).',
            'items': <String, dynamic>{'type': 'string'},
          },
          'time_range': <String, dynamic>{
            'type': 'string',
            'description': 'النطاق الزمني للمخططات التاريخية والمقارنات.',
            'enum': <String>['day', 'week', 'month', 'year'],
          },
          'count': <String, dynamic>{
            'type': 'integer',
            'description': 'عدد المحطات في قائمة الترتيب (ranked_list).',
          },
          'order': <String, dynamic>{
            'type': 'string',
            'description': 'اتجاه الترتيب: الأعلى منسوباً أم الأدنى.',
            'enum': <String>['highest', 'lowest'],
          },
          'summary_text': <String, dynamic>{
            'type': 'string',
            'description':
                'نص عربي يُعرض عند block_type=summary_text (تحية أو تعريف أو طلب توضيح أو إجابة عن سؤال خارج نطاق المياه). '
                    'ويُستعمل أيضاً مع block_type=station_list لحمل كلمة التصفية (اسم نهر أو محافظة) إن وُجدت.',
          },
        },
        'required': <String>['block_type'],
      },
    };
  }

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
// statistics — ملخص رقمي لمحطة عبر مدة (الأدنى/الأعلى/المتوسط/الحالي)
{ "type": "statistics", "title": "إحصائيات سد الموصل (آخر 30 يوماً)", "station_id": "STN-001",
  "stats": [ {"label": "الحالي", "value": 321.2, "unit": "م", "status": "normal"},
             {"label": "الأعلى", "value": 325.1, "unit": "م"},
             {"label": "الأدنى", "value": 318.0, "unit": "م"},
             {"label": "المتوسط", "value": 321.4, "unit": "م"} ] }''',
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
