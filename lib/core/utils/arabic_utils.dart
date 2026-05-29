/// Arabic-language formatting helpers for user-facing strings.
///
/// All copy produced here is Arabic (the app is RTL, locale `ar_IQ`).
/// Numbers are rendered with Western (ASCII) digits, which is the common
/// convention for technical water-level readings in Iraqi usage and matches
/// the values shown throughout the PRD (e.g. "319.84 م").
library;

import 'package:intl/intl.dart';
import 'package:ma_water/data/models/enums.dart';

/// The Arabic word for "meters" used as the level unit suffix.
const String _metersUnitAr = 'م';

/// Two-decimal-place number formatter (Western digits).
final NumberFormat _levelFormat = NumberFormat('0.00', 'en');

/// Formats a water level in meters, e.g. `319.84` -> `"319.84 م"`.
String formatLevel(double m) => '${_levelFormat.format(m)} $_metersUnitAr';

/// Formats a signed delta in meters with an explicit sign and unit.
///
/// Examples: `0.42` -> `"+0.42 م"`, `-0.10` -> `"-0.10 م"`, `0.0` -> `"0.00 م"`.
String formatDelta(double d) {
  // Treat negative zero as zero so it never renders as "-0.00".
  final value = d == 0 ? 0.0 : d;
  final magnitude = _levelFormat.format(value.abs());
  final sign = value > 0
      ? '+'
      : value < 0
          ? '-'
          : '';
  return '$sign$magnitude $_metersUnitAr';
}

/// Arabic relative-time label for [t], relative to [now] (defaults to the
/// current instant in UTC).
///
/// Examples: `"الآن"`, `"قبل دقيقة"`, `"قبل 3 ساعات"`, `"اليوم"`, `"أمس"`,
/// `"قبل 5 أيام"`. Future instants fall back to `"الآن"`.
String relativeArabic(DateTime t, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toUtc();
  final target = t.toUtc();
  final diff = current.difference(target);

  // Future or essentially-now.
  if (diff.inSeconds <= 0) return 'الآن';

  final minutes = diff.inMinutes;
  if (minutes < 1) return 'الآن';
  if (minutes < 60) return _agoArabic(minutes, _minuteForms);

  final hours = diff.inHours;
  if (hours < 24) return _agoArabic(hours, _hourForms);

  // Day-granularity: use calendar-day labels for the recent past.
  final days = diff.inDays;
  if (days == 0) return 'اليوم';
  if (days == 1) return 'أمس';
  return _agoArabic(days, _dayForms);
}

/// Arabic label for a [StationStatus]: طبيعي / تحذير / خطر.
String statusLabelAr(StationStatus status) {
  switch (status) {
    case StationStatus.normal:
      return 'طبيعي';
    case StationStatus.warning:
      return 'تحذير';
    case StationStatus.danger:
      return 'خطر';
  }
}

// --- Arabic pluralization helpers -----------------------------------------

/// Pluralization forms for a unit: (singular, dual, plural-3-to-10, plural-11+).
typedef _UnitForms = ({String one, String two, String few, String many});

const _UnitForms _minuteForms =
    (one: 'دقيقة', two: 'دقيقتين', few: 'دقائق', many: 'دقيقة');
const _UnitForms _hourForms =
    (one: 'ساعة', two: 'ساعتين', few: 'ساعات', many: 'ساعة');
const _UnitForms _dayForms =
    (one: 'يوم', two: 'يومين', few: 'أيام', many: 'يوم');

/// Builds an Arabic "X ago" phrase applying CLDR-style number agreement.
///
/// Arabic agreement rules used here:
/// - 1   -> `قبل <singular>`            ("قبل دقيقة")
/// - 2   -> `قبل <dual>`                ("قبل دقيقتين")
/// - 3-10 -> `قبل N <few-plural>`       ("قبل 3 دقائق")
/// - 11+ -> `قبل N <singular-as-many>`  ("قبل 15 دقيقة")
String _agoArabic(int count, _UnitForms forms) {
  if (count == 1) return 'قبل ${forms.one}';
  if (count == 2) return 'قبل ${forms.two}';
  if (count >= 3 && count <= 10) return 'قبل $count ${forms.few}';
  return 'قبل $count ${forms.many}';
}
