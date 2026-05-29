import 'package:dio/dio.dart';

/// One conversational turn sent to Gemini. [isUser] selects the wire role
/// (`user` vs `model`); [text] is the plain content for that turn.
class GeminiTurn {
  final bool isUser;
  final String text;

  const GeminiTurn({required this.isUser, required this.text});

  /// Convenience constructor for a user turn.
  const GeminiTurn.user(this.text) : isUser = true;

  /// Convenience constructor for a model (assistant) turn.
  const GeminiTurn.model(this.text) : isUser = false;
}

/// The outcome of a single Gemini decision: either a tool/function call the
/// model wants the app to execute, or a plain-text reply.
///
/// Sealed so callers must handle both arms exhaustively.
sealed class GeminiDecision {
  const GeminiDecision();

  /// The model asked to invoke [name] with [args].
  const factory GeminiDecision.functionCall(
    String name,
    Map<String, dynamic> args,
  ) = GeminiFunctionCall;

  /// The model replied with free [text].
  const factory GeminiDecision.text(String text) = GeminiText;
}

/// A function-call decision (`functionCall` part in the Gemini response).
class GeminiFunctionCall extends GeminiDecision {
  final String name;
  final Map<String, dynamic> args;

  const GeminiFunctionCall(this.name, this.args);
}

/// A plain-text decision (joined text parts in the Gemini response).
class GeminiText extends GeminiDecision {
  final String text;

  const GeminiText(this.text);
}

/// Thrown when the Gemini response cannot be parsed into a [GeminiDecision]
/// (e.g. no candidates, or a candidate with neither a function call nor text).
class GeminiClientException implements Exception {
  final String message;

  const GeminiClientException(this.message);

  @override
  String toString() => 'GeminiClientException: $message';
}

/// Thin client over the Gemini `generateContent` REST endpoint.
///
/// Stateless: each [decide] call is a single POST. Function calling is forced
/// (`tool_config.function_calling_config.mode = ANY`) so the model is steered
/// toward `render_water_ui`; a text reply is still handled defensively.
class GeminiClient {
  final String apiKey;
  final String model;
  final Dio _dio;

  GeminiClient({
    required this.apiKey,
    Dio? dio,
    this.model = 'gemini-2.5-flash-lite',
  }) : _dio = dio ?? Dio();

  /// Max attempts for transient (503 UNAVAILABLE / 429 RESOURCE_EXHAUSTED)
  /// failures. Free-tier flash models occasionally return 503 under load.
  static const int _maxAttempts = 3;

  /// Sends [systemPrompt] + [turns] + the single [functionDeclaration] to
  /// Gemini and returns its [GeminiDecision].
  ///
  /// Throws [DioException] on transport/HTTP errors and
  /// [GeminiClientException] when the payload is well-formed JSON but carries
  /// no usable candidate.
  Future<GeminiDecision> decide({
    required String systemPrompt,
    required List<GeminiTurn> turns,
    required Map<String, dynamic> functionDeclaration,
  }) async {
    final uri =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

    final body = <String, dynamic>{
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        for (final turn in turns)
          {
            'role': turn.isUser ? 'user' : 'model',
            'parts': [
              {'text': turn.text},
            ],
          },
      ],
      'tools': [
        {
          'function_declarations': [functionDeclaration],
        },
      ],
      'tool_config': {
        'function_calling_config': {'mode': 'ANY'},
      },
    };

    final options = Options(
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );

    DioException? lastError;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await _dio.post<dynamic>(
          uri,
          queryParameters: {'key': apiKey},
          data: body,
          options: options,
        );
        return _parse(response.data);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final transient = status == 503 || status == 429;
        if (transient && attempt < _maxAttempts - 1) {
          lastError = e;
          // Linear backoff: 800ms, 1600ms. Keeps total latency tolerable while
          // riding out brief free-tier 503 spikes.
          await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
    throw lastError ?? const GeminiClientException('Gemini request failed.');
  }

  /// Parses a `generateContent` response body into a [GeminiDecision].
  GeminiDecision _parse(Object? data) {
    final map = _asMap(data);
    if (map == null) {
      throw const GeminiClientException('Empty or non-object response.');
    }

    final candidates = map['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiClientException('Response has no candidates.');
    }

    final content = _asMap(candidates.first)?['content'];
    final parts = _asMap(content)?['parts'];
    if (parts is! List) {
      throw const GeminiClientException('Candidate has no content parts.');
    }

    // Prefer a function call if any part carries one.
    for (final part in parts) {
      final partMap = _asMap(part);
      final fc = _asMap(partMap?['functionCall']);
      if (fc != null) {
        final name = fc['name'] as String? ?? '';
        final args = _asMap(fc['args']) ?? <String, dynamic>{};
        return GeminiDecision.functionCall(name, args);
      }
    }

    // Otherwise join any text parts.
    final buffer = StringBuffer();
    for (final part in parts) {
      final text = _asMap(part)?['text'];
      if (text is String) buffer.write(text);
    }
    final joined = buffer.toString().trim();
    if (joined.isEmpty) {
      throw const GeminiClientException(
        'Candidate has neither a function call nor text.',
      );
    }
    return GeminiDecision.text(joined);
  }

  /// Coerces [value] into a `Map<String, dynamic>` when possible, else `null`.
  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
