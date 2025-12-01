import 'dart:math' as math;

/// Utilities to compute statistics from the attendance map structure used in
/// AttendanceFirestoreService and AttendanceTable.
///
/// Expected structure:
/// attendance[dateKey][itemId] = {
///   'present': List<String>,
///   'absent': List<String>,
///   'onLeave': List<String>,
///   'default': List<String>,
///   'lateMinutes': Map<String,int> // optional
/// }
/// attendance['roster'] = List<String> // optional pre-filtered to relevant users

enum TimeGranularity { week, month, quarter, year }

class RatingPoint {
  final DateTime start; // bucket start day inclusive
  final double rating; // 0..1
  RatingPoint(this.start, this.rating);
}

class HistoryBar {
  final DateTime start; // bucket start
  final int present; // count of present
  final int onLeave; // count of onLeave
  int get totalPositive => present + onLeave;
  HistoryBar(this.start, {required this.present, required this.onLeave});
}

class SeriesRun {
  final DateTime start;
  final DateTime end; // inclusive
  int get length => end.difference(start).inDays + 1;
  SeriesRun(this.start, this.end);
}

class HeatCell {
  final int weekday; // 1..7 (Mon..Sun)
  final int year;
  final int count;
  HeatCell(this.weekday, this.year, this.count);
}

DateTime _parseKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String _fmt(DateTime d) {
  String two(int v) => v < 10 ? '0$v' : '$v';
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

// Public helpers for other files
DateTime parseDateKey(String key) => _parseKey(key);
String formatDateKey(DateTime d) => _fmt(d);

/// Build a normalized list of date keys for an item subject to its allowed weekdays.
List<String> normalizedDatesForItem(Map<String, dynamic> attendance, String itemId, {List<int>? weekdays}) {
  final List<String> keys = attendance.keys
      .where((k) => k != 'roster')
      .where((k) => attendance[k] is Map && (attendance[k][itemId] is Map))
      .cast<String>()
      .toList();
  keys.sort((a, b) => _parseKey(a).compareTo(_parseKey(b))); // ascending
  if (weekdays == null || weekdays.length == 7) return keys;
  final wdSet = weekdays.toSet();
  return keys.where((k) => wdSet.contains(_parseKey(k).weekday)).toList();
}

class TotalsSnapshot {
  final int present;
  final int onLeave;
  final int absent;
  final int defaulted;
  final int rosterSize;
  const TotalsSnapshot(this.present, this.onLeave, this.absent, this.defaulted, this.rosterSize);
}

TotalsSnapshot totalsForDate(Map<String, dynamic> attendance, String dateKey, String itemId, {List<String>? roster}) {
  final dateRec = attendance[dateKey] as Map<String, dynamic>?;
  final rec = dateRec == null ? null : (dateRec[itemId] as Map<String, dynamic>?);
  final present = (rec == null ? const <String>[] : (rec['present'] as List?)?.cast<String>() ?? const <String>[]).length;
  final onLeave = (rec == null ? const <String>[] : (rec['onLeave'] as List?)?.cast<String>() ?? const <String>[]).length;
  final absent = (rec == null ? const <String>[] : (rec['absent'] as List?)?.cast<String>() ?? const <String>[]).length;
  final def = (rec == null ? const <String>[] : (rec['default'] as List?)?.cast<String>() ?? const <String>[]).length;
  final rosterSize = roster?.length ?? (attendance['roster'] as List?)?.length ?? (present + onLeave + absent + def);
  return TotalsSnapshot(present, onLeave, absent, def, rosterSize);
}

/// Rating uses (present + onLeave) / roster for each period.
List<RatingPoint> computeRatingSeries(Map<String, dynamic> attendance, String itemId, {
  required TimeGranularity granularity,
  List<int>? weekdays,
  List<String>? roster,
}) {
  final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  if (keys.isEmpty) return const [];

  final Map<String, List<String>> buckets = {};
  for (final k in keys) {
    final dt = _parseKey(k);
    late DateTime bucketStart;
    switch (granularity) {
      case TimeGranularity.week:
        bucketStart = dt.subtract(Duration(days: dt.weekday - 1)); // Monday start
        break;
      case TimeGranularity.month:
        bucketStart = DateTime(dt.year, dt.month, 1);
        break;
      case TimeGranularity.quarter:
        final qStartMonth = ((dt.month - 1) ~/ 3) * 3 + 1;
        bucketStart = DateTime(dt.year, qStartMonth, 1);
        break;
      case TimeGranularity.year:
        bucketStart = DateTime(dt.year, 1, 1);
        break;
    }
    final id = _fmt(bucketStart);
    (buckets[id] ??= <String>[]).add(k);
  }

  final points = <RatingPoint>[];
  final r = roster ?? (attendance['roster'] as List?)?.cast<String>();
  final rosterSize = (r ?? const <String>[]).isEmpty ? null : r!.length;
  final entries = buckets.entries.toList()
    ..sort((a, b) => _parseKey(a.key).compareTo(_parseKey(b.key)));
  for (final e in entries) {
    final start = _parseKey(e.key);
    int present = 0;
    int leave = 0;
    int rosterRef = 0;
    for (final dayKey in e.value) {
      final t = totalsForDate(attendance, dayKey, itemId, roster: r);
      present += t.present;
      leave += t.onLeave;
      rosterRef += (rosterSize ?? t.rosterSize);
    }
    final rating = rosterRef == 0 ? 0.0 : (present + leave) / rosterRef;
    points.add(RatingPoint(start, rating));
  }
  return points;
}

/// History absolute counts for present and onLeave per bucket.
List<HistoryBar> computeHistoryBars(Map<String, dynamic> attendance, String itemId, {
  required TimeGranularity granularity,
  List<int>? weekdays,
}) {
  final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  final Map<String, List<String>> buckets = {};
  for (final k in keys) {
    final dt = _parseKey(k);
    late DateTime start;
    switch (granularity) {
      case TimeGranularity.week:
        start = dt.subtract(Duration(days: dt.weekday - 1));
        break;
      case TimeGranularity.month:
        start = DateTime(dt.year, dt.month, 1);
        break;
      case TimeGranularity.quarter:
        final q = ((dt.month - 1) ~/ 3) * 3 + 1;
        start = DateTime(dt.year, q, 1);
        break;
      case TimeGranularity.year:
        start = DateTime(dt.year, 1, 1);
        break;
    }
    (buckets[_fmt(start)] ??= <String>[]).add(k);
  }
  final bars = <HistoryBar>[];
  final entries = buckets.entries.toList()
    ..sort((a, b) => _parseKey(a.key).compareTo(_parseKey(b.key)));
  for (final e in entries) {
    int p = 0, l = 0;
    for (final day in e.value) {
      final t = totalsForDate(attendance, day, itemId);
      p += t.present;
      l += t.onLeave; // treated positive
    }
    bars.add(HistoryBar(_parseKey(e.key), present: p, onLeave: l));
  }
  return bars;
}

/// Compute best consecutive presence streaks. onLeave does not break the series.
List<SeriesRun> computeBestSeries(Map<String, dynamic> attendance, String itemId, {List<int>? weekdays, int limit = 10}) {
  final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  if (keys.isEmpty) return const [];
  DateTime? runStart;
  DateTime? lastDate;
  int bestLen = 0;
  final runs = <SeriesRun>[];
  for (final k in keys) {
    final dt = _parseKey(k);
    final t = totalsForDate(attendance, k, itemId);
    final positive = (t.present + t.onLeave) > 0; // at least someone present/leave
    if (positive) {
      if (runStart == null) {
        runStart = dt;
      } else if (lastDate != null) {
        // fill gaps by 1 day increments irrespective of weekdays selection
        final expectedNext = lastDate.add(const Duration(days: 1));
        if (dt.difference(expectedNext).inDays > 0) {
          // gap -> close previous run
          runs.add(SeriesRun(runStart, lastDate));
          bestLen = math.max(bestLen, runs.last.length);
          runStart = dt;
        }
      }
      lastDate = dt;
    } else {
      if (runStart != null && lastDate != null) {
        runs.add(SeriesRun(runStart, lastDate));
        bestLen = math.max(bestLen, runs.last.length);
      }
      runStart = null;
      lastDate = null;
    }
  }
  if (runStart != null && lastDate != null) {
    runs.add(SeriesRun(runStart, lastDate));
  }
  runs.sort((a, b) => b.length.compareTo(a.length));
  return runs.take(limit).toList();
}

/// Build a calendar marking presence/onLeave as positive. Returns a set of day keys.
Set<String> calendarPositiveDays(Map<String, dynamic> attendance, String itemId, {List<int>? weekdays}) {
  final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  final Set<String> result = {};
  for (final k in keys) {
    final t = totalsForDate(attendance, k, itemId);
    if (t.present + t.onLeave > 0) result.add(k);
  }
  return result;
}

/// Heatmap cells: year x weekday counts of positive days.
List<HeatCell> computeHeatmap(Map<String, dynamic> attendance, String itemId, {List<int>? weekdays}) {
  final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  final Map<int, Map<int, int>> byYearWeekday = {}; // year -> weekday -> count
  for (final k in keys) {
    final dt = _parseKey(k);
    final t = totalsForDate(attendance, k, itemId);
    if (t.present + t.onLeave == 0) continue;
    final ymap = byYearWeekday.putIfAbsent(dt.year, () => <int, int>{});
    ymap[dt.weekday] = (ymap[dt.weekday] ?? 0) + 1;
  }
  final cells = <HeatCell>[];
  for (final e in byYearWeekday.entries) {
    for (final wd in [1, 2, 3, 4, 5, 6, 7]) {
      final c = e.value[wd] ?? 0;
      cells.add(HeatCell(wd, e.key, c));
    }
  }
  cells.sort((a, b) {
    final yc = a.year.compareTo(b.year);
    if (yc != 0) return yc;
    return a.weekday.compareTo(b.weekday);
  });
  return cells;
}

// ---------------------------------------------------------------------------
// User-Specific Computation Functions
// ---------------------------------------------------------------------------

List<RatingPoint> computeUserRatingSeries(Map<String, dynamic> attendance, String itemId, {
  required TimeGranularity granularity,
  required String? userId,
  List<int>? weekdays,
  bool allTime = false,
}) {
  if (userId == 'all' || userId == null) {
    if (allTime) {
      final k = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
      if (k.isEmpty) return const [];
      int present = 0;
      int leave = 0;
      int rosterRef = 0;
      final roster = (attendance['roster'] as List?)?.cast<String>();
      final rosterSize = (roster ?? const <String>[]).isEmpty ? null : roster!.length;
      for (final dayKey in k) {
        final t = totalsForDate(attendance, dayKey, itemId, roster: roster);
        present += t.present;
        leave += t.onLeave;
        rosterRef += (rosterSize ?? t.rosterSize);
      }
      final rating = rosterRef == 0 ? 0.0 : (present + leave) / rosterRef;
      return [RatingPoint(DateTime.now(), rating)];
    }
    return computeRatingSeries(attendance, itemId, granularity: granularity, weekdays: weekdays);
  }

  final k = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  if (k.isEmpty) return const [];
  final buckets = <String, List<String>>{};
  
  if (allTime) {
    buckets['All Time'] = k;
  } else {
    for (final dayKey in k) {
      final dt = _parseKey(dayKey);
      DateTime start;
      switch (granularity) {
        case TimeGranularity.week:
          start = dt.subtract(Duration(days: dt.weekday - 1));
          break;
        case TimeGranularity.month:
          start = DateTime(dt.year, dt.month, 1);
          break;
        case TimeGranularity.quarter:
          final q = ((dt.month - 1) ~/ 3) * 3 + 1;
          start = DateTime(dt.year, q, 1);
          break;
        case TimeGranularity.year:
          start = DateTime(dt.year, 1, 1);
          break;
      }
      (buckets[_fmt(start)] ??= <String>[]).add(dayKey);
    }
  }
  final entries = buckets.entries.toList()
    ..sort((a, b) => _parseKey(a.key).compareTo(_parseKey(b.key)));
  final points = <RatingPoint>[];
  for (final e in entries) {
    final keys = e.value;
    int positive = 0;
    int considered = 0;
    for (final dk in keys) {
      final rec = (attendance[dk] as Map?)?[itemId] as Map?;
      if (rec == null) continue;
      final isDefault = ((rec['default'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      if (isDefault) continue; // ignore default entirely
      final present = ((rec['present'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      final onLeave = ((rec['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      final absent = ((rec['absent'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      
      if (present || onLeave || absent) {
        considered++;
        if (present || onLeave) positive++;
      }
    }
    final rating = considered == 0 ? 0.0 : positive / considered;
    points.add(RatingPoint(allTime ? DateTime.now() : _parseKey(e.key), rating));
  }
  return points;
}

List<HistoryBar> computeUserHistory(Map<String, dynamic> attendance, String itemId, {
  required TimeGranularity granularity,
  required String? userId,
  List<int>? weekdays,
}) {
  if (userId == 'all' || userId == null) {
    return computeHistoryBars(attendance, itemId, granularity: granularity, weekdays: weekdays);
  }

  final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  final buckets = <String, List<String>>{};
  for (final k in keys) {
    final dt = _parseKey(k);
    DateTime start;
    switch (granularity) {
      case TimeGranularity.week:
        start = dt.subtract(Duration(days: dt.weekday - 1));
        break;
      case TimeGranularity.month:
        start = DateTime(dt.year, dt.month, 1);
        break;
      case TimeGranularity.quarter:
        final q = ((dt.month - 1) ~/ 3) * 3 + 1;
        start = DateTime(dt.year, q, 1);
        break;
      case TimeGranularity.year:
        start = DateTime(dt.year, 1, 1);
        break;
    }
    (buckets[_fmt(start)] ??= <String>[]).add(k);
  }
  final bars = <HistoryBar>[];
  final entries = buckets.entries.toList()
    ..sort((a, b) => _parseKey(a.key).compareTo(_parseKey(b.key)));
  for (final e in entries) {
    int p = 0, l = 0;
    for (final day in e.value) {
      final rec = (attendance[day] as Map?)?[itemId] as Map?;
      final isDefault = ((rec?['default'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      if (isDefault) continue; // ignore default
      final pres = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      final leave = ((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      if (pres) {
        p += 1;
      } else if (leave) {
        l += 1;
      }
    }
    bars.add(HistoryBar(_parseKey(e.key), present: p, onLeave: l));
  }
  return bars;
}

DateTime _nextValidDate(DateTime date, List<int> weekdays) {
  DateTime d = date.add(const Duration(days: 1));
  while (!weekdays.contains(d.weekday)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

List<SeriesRun> computeBestUserSeries(Map<String, dynamic> attendance, String itemId, {
  required String? userId,
  List<int>? weekdays,
  int limit = 10,
}) {
  if (userId == 'all' || userId == null) {
    return computeBestSeries(attendance, itemId, weekdays: weekdays, limit: limit);
  }

  final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
  if (keys.isEmpty) return const [];
  DateTime? runStart;
  DateTime? lastDate;
  final runs = <SeriesRun>[];
  final wd = weekdays ?? [1, 2, 3, 4, 5, 6, 7];

  for (int i = 0; i < keys.length; i++) {
    final k = keys[i];
    final dt = _parseKey(k);
    final rec = (attendance[k] as Map?)?[itemId] as Map?;
    final isDefault = ((rec?['default'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
    final present = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
    final leave = ((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
    
    // Absent breaks streak. Present or Leave extends it.
    // Default is ignored (skipped).
    
    if (isDefault) {
      // ignore default: neither break nor extend; just skip
      continue;
    }
    
    final positive = present || leave;

    if (positive) {
      if (runStart == null) {
        runStart = dt;
      } else if (lastDate != null) {
        // Check if this dt follows lastDate in the keys sequence
        // We need to check if there were any VALID days between lastDate and dt that were missed (absent).
        
        bool broken = false;
        DateTime check = _nextValidDate(lastDate, wd);
        while (check.isBefore(dt)) {
           final ck = _fmt(check);
           final crec = (attendance[ck] as Map?)?[itemId] as Map?;
           final isAbsent = ((crec?['absent'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
           
           if (isAbsent) {
             // Explicitly absent -> break streak
             broken = true;
             break;
           }
           // Otherwise (missing data, default, or just not in keys for some reason) -> bridge the gap
           check = _nextValidDate(check, wd);
        }
        
        if (broken) {
          runs.add(SeriesRun(runStart, lastDate));
          runStart = dt;
        }
      }
      lastDate = dt;
    } else {
      // Not positive. Check if explicitly absent.
      final isAbsent = ((rec?['absent'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      if (isAbsent) {
        // Explicitly absent -> Break
        if (runStart != null && lastDate != null) runs.add(SeriesRun(runStart, lastDate));
        runStart = null;
        lastDate = null;
      }
      // If not absent (e.g. missing or neutral), do nothing. 
      // runStart stays set, lastDate stays set. 
      // Next positive day will trigger gap check which handles this day via isAbsent check.
    }
  }
  if (runStart != null && lastDate != null) runs.add(SeriesRun(runStart, lastDate));
  
  // Filter out runs that are purely onLeave (no present days)
  final filteredRuns = runs.where((run) {
    bool hasPresent = false;
    DateTime d = run.start;
    while (!d.isAfter(run.end)) {
      final k = _fmt(d);
      final rec = (attendance[k] as Map?)?[itemId] as Map?;
      final present = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
      if (present) {
        hasPresent = true;
        break;
      }
      d = d.add(const Duration(days: 1));
    }
    return hasPresent;
  }).toList();

  filteredRuns.sort((a, b) => b.length.compareTo(a.length));
  return filteredRuns.take(limit).toList();
}
