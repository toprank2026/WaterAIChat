import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ma_water/ai/inference_service.dart';
import 'package:ma_water/core/di/providers.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/chat/chat_models.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Immutable state for the chat screen: the ordered transcript and whether the
/// assistant is currently producing a reply.
class ChatState {
  /// Transcript, oldest-first. Capped at [ChatController.maxMessages].
  final List<ChatMessage> messages;

  /// `true` while a user message is being answered (a loading assistant
  /// placeholder is present in [messages]).
  final bool isResponding;

  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isResponding = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isResponding,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isResponding: isResponding ?? this.isResponding,
    );
  }
}

/// Drives one user message through the AI loop and owns the chat transcript.
///
/// On [build] the transcript is seeded with an Arabic welcome message and, when
/// the proactive anomaly scan reports critical alerts, a leading [AlertCardSpec]
/// summarising the most urgent situation.
class ChatController extends Notifier<ChatState> {
  /// Maximum messages retained in the transcript; older ones are dropped.
  static const int maxMessages = 50;

  /// Monotonic id source for locally-authored messages.
  int _idCounter = 0;

  @override
  ChatState build() {
    final messages = <ChatMessage>[_welcomeMessage()];
    final state = ChatState(messages: List.unmodifiable(messages));
    // Kick off the proactive critical-alert scan without blocking build().
    _maybePrependCriticalAlert();
    return state;
  }

  /// Resets the transcript to just the welcome message and re-runs the
  /// proactive critical-alert scan.
  void seedWelcome() {
    _idCounter = 0;
    state = ChatState(messages: List.unmodifiable(<ChatMessage>[_welcomeMessage()]));
    _maybePrependCriticalAlert();
  }

  /// Sends a user [text]: appends the user message and a loading assistant
  /// placeholder, asks the [InferenceService] for a reply, then replaces the
  /// placeholder with the result. No-op for blank input or while responding.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isResponding) return;

    final history = List<ChatMessage>.of(state.messages);
    final userMessage = ChatMessage(
      id: _nextId('user'),
      role: MessageRole.user,
      text: trimmed,
      createdAt: DateTime.now().toUtc(),
    );
    final placeholderId = _nextId('asst');
    final placeholder = ChatMessage(
      id: placeholderId,
      role: MessageRole.assistant,
      createdAt: DateTime.now().toUtc(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: _capped([...state.messages, userMessage, placeholder]),
      isResponding: true,
    );

    ChatMessage reply;
    try {
      final inference = ref.read(inferenceServiceProvider);
      final result = await inference.respond(
        userText: trimmed,
        history: history,
      );
      reply = result.copyWith(id: placeholderId, isLoading: false);
    } catch (_) {
      reply = ChatMessage(
        id: placeholderId,
        role: MessageRole.assistant,
        block: const SummaryTextSpec(
          text: 'تعذّر إكمال الطلب حالياً. حاول مرة أخرى من فضلك.',
        ),
        createdAt: DateTime.now().toUtc(),
      );
    }

    state = state.copyWith(
      messages: _replaceById(state.messages, placeholderId, reply),
      isResponding: false,
    );
  }

  // --------------------------------------------------------------------------
  // Proactive alerts
  // --------------------------------------------------------------------------

  /// Runs the proactive anomaly scan and, if any critical alerts exist, inserts
  /// a leading [AlertCardSpec] message after the welcome. Failures are silently
  /// ignored so a flaky scan never blocks the chat.
  Future<void> _maybePrependCriticalAlert() async {
    List<Alert> alerts;
    try {
      alerts = await ref.read(alertsProvider.future);
    } catch (_) {
      return;
    }

    final critical = alerts
        .where((a) => a.severity == AlertSeverity.critical)
        .toList();
    if (critical.isEmpty) return;

    final alert = critical.first;
    final card = ChatMessage(
      id: _nextId('alert'),
      role: MessageRole.assistant,
      block: AlertCardSpec(
        severity: alert.severity,
        title: _alertTitle(alert.kind),
        body: alert.messageAr,
        stationId: alert.stationId,
        aiNote: critical.length > 1
            ? 'يوجد ${critical.length} تنبيهات حرجة نشطة. اسألني "هل توجد تنبيهات؟" للمزيد.'
            : null,
      ),
      createdAt: DateTime.now().toUtc(),
    );

    // Insert right after the welcome message (index 0) if present.
    final current = List<ChatMessage>.of(state.messages);
    final insertAt = current.isEmpty ? 0 : 1;
    current.insert(insertAt, card);
    state = state.copyWith(messages: _capped(current));
  }

  String _alertTitle(AlertKind kind) {
    switch (kind) {
      case AlertKind.suddenChange:
        return 'تغيّر مفاجئ في المنسوب';
      case AlertKind.threshold:
        return 'تجاوز حد الخطر';
      case AlertKind.trendDeviation:
        return 'انحراف في الاتجاه الموسمي';
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  ChatMessage _welcomeMessage() {
    return ChatMessage(
      id: _nextId('welcome'),
      role: MessageRole.assistant,
      block: const SummaryTextSpec(
        text: 'أهلاً بك في "ماء"، مساعد مناسيب المياه في العراق.\n'
            'اسألني عن مستوى أي محطة، أو قارن محطتين، أو اعرض الأعلى منسوباً، '
            'أو تحقّق من التنبيهات النشطة.',
      ),
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// Replaces the message whose id equals [id] with [replacement], preserving
  /// order. Returns an unmodifiable list.
  List<ChatMessage> _replaceById(
    List<ChatMessage> messages,
    String id,
    ChatMessage replacement,
  ) {
    final next = messages
        .map((m) => m.id == id ? replacement : m)
        .toList(growable: false);
    return List.unmodifiable(next);
  }

  /// Caps [messages] to the most recent [maxMessages] and returns an
  /// unmodifiable list.
  List<ChatMessage> _capped(List<ChatMessage> messages) {
    final capped = messages.length > maxMessages
        ? messages.sublist(messages.length - maxMessages)
        : messages;
    return List.unmodifiable(capped);
  }

  String _nextId(String prefix) => '$prefix-${_idCounter++}';
}
