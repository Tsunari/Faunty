enum PrayerTrackingMode { missedOnly, manual }

enum PrayerStatsScope { weekly, monthly, yearly }

class PrayerDayData {
  final DateTime date;
  final Map<String, bool> prayers;

  PrayerDayData({required this.date, required this.prayers});

  int get completedCount => prayers.values.where((isDone) => isDone).length;

  bool get isComplete => completedCount == prayers.length;

  double get completionRatio {
    if (prayers.isEmpty) return 0;
    return completedCount / prayers.length;
  }
}

class PrayerStatsSummary {
  final int completed;
  final int total;
  final int daysCompleted;
  final int currentStreak;

  PrayerStatsSummary({
    required this.completed,
    required this.total,
    required this.daysCompleted,
    required this.currentStreak,
  });

  double get completionRatio {
    if (total == 0) return 0;
    return completed / total;
  }
}

class PrayerChartBucket {
  final String label;
  final double ratio;

  PrayerChartBucket({required this.label, required this.ratio});
}
