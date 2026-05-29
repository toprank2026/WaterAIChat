import 'package:ma_water/ai/inference_service.dart';
import 'package:ma_water/ai/prompt_builder.dart';
import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/ui/chat/chat_models.dart';

/// On-device inference engine backed by `flutter_gemma`.
///
/// IMPORTANT — current status: this is a **stub**. The default engine for the
/// app is [HeuristicInferenceService] (pure Dart, no model required), so the
/// Gemma path is intentionally not wired yet and [respond] throws
/// [UnimplementedError]. This file deliberately does **not** import
/// `flutter_gemma` at the top level, so the project builds whether or not that
/// dependency is present in `pubspec.yaml`.
///
/// The constructor dependencies ([PromptBuilder], [ToolDispatcher]) are kept so
/// the wiring below can be filled in without changing call sites.
class GemmaInferenceService implements InferenceService {
  final PromptBuilder _promptBuilder;
  // ignore: unused_field — used by the TODO wiring below once Gemma is enabled.
  final ToolDispatcher _tools;

  GemmaInferenceService({
    required ToolDispatcher tools,
    PromptBuilder promptBuilder = const PromptBuilder(),
  })  : _tools = tools,
        _promptBuilder = promptBuilder;

  @override
  Future<ChatMessage> respond({
    required String userText,
    required List<ChatMessage> history,
  }) async {
    // Touch the prompt builder so the field is considered used and the wiring
    // contract (system prompt + conversation) is exercised even while stubbed.
    final _ = _promptBuilder.systemPrompt();

    throw UnimplementedError(
      'Gemma path not wired; default is HeuristicInferenceService',
    );

    // ------------------------------------------------------------------------
    // TODO(gemma): Wire flutter_gemma here. Reference implementation outline —
    // keep all flutter_gemma imports INSIDE this file (added at the top only
    // once the dependency is committed to pubspec.yaml) so the rest of the app
    // stays decoupled behind the [InferenceService] interface.
    //
    //   import 'package:flutter_gemma/flutter_gemma.dart';
    //
    //   // 1. Initialize / load the model once (typically during onboarding):
    //   final gemma = FlutterGemmaPlugin.instance;
    //   final model = await gemma.createModel(
    //     modelType: ModelType.gemmaIt,
    //     maxTokens: 1024,
    //   );
    //   final session = await model.createSession(temperature: 0.2, topK: 40);
    //
    //   // 2. Build the constrained prompt from PromptBuilder:
    //   final system = _promptBuilder.systemPrompt();          // Arabic rules
    //   final examples = _promptBuilder.fewShotExamples();     // few-shot turns
    //   final convo = _promptBuilder.renderConversation(
    //     userText: userText,
    //     history: history,
    //   );
    //   final prompt = StringBuffer()
    //     ..writeln(system)
    //     ..writeAll(examples, '\n\n')
    //     ..writeln()
    //     ..writeln(convo);
    //
    //   // 3. Tool-call loop (PRD §11.2 / §15 Arabic tool-calling risk):
    //   //    a. Send `prompt`; parse the model's `{"tool":..,"args":..}` JSON.
    //   //    b. Route the call through `_tools` (the ToolDispatcher), e.g.
    //   //       `_tools.getCurrentLevel(id)` / `_tools.getHistory(...)` etc.
    //   //    c. Append the tool result and re-prompt for the final block.
    //   //    d. On parse failure, retry once with a corrective Arabic hint.
    //   await session.addQueryChunk(Message.text(text: prompt.toString()));
    //   final raw = await session.getResponse();
    //
    //   // 4. Parse the single emitted block JSON and wrap it in a ChatMessage:
    //   final json = jsonDecode(_extractFirstJsonObject(raw))
    //       as Map<String, dynamic>;
    //   final block = BlockSpec.fromJson(json);  // from ui/genui_blocks/block_spec.dart
    //   return ChatMessage(
    //     id: 'asst-${DateTime.now().microsecondsSinceEpoch}',
    //     role: MessageRole.assistant,
    //     block: block,
    //     createdAt: DateTime.now().toUtc(),
    //   );
    // ------------------------------------------------------------------------
  }
}
