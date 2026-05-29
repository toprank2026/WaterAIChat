import 'package:ma_water/data/mock/mock_stations_dams.dart';
import 'package:ma_water/data/mock/mock_stations_diyala.dart';
import 'package:ma_water/data/mock/mock_stations_euphrates.dart';
import 'package:ma_water/data/mock/mock_stations_khabur_shatt.dart';
import 'package:ma_water/data/mock/mock_stations_lakes.dart';
import 'package:ma_water/data/mock/mock_stations_tigris.dart';
import 'package:ma_water/data/mock/mock_stations_zab.dart';
import 'package:ma_water/data/models/station.dart';

/// Canonical mock station dataset for "Mā".
///
/// Aggregates every per-water-body chunk into a single flat list.
///
/// INVARIANT: [mockStations] MUST contain exactly 100 stations
/// (IDs STN-001..STN-100). [mockStationCount] is provided so callers/tests
/// can assert this; do not add or remove entries here — edit the source
/// chunk files instead.
final List<Station> mockStations = <Station>[
  ...tigrisStations,
  ...euphratesStations,
  ...damsStations,
  ...lakesStations,
  ...greaterZabStations,
  ...lesserZabStations,
  ...diyalaStations,
  ...adhaimStations,
  ...khaburStations,
  ...shattAlArabStations,
];

/// Fast lookup of a [Station] by its `id` (e.g. `'STN-001'`).
final Map<String, Station> mockStationsById = <String, Station>{
  for (final s in mockStations) s.id: s,
};

/// Total number of mock stations. MUST equal 100.
int get mockStationCount => mockStations.length;
