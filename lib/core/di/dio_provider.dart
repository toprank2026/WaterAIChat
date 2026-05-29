import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shared [Dio] HTTP client used by the Phase 2 API repository.
///
/// Base URL and defaults follow the Phase 2 contract (PRD §9.1). Auth headers
/// (`Authorization: Bearer <token>`) are out of scope for v1 and can be layered
/// on via an interceptor later. This provider is only consumed once the app is
/// switched to `ApiWaterStationRepository` in `providers.dart` (PRD §6.4).
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.iq/v1'));
});
