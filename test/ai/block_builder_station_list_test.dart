import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/ai/block_builder.dart';
import 'package:ma_water/ai/tool_dispatcher.dart';
import 'package:ma_water/data/repositories/mock_water_station_repository.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Verifies the station-list builder, including the fallback that a filter
/// matching nothing (e.g. an echoed English phrase) returns the full fleet
/// rather than an empty list.
void main() {
  late BlockBuilder builder;

  setUp(() {
    builder = BlockBuilder(ToolDispatcher(const MockWaterStationRepository()));
  });

  test('no filter lists all 100 stations', () async {
    final block = await builder.stationList();
    expect(block, isA<StationListSpec>());
    expect((block as StationListSpec).count, 100);
  });

  test('a non-matching filter falls back to all stations (not empty)', () async {
    final block = await builder.stationList(filter: 'all water stations');
    expect((block as StationListSpec).count, 100);
    expect(block.items, isNotEmpty);
  });

  test('a real water-body filter narrows the list', () async {
    final block = await builder.stationList(filter: 'دجلة') as StationListSpec;
    expect(block.count, greaterThan(0));
    expect(block.count, lessThan(100));
  });
}
