import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:ma_water/data/models/enums.dart';

part 'station.freezed.dart';
part 'station.g.dart';

/// A water-level monitoring station.
///
/// Wire format (snake_case) is defined in PRD §9.2 `GET /stations`.
@freezed
abstract class Station with _$Station {
  const factory Station({
    required String id,
    required int number,
    @JsonKey(name: 'name_ar') required String nameAr,
    @JsonKey(name: 'name_en') required String nameEn,
    @JsonKey(name: 'water_body_ar') required String waterBodyAr,
    @JsonKey(name: 'water_body_en') required String waterBodyEn,
    @JsonKey(name: 'body_type') required WaterBodyType bodyType,
    @JsonKey(name: 'governorate_ar') required String governorateAr,
    @JsonKey(name: 'governorate_en') required String governorateEn,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'base_level_m') required double baseLevelM,
    @JsonKey(name: 'danger_high_m') required double dangerHighM,
    @JsonKey(name: 'danger_low_m') required double dangerLowM,
    @JsonKey(name: 'installed_at') required DateTime installedAt,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _Station;

  factory Station.fromJson(Map<String, dynamic> json) =>
      _$StationFromJson(json);
}
