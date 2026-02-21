import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'quran_prayer_models.dart';

class PrayerHabitSection extends StatelessWidget {
  final List<String> prayerNames;
  final List<PrayerDayData> displayDays;
  final PrayerTrackingMode trackingMode;
  final PrayerStatsScope statsScope;
  final PrayerStatsSummary statsSummary;
  final List<PrayerChartBucket> chartBuckets;
  final String completionLabel;
  final int totalDays;
  final void Function(PrayerTrackingMode mode) onModeChanged;
  final void Function(PrayerStatsScope scope) onScopeChanged;
  final void Function(DateTime date, String prayerName, bool value)
  onTogglePrayer;
  final String Function(DateTime date) weekdayLabelBuilder;

  const PrayerHabitSection({
    super.key,
    required this.prayerNames,
    required this.displayDays,
    required this.trackingMode,
    required this.statsScope,
    required this.statsSummary,
    required this.chartBuckets,
    required this.completionLabel,
    required this.totalDays,
    required this.onModeChanged,
    required this.onScopeChanged,
    required this.onTogglePrayer,
    required this.weekdayLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionPercent = (statsSummary.completionRatio * 100).round();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: translation(context: context, 'Stats overview'),
              trailing: _ScopeSelector(
                scope: statsScope,
                onChanged: onScopeChanged,
              ),
            ),
            const SizedBox(height: 12),
            _WeeklyBarChart(buckets: chartBuckets),
            const SizedBox(height: 12),
            _StatsRow(
              completionPercent: completionPercent,
              daysCompleted: statsSummary.daysCompleted,
              currentStreak: statsSummary.currentStreak,
              totalDays: totalDays,
              completionLabel: completionLabel,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _ModeSelector(trackingMode: trackingMode, onChanged: onModeChanged),
            const SizedBox(height: 8),
            Text(
              trackingMode == PrayerTrackingMode.missedOnly
                  ? translation(context: context, 'Mark missed prayers')
                  : translation(context: context, 'Mark completed prayers'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            for (final day in displayDays)
              _PrayerDayTile(
                day: day,
                prayerNames: prayerNames,
                weekdayLabel: weekdayLabelBuilder(day.date),
                trackingMode: trackingMode,
                onTogglePrayer: onTogglePrayer,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget trailing;

  const _SectionTitle({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ScopeSelector extends StatelessWidget {
  final PrayerStatsScope scope;
  final void Function(PrayerStatsScope scope) onChanged;

  const _ScopeSelector({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        ChoiceChip(
          label: Text(translation(context: context, 'Weekly')),
          selected: scope == PrayerStatsScope.weekly,
          onSelected: (_) => onChanged(PrayerStatsScope.weekly),
        ),
        ChoiceChip(
          label: Text(translation(context: context, 'Monthly')),
          selected: scope == PrayerStatsScope.monthly,
          onSelected: (_) => onChanged(PrayerStatsScope.monthly),
        ),
        ChoiceChip(
          label: Text(translation(context: context, 'Yearly')),
          selected: scope == PrayerStatsScope.yearly,
          onSelected: (_) => onChanged(PrayerStatsScope.yearly),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final PrayerTrackingMode trackingMode;
  final void Function(PrayerTrackingMode mode) onChanged;

  const _ModeSelector({required this.trackingMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text(translation(context: context, 'Missed mode')),
          selected: trackingMode == PrayerTrackingMode.missedOnly,
          onSelected: (_) => onChanged(PrayerTrackingMode.missedOnly),
        ),
        ChoiceChip(
          label: Text(translation(context: context, 'Manual mode')),
          selected: trackingMode == PrayerTrackingMode.manual,
          onSelected: (_) => onChanged(PrayerTrackingMode.manual),
        ),
      ],
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<PrayerChartBucket> buckets;

  const _WeeklyBarChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bucket in buckets)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 80 * bucket.ratio + 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.2 + 0.6 * bucket.ratio),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bucket.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int completionPercent;
  final int daysCompleted;
  final int currentStreak;
  final int totalDays;
  final String completionLabel;

  const _StatsRow({
    required this.completionPercent,
    required this.daysCompleted,
    required this.currentStreak,
    required this.totalDays,
    required this.completionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: completionLabel,
            value: '$completionPercent%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: translation(context: context, 'Days completed'),
            value: '$daysCompleted/$totalDays',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: translation(context: context, 'Current streak'),
            value: '$currentStreak',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerDayTile extends StatelessWidget {
  final PrayerDayData day;
  final List<String> prayerNames;
  final String weekdayLabel;
  final PrayerTrackingMode trackingMode;
  final void Function(DateTime date, String prayerName, bool value)
  onTogglePrayer;

  const _PrayerDayTile({
    required this.day,
    required this.prayerNames,
    required this.weekdayLabel,
    required this.trackingMode,
    required this.onTogglePrayer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isSameDay(day.date, DateTime.now());

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: isToday,
      title: Row(
        children: [
          Text(
            weekdayLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${day.date.day}/${day.date.month}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                translation(context: context, 'Today'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${translation(context: context, 'Completed')} ${day.completedCount}/${day.prayers.length}',
      ),
      children: [
        for (final prayer in prayerNames)
          _PrayerCheckboxTile(
            day: day,
            prayer: prayer,
            trackingMode: trackingMode,
            onTogglePrayer: onTogglePrayer,
          ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _PrayerCheckboxTile extends StatelessWidget {
  final PrayerDayData day;
  final String prayer;
  final PrayerTrackingMode trackingMode;
  final void Function(DateTime date, String prayerName, bool value)
  onTogglePrayer;

  const _PrayerCheckboxTile({
    required this.day,
    required this.prayer,
    required this.trackingMode,
    required this.onTogglePrayer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMissedMode = trackingMode == PrayerTrackingMode.missedOnly;

    // In missed mode: value represents "is missed" (false = not missed, true = missed)
    // In manual mode: value represents "is completed" (false = not done, true = done)
    final isMarked = isMissedMode
        ? !(day.prayers[prayer] ?? false)
        : (day.prayers[prayer] ?? false);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(translation(context: context, prayer)),
      onTap: () {
        onTogglePrayer(day.date, prayer, !isMarked);
      },
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(
            color: isMissedMode && isMarked
                ? Colors.red
                : theme.colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isMissedMode && isMarked
              ? Colors.red.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: isMarked
            ? Icon(
                isMissedMode ? Icons.close : Icons.check,
                size: 16,
                color: isMissedMode ? Colors.red : theme.colorScheme.primary,
              )
            : null,
      ),
    );
  }
}
