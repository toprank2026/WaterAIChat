import 'package:dio/dio.dart';

import 'package:ma_water/ai/block_builder.dart';
import 'package:ma_water/ai/gemini_client.dart';
import 'package:ma_water/ai/inference_service.dart';
import 'package:ma_water/ai/prompt_builder.dart';
import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/ui/chat/chat_models.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Cloud conversational engine backed by Gemini function calling.
///
/// Flow:
/// 1. Turn the conversation [history] + the new message into [GeminiTurn]s.
///    Assistant blocks become a SHORT Arabic description so context carries.
/// 2. Ask [GeminiClient.decide] for a decision, forcing the single
///    `render_water_ui` function.
/// 3. On a function call, read the arguments and use [BlockBuilder] to fetch
///    the **real** data and assemble the matching [BlockSpec] (Gemini never
///    invents numbers). On a text decision, wrap it in a [SummaryTextSpec].
/// 4. On ANY error (network/auth/parse), defer to [fallback] if provided,
///    else return a friendly Arabic "AI unavailable" message.
class GeminiInferenceService implements InferenceService {
  final BlockBuilder _blocks;
  final GeminiClient _client;
  final PromptBuilder _prompts;
  final InferenceService? fallback;

  GeminiInferenceService({
    required ToolDispatcher tools,
    required String apiKey,
    Dio? dio,
    String model = 'gemini-2.5-flash-lite',
    this.fallback,
  })  : _blocks = BlockBuilder(tools),
        _client = GeminiClient(apiKey: apiKey, dio: dio, model: model),
        _prompts = const PromptBuilder();

  @override
  Future<ChatMessage> respond({
    required String userText,
    required List<ChatMessage> history,
  }) async {
    try {
      final turns = _buildTurns(userText, history);
      final decision = await _client.decide(
        systemPrompt: _prompts.geminiSystemPrompt(),
        turns: turns,
        functionDeclaration: _prompts.renderFunctionDeclaration(),
      );

      final block = await _toBlock(decision);
      return _assistant(block);
    } catch (_) {
      if (fallback != null) {
        return fallback!.respond(userText: userText, history: history);
      }
      return _assistant(const SummaryTextSpec(
        text: 'عذراً، خدمة الذكاء الاصطناعي غير متاحة حالياً. '
            'يرجى المحاولة مرة أخرى بعد قليل.',
      ));
    }
  }

  // --------------------------------------------------------------------------
  // Decision -> block
  // --------------------------------------------------------------------------

  Future<BlockSpec> _toBlock(GeminiDecision decision) async {
    switch (decision) {
      case GeminiText(:final text):
        return SummaryTextSpec(text: text);
      case GeminiFunctionCall(:final name, :final args):
        if (name != 'render_water_ui') {
          return _blocks.guidance();
        }
        return _renderWaterUi(args);
    }
  }

  Future<BlockSpec> _renderWaterUi(Map<String, dynamic> args) async {
    final blockType = (args['block_type'] as String?) ?? 'summary_text';
    final stationNames = _stringList(args['station_names']);
    final timeRange = (args['time_range'] as String?) ?? 'week';
    final count = _asInt(args['count']) ?? 5;
    final order = (args['order'] as String?) == 'lowest' ? 'asc' : 'desc';
    final summaryText = args['summary_text'] as String?;

    switch (blockType) {
      case 'stat_card':
        final station = await _resolveFirst(stationNames);
        if (station == null) return _blocks.clarify();
        return _blocks.currentLevel(station);

      case 'statistics':
        final station = await _resolveFirst(stationNames);
        if (station == null) return _blocks.clarify();
        final (window, labelAr) = _window(timeRange, statistics: true);
        return _blocks.statistics(station, window, labelAr);

      case 'line_chart':
        final station = await _resolveFirst(stationNames);
        if (station == null) return _blocks.clarify();
        final (window, labelAr) = _window(timeRange);
        return _blocks.history(station, window, labelAr);

      case 'multi_line_chart':
        final stations = await _resolveMany(stationNames);
        if (stations.length < 2) {
          return const SummaryTextSpec(
            text:
                'للمقارنة أحتاج اسمي محطتين على الأقل. مثال: "قارن سد الموصل وسد حديثة".',
          );
        }
        final (window, _) = _window(timeRange);
        return _blocks.compare(stations, window);

      case 'ranked_list':
        return _blocks.rank(count: count, order: order);

      case 'station_map':
        return _blocks.map();

      case 'alert_card':
        return _blocks.alerts();

      case 'summary_text':
        if (summaryText != null && summaryText.trim().isNotEmpty) {
          return SummaryTextSpec(text: summaryText.trim());
        }
        return _blocks.guidance();

      default:
        return _blocks.guidance();
    }
  }

  // --------------------------------------------------------------------------
  // Conversation turns
  // --------------------------------------------------------------------------

  /// Builds the turn list from [history] plus the new [userText] user turn.
  ///
  /// Assistant messages are rendered as a SHORT Arabic description of their
  /// block (e.g. "عرضتُ بطاقة منسوب لمحطة X") so prior context — especially the
  /// last referenced station — survives into the next decision.
  List<GeminiTurn> _buildTurns(String userText, List<ChatMessage> history) {
    final turns = <GeminiTurn>[];
    for (final message in history) {
      if (message.role == MessageRole.user) {
        final text = message.text;
        if (text != null && text.trim().isNotEmpty) {
          turns.add(GeminiTurn.user(text.trim()));
        }
      } else {
        final desc = _describeAssistant(message);
        if (desc.isNotEmpty) turns.add(GeminiTurn.model(desc));
      }
    }
    turns.add(GeminiTurn.user(userText));
    return turns;
  }

  /// A short Arabic description of an assistant turn for context carry-over.
  String _describeAssistant(ChatMessage message) {
    final block = message.block;
    switch (block) {
      case StatCardSpec():
        return 'عرضتُ بطاقة منسوب لمحطة ${block.title}.';
      case StatisticsSpec():
        return 'عرضتُ إحصائيات: ${block.title}.';
      case LineChartSpec():
        return 'عرضتُ مخطط تطوّر المنسوب: ${block.title}.';
      case MultiLineChartSpec():
        return 'عرضتُ مقارنة: ${block.title}.';
      case RankedListSpec():
        return 'عرضتُ قائمة مرتّبة: ${block.title}.';
      case StationMapSpec():
        return 'عرضتُ خريطة المحطات.';
      case AlertCardSpec():
        return 'عرضتُ تنبيهاً: ${block.title}.';
      case SummaryTextSpec():
        return block.text.trim();
      case null:
        return message.text?.trim() ?? '';
    }
  }

  // --------------------------------------------------------------------------
  // Station resolution helpers
  // --------------------------------------------------------------------------

  Future<Station?> _resolveFirst(List<String> names) async {
    for (final name in names) {
      final station = await _blocks.resolve(name);
      if (station != null) return station;
    }
    return null;
  }

  Future<List<Station>> _resolveMany(List<String> names) async {
    final resolved = <String, Station>{};
    for (final name in names) {
      final station = await _blocks.resolve(name);
      if (station != null) resolved[station.id] = station;
    }
    return resolved.values.toList();
  }

  // --------------------------------------------------------------------------
  // Argument coercion
  // --------------------------------------------------------------------------

  /// Maps a `time_range` enum to a (window, Arabic label) pair.
  ///
  /// When [statistics] is true an unspecified range defaults to 30 days (a
  /// month) rather than a week, since a numeric summary is most meaningful over
  /// a longer span; explicit day/month/year ranges are still honoured.
  (Duration, String) _window(String timeRange, {bool statistics = false}) {
    switch (timeRange) {
      case 'day':
        return (const Duration(days: 1), 'آخر يوم');
      case 'month':
        return (const Duration(days: 30), 'آخر شهر');
      case 'year':
        return (const Duration(days: 365), 'آخر سنة');
      case 'week':
        if (statistics) {
          return (const Duration(days: 30), 'آخر 30 يوماً');
        }
        return (const Duration(days: 7), 'آخر 7 أيام');
      default:
        if (statistics) {
          return (const Duration(days: 30), 'آخر 30 يوماً');
        }
        return (const Duration(days: 7), 'آخر 7 أيام');
    }
  }

  List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const <String>[];
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  ChatMessage _assistant(BlockSpec block) {
    return ChatMessage(
      id: _newId(),
      role: MessageRole.assistant,
      block: block,
      createdAt: DateTime.now().toUtc(),
    );
  }

  String _newId() =>
      'asst-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}
