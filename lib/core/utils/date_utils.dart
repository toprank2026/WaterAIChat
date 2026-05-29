/// Date/time helpers used across the app.
///
/// All helpers operate in **UTC** to stay consistent with the data model:
/// [WaterLevelReading.timestamp] is defined as "top of the hour, UTC"
/// (PRD §7.2). Relative-range helpers return an inclusive `(from, to)`
/// record where `to` is the current instant.
library;

/// A UTC `(from, to)` time range. `from` and `to` are both UTC instants.
typedef DateRange = ({DateTime from, DateTime to});

/// The current instant in UTC. Re-evaluated on every call (uses wall clock).
DateTime nowUtc() => DateTime.now().toUtc();

/// Truncates [t] to the top of its hour, in UTC.
///
/// Minutes, seconds, milliseconds and microseconds are zeroed. The result is
/// always a UTC [DateTime] regardless of the input's time zone.
DateTime startOfHour(DateTime t) {
  final u = t.toUtc();
  return DateTime.utc(u.year, u.month, u.day, u.hour);
}

/// Truncates [t] to midnight (start of day) in UTC.
DateTime startOfDay(DateTime t) {
  final u = t.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}

/// The UTC instant [n] days before [nowUtc].
///
/// [n] may be negative to look into the future.
DateTime daysAgo(int n) => nowUtc().subtract(Duration(days: n));

/// The UTC instant [n] hours before [nowUtc].
///
/// [n] may be negative to look into the future.
DateTime hoursAgo(int n) => nowUtc().subtract(Duration(hours: n));

/// Range covering the last 24 hours, ending now (UTC).
DateRange last24h() {
  final to = nowUtc();
  return (from: to.subtract(const Duration(hours: 24)), to: to);
}

/// Range covering the last 7 days, ending now (UTC).
DateRange last7Days() {
  final to = nowUtc();
  return (from: to.subtract(const Duration(days: 7)), to: to);
}

/// Range covering the last 30 days, ending now (UTC).
DateRange last30Days() {
  final to = nowUtc();
  return (from: to.subtract(const Duration(days: 30)), to: to);
}

/// Whether [a] and [b] fall on the same UTC calendar day.
bool isSameUtcDay(DateTime a, DateTime b) {
  final ua = a.toUtc();
  final ub = b.toUtc();
  return ua.year == ub.year && ua.month == ub.month && ua.day == ub.day;
}
