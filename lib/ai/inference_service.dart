import 'package:ma_water/ui/chat/chat_models.dart';

/// Contract for the conversational engine that turns a user's Arabic message
/// into an assistant [ChatMessage] (text and/or a single generative-UI block).
///
/// Two implementations exist:
/// - [HeuristicInferenceService] — the **default** engine. Pure Dart keyword
///   heuristics over the Arabic text; requires no model and runs fully offline.
/// - `GemmaInferenceService` — wraps `flutter_gemma` (currently a stub; see
///   `gemma_service.dart`). Wired later behind the same interface so the rest
///   of the app never depends on which engine is active.
abstract interface class InferenceService {
  /// Produces an assistant reply for [userText], given the prior [history]
  /// (oldest-first). The returned message has `role == MessageRole.assistant`
  /// and typically carries a [BlockSpec] in `block` and/or prose in `text`.
  Future<ChatMessage> respond({
    required String userText,
    required List<ChatMessage> history,
  });
}
