import 'package:dio/dio.dart';

import 'package:ma_water/data/api/api_dtos.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/data/repositories/water_station_repository.dart';

/// Phase 2 [WaterStationRepository] backed by the Laravel HTTP API (PRD §9).
///
/// Hits the documented endpoints under the configured base URL and maps the
/// JSON envelopes to domain models via `api_dtos.dart`. All timestamps are sent
/// and parsed as ISO 8601 UTC (PRD §9.1).
///
/// This implementation is wired into the dependency graph in Phase 2 only; in
/// Phase 1 the app uses `MockWaterStationRepository`. It must nonetheless
/// compile and satisfy the [WaterStationRepository] contract.
class ApiWaterStationRepository implements WaterStationRepository {
  /// The configured Dio client (see `dioProvider`). Carries the base URL and
  /// any auth headers.
  final Dio dio;

  ApiWaterStationRepository({required this.dio});

  @override
  Future<List<Station>> getStations() async {
    final response = await dio.get<Map<String, dynamic>>('/stations');
    return _dataList(response.data).map(stationFromApi).toList();
  }

  @override
  Future<Station?> getStationById(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/stations/$id');
      final body = _asMap(response.data);
      // A single-resource endpoint may return the object directly or wrapped in
      // a `data` envelope; accept either shape.
      final raw = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      return stationFromApi(raw);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Station>> findStations(String query) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/stations',
      queryParameters: <String, dynamic>{'q': query},
    );
    return _dataList(response.data).map(stationFromApi).toList();
  }

  @override
  Future<List<WaterLevelReading>> getHistory({
    required String stationId,
    required DateTime from,
    required DateTime to,
    ReadingInterval interval = ReadingInterval.hour,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/stations/$stationId/readings',
      queryParameters: <String, dynamic>{
        'from': _iso(from),
        'to': _iso(to),
        'interval': _intervalParam(interval),
      },
    );
    final body = _asMap(response.data);
    // The readings envelope echoes its own `station_id`; trust it when present,
    // otherwise fall back to the requested id.
    final ownerId = (body['station_id'] as String?) ?? stationId;
    return _dataItems(body)
        .map((item) => readingFromApi(item, stationId: ownerId))
        .toList();
  }

  @override
  Future<CurrentLevel> getCurrentLevel(String stationId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/stations/$stationId/current',
    );
    return currentFromApi(_asMap(response.data));
  }

  @override
  Future<List<RankedStation>> rankStations({
    String by = 'level',
    String order = 'desc',
    int limit = 5,
    DateTime? at,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/stations/rank',
      queryParameters: <String, dynamic>{
        'by': by,
        'order': order,
        'limit': limit,
        // PRD §9.2 documents `at=now`; send the literal when no instant is
        // given, otherwise an explicit ISO 8601 UTC timestamp.
        'at': at == null ? 'now' : _iso(at),
      },
    );
    final items = _dataItems(_asMap(response.data));
    if (items.isEmpty) return const <RankedStation>[];

    // The rank endpoint returns only `{station_id, level_m, name_ar}` per item
    // (PRD §9.2), but [RankedStation] needs a full [Station]. Resolve the
    // stations in one fetch and join by id, preserving the server's order.
    final stationsById = <String, Station>{
      for (final s in await getStations()) s.id: s,
    };

    final ranked = <RankedStation>[];
    for (final item in items) {
      final id = item['station_id'] as String;
      final station = stationsById[id];
      if (station == null) continue; // skip unknown ids rather than crash
      ranked.add(
        RankedStation(
          station: station,
          levelM: (item['level_m'] as num).toDouble(),
        ),
      );
    }
    return ranked;
  }

  @override
  Future<List<Alert>> listAlerts({bool activeOnly = true}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/alerts',
      queryParameters: <String, dynamic>{'active': activeOnly},
    );
    return _dataList(response.data).map(alertFromApi).toList();
  }

  // ---------------------------------------------------------------------------
  // Envelope / serialization helpers
  // ---------------------------------------------------------------------------

  /// Casts a JSON response body to a `Map`, failing loudly on an unexpected
  /// shape (e.g. an error payload or `null`).
  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw FormatException('Expected a JSON object, got: ${data.runtimeType}');
  }

  /// Extracts and casts the `data` array from a `{"data": [...]}` envelope.
  List<Map<String, dynamic>> _dataList(Object? data) =>
      _dataItems(_asMap(data));

  /// Extracts and casts the `data` array from an already-decoded envelope map.
  List<Map<String, dynamic>> _dataItems(Map<String, dynamic> body) {
    final list = body['data'];
    if (list is! List) {
      throw const FormatException('Missing "data" array in response envelope');
    }
    return list.cast<Map<String, dynamic>>();
  }

  /// Formats a [DateTime] as an ISO 8601 UTC string (PRD §9.1).
  String _iso(DateTime dt) => dt.toUtc().toIso8601String();

  /// Maps a [ReadingInterval] to its wire value (`hour` | `day`, PRD §9.2).
  String _intervalParam(ReadingInterval interval) {
    switch (interval) {
      case ReadingInterval.hour:
        return 'hour';
      case ReadingInterval.day:
        return 'day';
    }
  }
}
