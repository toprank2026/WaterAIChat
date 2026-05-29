import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider moved to the legacy entry point in Riverpod 3.x.
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import 'package:ma_water/ai/anomaly_service.dart';
import 'package:ma_water/ai/heuristic_inference_service.dart';
import 'package:ma_water/ai/inference_service.dart';
import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/mock_water_station_repository.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';
import 'package:ma_water/ui/chat/chat_controller.dart';

/// **THE SWAP POINT** — the single place that binds the [WaterStationRepository]
/// interface to a concrete implementation.
///
/// Phase 1 uses [MockWaterStationRepository] (deterministic in-memory data).
/// Phase 2 swaps to `ApiWaterStationRepository` here and nowhere else; no call
/// site outside `lib/data/` may name a concrete repository type.
final waterStationRepositoryProvider = Provider<WaterStationRepository>((ref) {
  return const MockWaterStationRepository();
  // Phase 2 (Laravel API):
  // return ApiWaterStationRepository(dio: ref.read(dioProvider));
});

/// Proactive anomaly detection over the fleet (PRD §F5).
final anomalyServiceProvider = Provider<AnomalyService>((ref) {
  return AnomalyService(ref.read(waterStationRepositoryProvider));
});

/// Routes parsed tool calls to the repository (PRD §11.2).
final toolDispatcherProvider = Provider<ToolDispatcher>((ref) {
  return ToolDispatcher(ref.read(waterStationRepositoryProvider));
});

/// The active conversational engine. Defaults to the offline heuristic engine.
final inferenceServiceProvider = Provider<InferenceService>((ref) {
  return HeuristicInferenceService(ref.read(toolDispatcherProvider));
});

/// All stations, loaded once from the repository.
final stationsProvider = FutureProvider<List<Station>>((ref) {
  return ref.read(waterStationRepositoryProvider).getStations();
});

/// Active alerts produced by the proactive anomaly scan.
final alertsProvider = FutureProvider<List<Alert>>((ref) {
  return ref.read(anomalyServiceProvider).detectAll();
});

/// Text to prefill the composer with (e.g. from a tapped suggestion). `null`
/// when there is nothing pending.
final composerPrefillProvider = StateProvider<String?>((ref) => null);

/// Owns the chat transcript and drives the AI loop.
final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);
