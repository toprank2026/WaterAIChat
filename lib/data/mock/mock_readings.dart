import 'dart:math';

import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/station.dart';

/// Deterministic synthetic water-level reading generator (PRD §8.3).
///
/// The goal is full reproducibility for demos: the level for a given
/// `(station, timestamp)` pair MUST be identical no matter what `from`/`to`
/// window is requested.
///
/// Determinism design note:
/// We do NOT advance a single [Random] across the hourly loop. Doing so would
/// couple each value to the window start (the Nth iteration would depend on how
/// many `nextDouble()` calls preceded it), so `generateReadings(from: A)` and
/// `generateReadings(from: B)` would disagree on overlapping hours. Instead we
/// re-seed a fresh [Random] on every iteration from a stable hash of the
/// station id and the truncated-to-hour timestamp
/// (`Object.hash(station.id, t.year, t.month, t.day, t.hour)`). The same
/// `(station, hour)` therefore always produces the same noise and anomaly draw,
/// independent of the requested window.

/// Builds the per-hour RNG. Seeding from the station id plus the hour-resolution
/// timestamp components guarantees stable output per `(station, hour)`.
Random _rngFor(Station station, DateTime t) {
  final seed = Object.hash(
    station.id,
    t.year,
    t.month,
    t.day,
    t.hour,
  );
  return Random(seed);
}

/// Computes the deterministic water level (meters, 3 decimals) for [station]
/// at the top of the hour containing [t].
double levelAt(Station station, DateTime t) {
  // Normalize to the top of the hour so sub-hour timestamps map to one reading.
  final hour = DateTime(t.year, t.month, t.day, t.hour);
  final rng = _rngFor(station, hour);

  // 1. Seasonal base: sinusoidal over the year.
  final dayOfYear = hour.difference(DateTime(hour.year)).inDays;
  final seasonal =
      sin(2 * pi * dayOfYear / 365) *
      (station.dangerHighM - station.baseLevelM) *
      0.35;

  // 2. Daily cycle: small sinusoidal over 24h.
  final daily = sin(2 * pi * hour.hour / 24) * 0.15;

  // 3. Noise.
  final noise = (rng.nextDouble() - 0.5) * 0.08;

  // 4. Occasional anomaly (~1% of readings).
  final anomaly = rng.nextDouble() < 0.01 ? (rng.nextDouble() * 1.2) : 0.0;

  final level = station.baseLevelM + seasonal + daily + noise + anomaly;
  return double.parse(level.toStringAsFixed(3));
}

/// Builds the deterministic [WaterLevelReading] for [station] at the top of the
/// hour containing [t].
WaterLevelReading readingAt(Station station, DateTime t) {
  final hour = DateTime(t.year, t.month, t.day, t.hour);
  return WaterLevelReading(
    stationId: station.id,
    timestamp: hour,
    levelM: levelAt(station, hour),
  );
}

/// Generates hourly [WaterLevelReading]s for [station] across `[from, to)`
/// (the `to` bound is exclusive).
///
/// Output is window-independent: any overlapping hour shared by two different
/// windows yields the identical reading.
List<WaterLevelReading> generateReadings({
  required Station station,
  required DateTime from,
  required DateTime to,
}) {
  final readings = <WaterLevelReading>[];
  for (
    var t = from;
    t.isBefore(to);
    t = t.add(const Duration(hours: 1))
  ) {
    readings.add(readingAt(station, t));
  }
  return readings;
}
