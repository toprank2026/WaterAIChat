import 'package:flutter_test/flutter_test.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Verifies that [BlockSpec.fromJson] dispatches the `station_list` block to a
/// [StationListSpec] and parses its title, total count, and list of
/// [StationListItem]s (station id, name, water body, governorate, and optional
/// status). The JSON shape is copied from the STATION-LIST BLOCK pinned
/// contract.
void main() {
  group('BlockSpec.fromJson station_list -> StationListSpec', () {
    test('parses title, count and items (station_id, name, status)', () {
      final json = <String, dynamic>{
        'type': 'station_list',
        'title': 'المحطات',
        'count': 100,
        'items': <Map<String, dynamic>>[
          {
            'station_id': 'STN-047',
            'name': 'محطة سد الموصل',
            'water_body': 'نهر دجلة',
            'governorate': 'نينوى',
            'status': 'normal',
          },
          {
            'station_id': 'STN-091',
            'name': 'محطة سد حديثة',
            'water_body': 'نهر الفرات',
            'governorate': 'الأنبار',
            'status': 'warning',
          },
        ],
      };

      final spec = BlockSpec.fromJson(json);

      expect(spec, isA<StationListSpec>());
      final list = spec as StationListSpec;
      expect(list.title, 'المحطات');
      expect(list.count, 100);
      expect(list.items, hasLength(2));

      final first = list.items[0];
      expect(first.stationId, 'STN-047');
      expect(first.name, 'محطة سد الموصل');
      expect(first.waterBody, 'نهر دجلة');
      expect(first.governorate, 'نينوى');
      expect(first.status, StationStatus.normal);

      final second = list.items[1];
      expect(second.stationId, 'STN-091');
      expect(second.name, 'محطة سد حديثة');
      expect(second.status, StationStatus.warning);
    });

    test('missing items degrades to an empty list, not a throw', () {
      final spec = BlockSpec.fromJson(<String, dynamic>{
        'type': 'station_list',
        'title': 'بدون محطات',
        'count': 0,
      });

      expect(spec, isA<StationListSpec>());
      final list = spec as StationListSpec;
      expect(list.title, 'بدون محطات');
      expect(list.count, 0);
      expect(list.items, isEmpty);
    });

    test('optional fields and unknown status parse to null', () {
      final spec = BlockSpec.fromJson(<String, dynamic>{
        'type': 'station_list',
        'title': 'محطات بحقول ناقصة',
        'count': 1,
        'items': <Map<String, dynamic>>[
          {'station_id': 'STN-001', 'name': 'محطة بلا بيانات', 'status': 'bogus'},
        ],
      });

      final list = spec as StationListSpec;
      expect(list.items, hasLength(1));
      final only = list.items.first;
      expect(only.stationId, 'STN-001');
      expect(only.name, 'محطة بلا بيانات');
      expect(only.waterBody, isNull);
      expect(only.governorate, isNull);
      expect(only.status, isNull);
    });
  });
}
