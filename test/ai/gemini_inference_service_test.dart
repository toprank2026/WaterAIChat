import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/ai/gemini_inference_service.dart';
import 'package:ma_water/ai/inference_service.dart';
import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/data/repositories/mock_water_station_repository.dart';
import 'package:ma_water/ui/chat/chat_models.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// A fake Dio [HttpClientAdapter] that never hits the network: it either
/// returns a canned [responseJson] body (status 200), or throws when
/// [shouldThrow] is set — exercising the success and error paths respectively.
class _FakeAdapter implements HttpClientAdapter {
  final String? responseJson;
  final bool shouldThrow;

  _FakeAdapter.success(this.responseJson) : shouldThrow = false;
  _FakeAdapter.failing()
      : responseJson = null,
        shouldThrow = true;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (shouldThrow) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'fake network failure',
      );
    }
    return ResponseBody.fromString(
      responseJson!,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A stub [InferenceService] whose [respond] always returns the same canned
/// [block]. Used to assert the Gemini service defers to its fallback on error.
class _StubFallback implements InferenceService {
  final BlockSpec block;

  _StubFallback(this.block);

  @override
  Future<ChatMessage> respond({
    required String userText,
    required List<ChatMessage> history,
  }) async {
    return ChatMessage(
      id: 'fallback-1',
      role: MessageRole.assistant,
      block: block,
      createdAt: DateTime.now().toUtc(),
    );
  }
}

/// Builds a canned `generateContent` response whose single candidate carries a
/// `render_water_ui` function call with the given [args].
String _functionCallResponse(Map<String, dynamic> args) {
  return jsonEncode({
    'candidates': [
      {
        'content': {
          'role': 'model',
          'parts': [
            {
              'functionCall': {
                'name': 'render_water_ui',
                'args': args,
              },
            },
          ],
        },
      },
    ],
  });
}

void main() {
  late ToolDispatcher tools;

  setUp(() {
    tools = ToolDispatcher(const MockWaterStationRepository());
  });

  test(
      'function call render_water_ui(stat_card) yields a StatCardSpec with a '
      'non-null stationId', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter.success(
        _functionCallResponse({
          'block_type': 'stat_card',
          'station_names': ['سد الموصل'],
        }),
      );

    final service = GeminiInferenceService(
      tools: tools,
      apiKey: 'test-key',
      dio: dio,
    );

    final reply = await service.respond(
      userText: 'شكد منسوب سد الموصل؟',
      history: const [],
    );

    expect(reply.role, MessageRole.assistant);
    expect(reply.block, isA<StatCardSpec>());
    expect((reply.block as StatCardSpec).stationId, isNotNull);
  });

  test('on adapter error, respond returns the fallback service\'s block',
      () async {
    final dio = Dio()..httpClientAdapter = _FakeAdapter.failing();

    const fallbackBlock = SummaryTextSpec(text: 'رد احتياطي');
    final service = GeminiInferenceService(
      tools: tools,
      apiKey: 'test-key',
      dio: dio,
      fallback: _StubFallback(fallbackBlock),
    );

    final reply = await service.respond(
      userText: 'ما مستوى سد الموصل؟',
      history: const [],
    );

    expect(reply.block, isA<SummaryTextSpec>());
    expect((reply.block as SummaryTextSpec).text, 'رد احتياطي');
  });
}
