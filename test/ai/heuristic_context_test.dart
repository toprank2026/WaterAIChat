import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/ai/heuristic_inference_service.dart';
import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/data/repositories/mock_water_station_repository.dart';
import 'package:ma_water/ui/chat/chat_models.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Regression tests for conversational context carry-over in the heuristic
/// engine: a follow-up that refers to the previous station with a pronoun
/// ("لها") must resolve to that station instead of asking for clarification.
void main() {
  late HeuristicInferenceService engine;

  setUp(() {
    engine =
        HeuristicInferenceService(ToolDispatcher(MockWaterStationRepository()));
  });

  test('current-level question yields a StatCard carrying the station id',
      () async {
    final reply =
        await engine.respond(userText: 'ما مستوى سد الموصل؟', history: const []);
    expect(reply.block, isA<StatCardSpec>());
    expect((reply.block as StatCardSpec).stationId, isNotNull);
  });

  test('follow-up pronoun resolves to the last station from history', () async {
    final first =
        await engine.respond(userText: 'ما مستوى سد الموصل؟', history: const []);
    final stationId = (first.block as StatCardSpec).stationId;
    expect(stationId, isNotNull);

    final history = <ChatMessage>[
      ChatMessage(
        id: 'u1',
        role: MessageRole.user,
        text: 'ما مستوى سد الموصل؟',
        createdAt: DateTime.now().toUtc(),
      ),
      first,
    ];

    final follow = await engine.respond(
      userText: 'طيب اعرض المخطط لآخر شهر لها',
      history: history,
    );

    expect(follow.block, isA<LineChartSpec>(),
        reason: 'the follow-up should produce a chart, not a clarification');
    final chart = follow.block as LineChartSpec;
    expect(chart.stationId, stationId,
        reason: 'the pronoun "لها" must resolve to the previous station');
    expect(chart.title, contains('آخر شهر'),
        reason: '"آخر شهر" should select the 30-day window');
    expect(chart.points.length, greaterThan(20),
        reason: 'a month of daily points is ~30 samples');
  });

  test('a bare pronoun follow-up with no prior context asks to clarify',
      () async {
    final reply = await engine.respond(
      userText: 'اعرض المخطط لآخر شهر لها',
      history: const [],
    );
    expect(reply.block, isA<SummaryTextSpec>());
  });
}
