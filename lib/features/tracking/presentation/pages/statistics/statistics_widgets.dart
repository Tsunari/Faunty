import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/features/tracking/presentation/pages/statistics/stats_utils.dart';

class StatisticsWidgets extends StatefulWidget {
  final Map<String, dynamic> attendance;
  final String itemId;
  final Map<String, dynamic> itemMeta;
  final String? selectedUser;
  final String placeId;

  final ValueChanged<String?>? onUserChanged;
  final GlobalKey? screenshotKey;

  const StatisticsWidgets({
    super.key,
    required this.attendance,
    required this.itemId,
    required this.itemMeta,
    required this.selectedUser,
    this.onUserChanged,
    required this.placeId,
    this.screenshotKey,
  });

  @override
  State<StatisticsWidgets> createState() => _StatisticsWidgetsState();
}

class _StatisticsWidgetsState extends State<StatisticsWidgets> {
  TimeGranularity _ratingSpan = TimeGranularity.week;
  TimeGranularity _historySpan = TimeGranularity.month;

  // Local selection state: the widget manages selection locally to avoid
  // async races with parent-provided `selectedUser` and the async users list.
  String? _localSelectedUser;

  // Cached computations
  List<RatingPoint>? _cachedMonthSeries;
  List<RatingPoint>? _cachedYearSeries;
  List<RatingPoint>? _cachedAllTimeSeries;
  int? _cachedTotal;
  String? _lastComputedUser;
  int? _lastAttendanceHash;

  @override
  void didUpdateWidget(covariant StatisticsWidgets old) {
    super.didUpdateWidget(old);
    final roster =
        (widget.attendance['roster'] as List?)?.cast<String>() ??
        const <String>[];
    final allowed = <String>{'all', ...roster};

    // If the parent intentionally changed the selection, adopt it (if valid).
    if (widget.selectedUser != null &&
        widget.selectedUser != old.selectedUser) {
      if (allowed.contains(widget.selectedUser)) {
        setState(() {
          _localSelectedUser = widget.selectedUser;
        });
      }
    }

    // If our local selection became invalid due to roster changes, pick a fallback.
    if (_localSelectedUser != null && !allowed.contains(_localSelectedUser)) {
      final fb = roster.isNotEmpty ? roster.first : 'all';
      setState(() {
        _localSelectedUser = fb;
      });
      widget.onUserChanged?.call(_localSelectedUser);
    }
  }

  List<int> get _weekdays =>
      ((widget.itemMeta['weekdays'] as List?)?.cast<int>() ??
      const [1, 2, 3, 4, 5, 6, 7]);

  @override
  Widget build(BuildContext context) {
    final keys = normalizedDatesForItem(
      widget.attendance,
      widget.itemId,
      weekdays: _weekdays,
    );
    final roster =
        (widget.attendance['roster'] as List?)?.cast<String>() ??
        const <String>[];

    // Initialize local selection if not set. We avoid calling setState here
    // because this happens before first frame and assigning a field is fine.
    _localSelectedUser ??=
        widget.selectedUser ?? (roster.isNotEmpty ? roster.first : 'all');
    final effectiveUser = _localSelectedUser;

    // Only recompute series if user or attendance data changed
    final currentHash = widget.attendance.hashCode;
    final needsRecompute =
        _lastComputedUser != effectiveUser ||
        _lastAttendanceHash != currentHash;

    if (needsRecompute) {
      _cachedMonthSeries = computeUserRatingSeries(
        widget.attendance,
        widget.itemId,
        granularity: TimeGranularity.month,
        userId: effectiveUser,
        weekdays: _weekdays,
      );
      _cachedYearSeries = computeUserRatingSeries(
        widget.attendance,
        widget.itemId,
        granularity: TimeGranularity.year,
        userId: effectiveUser,
        weekdays: _weekdays,
      );
      _cachedAllTimeSeries = computeUserRatingSeries(
        widget.attendance,
        widget.itemId,
        granularity: TimeGranularity.year,
        userId: effectiveUser,
        weekdays: _weekdays,
        allTime: true,
      );

      // Compute total
      _cachedTotal = keys.where((k) {
        final rec = (widget.attendance[k] as Map?)?[widget.itemId] as Map?;
        if (rec == null) return false;
        if (effectiveUser == 'all' || effectiveUser == null) {
          final t = totalsForDate(widget.attendance, k, widget.itemId);
          return (t.present + t.onLeave + t.absent) > 0;
        } else {
          final isDefault =
              ((rec['default'] as List?)?.cast<String>() ?? const <String>[])
                  .contains(effectiveUser);
          if (isDefault) return false;
          final present =
              ((rec['present'] as List?)?.cast<String>() ?? const <String>[])
                  .contains(effectiveUser);
          final onLeave =
              ((rec['onLeave'] as List?)?.cast<String>() ?? const <String>[])
                  .contains(effectiveUser);
          final absent =
              ((rec['absent'] as List?)?.cast<String>() ?? const <String>[])
                  .contains(effectiveUser);
          return present || onLeave || absent;
        }
      }).length;

      _lastComputedUser = effectiveUser;
      _lastAttendanceHash = currentHash;
    }

    final monthSeries = _cachedMonthSeries!;
    final yearSeries = _cachedYearSeries!;
    final allTimeSeries = _cachedAllTimeSeries!;

    final currentRating = allTimeSeries.isEmpty
        ? 0.0
        : allTimeSeries.last.rating;
    final monthDelta = monthSeries.length >= 2
        ? (monthSeries.last.rating - monthSeries[monthSeries.length - 2].rating)
        : 0.0;
    final yearDelta = yearSeries.length >= 2
        ? (yearSeries.last.rating - yearSeries[yearSeries.length - 2].rating)
        : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepaintBoundary(
            key: widget.screenshotKey,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (roster.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _UserDropdown(
                        roster: roster,
                        selectedUser: effectiveUser,
                        onChanged: (v) {
                          setState(() {
                            _localSelectedUser = v;
                          });
                          widget.onUserChanged?.call(v);
                        },
                        onValidationChange: (v) {
                          if (mounted) {
                            setState(() {
                              _localSelectedUser = v;
                            });
                          }
                        },
                      ),
                    ),
                  _OverviewCard(
                    rating: currentRating,
                    monthDelta: monthDelta,
                    yearDelta: yearDelta,
                    total: _cachedTotal!,
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: translation(context: context, 'Rating'),
                    trailing: _SpanDropdown(
                      value: _ratingSpan,
                      onChanged: (v) => setState(() => _ratingSpan = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _RatingChart(
                      attendance: widget.attendance,
                      itemId: widget.itemId,
                      weekdays: _weekdays,
                      granularity: _ratingSpan,
                      selectedUser: effectiveUser,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: translation(context: context, 'History'),
                    trailing: _SpanDropdown(
                      value: _historySpan,
                      onChanged: (v) => setState(() => _historySpan = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _HistoryBars(
                      attendance: widget.attendance,
                      itemId: widget.itemId,
                      weekdays: _weekdays,
                      granularity: _historySpan,
                      selectedUser: effectiveUser,
                    ),
                  ),
                  // Padding(
                  // 	padding: const EdgeInsets.only(top: 6.0),
                  // 	child: Text(
                  // 		translation(context: context, 'Stacked bars show attended days per period: Present (bottom) + On leave (top).'),
                  // 		style: Theme.of(context).textTheme.bodySmall,
                  // 	),
                  // ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: translation(context: context, 'Calendar'),
                  ),
                  const SizedBox(height: 8),
                  _CalendarGrid(
                    attendance: widget.attendance,
                    itemId: widget.itemId,
                    weekdays: _weekdays,
                    selectedUser: effectiveUser,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: translation(context: context, 'Best Streaks'),
                  ),
                  const SizedBox(height: 8),
                  _SeriesList(
                    attendance: widget.attendance,
                    itemId: widget.itemId,
                    weekdays: _weekdays,
                    selectedUser: effectiveUser,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: translation(context: context, 'Frequency'),
                ),
                const SizedBox(height: 8),
                _HeatmapBubbles(
                  attendance: widget.attendance,
                  itemId: widget.itemId,
                  weekdays: _weekdays,
                  selectedUser: effectiveUser,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------- Per-user computations ---------

class _OverviewCard extends StatelessWidget {
  final double rating; // 0..1
  final double monthDelta;
  final double yearDelta;
  final int total;
  const _OverviewCard({
    required this.rating,
    required this.monthDelta,
    required this.yearDelta,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surface.withOpacity(0.4),
                  theme.colorScheme.surface.withOpacity(0.15),
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.95),
                ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 32,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: (rating * 100).clamp(0.1, 100),
                            color: color,
                            radius: 8,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (100 - (rating * 100)).clamp(0, 99.9),
                            color: theme.dividerColor.withOpacity(0.08),
                            radius: 6,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pct(rating),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        translation(context: context, 'Rate'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(
                      label: translation(context: context, 'Month'),
                      value: _signedPct(monthDelta),
                      isDelta: true,
                      deltaValue: monthDelta,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: theme.dividerColor.withOpacity(0.12),
                    ),
                    _Metric(
                      label: translation(context: context, 'Year'),
                      value: _signedPct(yearDelta),
                      isDelta: true,
                      deltaValue: yearDelta,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: theme.dividerColor.withOpacity(0.12),
                    ),
                    _Metric(
                      label: translation(context: context, 'Total'),
                      value: '$total',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _pct(double v) => '${(v * 100).round()}%';
  static String _signedPct(double v) =>
      '${v >= 0 ? '+' : ''}${(v * 100).round()}%';
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDelta;
  final double deltaValue;

  const _Metric({
    required this.label,
    required this.value,
    this.isDelta = false,
    this.deltaValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? valueColor = theme.colorScheme.onSurface;

    if (isDelta) {
      if (deltaValue > 0) {
        valueColor = const Color(0xFF10B981); // Modern green
      } else if (deltaValue < 0) {
        valueColor = const Color(0xFFEF4444); // Modern red
      } else {
        valueColor = theme.colorScheme.onSurface.withOpacity(0.6);
      }
    } else {
      valueColor = theme.colorScheme.primary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SpanDropdown extends StatelessWidget {
  final TimeGranularity value;
  final ValueChanged<TimeGranularity> onChanged;
  const _SpanDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeGranularity>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: [
            DropdownMenuItem(
              value: TimeGranularity.week,
              child: Text(translation('Week')),
            ),
            DropdownMenuItem(
              value: TimeGranularity.month,
              child: Text(translation('Month')),
            ),
            DropdownMenuItem(
              value: TimeGranularity.quarter,
              child: Text(translation('Quarter')),
            ),
            DropdownMenuItem(
              value: TimeGranularity.year,
              child: Text(translation('Year')),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChart extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final String itemId;
  final List<int> weekdays;
  final TimeGranularity granularity;
  final String? selectedUser;
  const _RatingChart({
    required this.attendance,
    required this.itemId,
    required this.weekdays,
    required this.granularity,
    required this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final series = computeUserRatingSeries(
      attendance,
      itemId,
      granularity: granularity,
      userId: selectedUser,
      weekdays: weekdays,
    );
    if (series.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(child: Text(translation(context: context, 'No data'))),
      );
    }
    final spots = <FlSpot>[];
    for (int i = 0; i < series.length; i++) {
      final y = (series[i].rating * 100).roundToDouble();
      spots.add(FlSpot(i.toDouble(), y));
    }
    String fmt(DateTime d) {
      switch (granularity) {
        case TimeGranularity.week:
          return DateFormat('dd MMM', locale).format(d);
        case TimeGranularity.month:
          return DateFormat('MMM yyyy', locale).format(d);
        case TimeGranularity.quarter:
          final q = ((d.month - 1) ~/ 3) + 1;
          return 'Q$q ${d.year}';
        case TimeGranularity.year:
          return DateFormat('yyyy', locale).format(d);
      }
    }

    final bottomLabels = [for (final p in series) fmt(p.start)];
    final theme = Theme.of(context);
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: -0.1,
          maxX: spots.length - 1 + 0.1,
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: 25,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: math.max(1, (series.length / 6).floor()).toDouble(),
                getTitlesWidget: (value, meta) {
                  final nearest = value.round();
                  if ((value - nearest).abs() > 0.01)
                    return const SizedBox.shrink();
                  final idx = nearest;
                  if (idx < 0 || idx >= bottomLabels.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      bottomLabels[idx],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  theme.colorScheme.surface.withOpacity(0.95),
              tooltipBorder: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              // tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map(
                      (s) => LineTooltipItem(
                        '${s.y.toInt()}%',
                        theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(color: Colors.white),
                      ),
                    )
                    .toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: theme.colorScheme.primary,
                      strokeWidth: 1.5,
                      strokeColor: theme.colorScheme.surface,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.18),
                    theme.colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryBars extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final String itemId;
  final List<int> weekdays;
  final TimeGranularity granularity;
  final String? selectedUser;
  const _HistoryBars({
    required this.attendance,
    required this.itemId,
    required this.weekdays,
    required this.granularity,
    required this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    final bars = computeUserHistory(
      attendance,
      itemId,
      granularity: granularity,
      userId: selectedUser,
      weekdays: weekdays,
    );
    if (bars.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(translation(context: context, 'No data'))),
      );
    }
    final groups = <BarChartGroupData>[];
    final monthLabels = <String>[];
    final totals = <int>[];
    final presentCounts = <int>[];
    final leaveCounts = <int>[];
    final theme = Theme.of(context);
    for (int i = 0; i < bars.length; i++) {
      final b = bars[i];
      final totalCount = b.present + b.onLeave;
      final total = totalCount.toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 6,
          barRods: [
            BarChartRodData(
              toY: total,
              width: 14,
              borderRadius: BorderRadius.circular(6),
              color: Colors.transparent,
              rodStackItems: [
                BarChartRodStackItem(
                  0,
                  b.present.toDouble(),
                  theme.colorScheme.primary,
                ),
                BarChartRodStackItem(
                  b.present.toDouble(),
                  total,
                  theme.colorScheme.primary.withOpacity(0.4),
                ),
              ],
            ),
          ],
        ),
      );
      totals.add(totalCount);
      presentCounts.add(b.present);
      leaveCounts.add(b.onLeave);
      final m = DateFormat(
        'MMM',
        Localizations.localeOf(context).toString(),
      ).format(b.start);
      final yearSuffix = granularity == TimeGranularity.year
          ? '${b.start.year}'
          : '';
      monthLabels.add('$m${yearSuffix.isNotEmpty ? '\n$yearSuffix' : ''}');
    }
    final interval = math.max(1, (bars.length / 6).floor());
    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: interval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= monthLabels.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      monthLabels[i],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= totals.length)
                    return const SizedBox.shrink();
                  final total = totals[i];
                  if (total == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      '$total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) =>
                  theme.colorScheme.surface.withOpacity(0.95),
              tooltipBorder: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final i = group.x;
                final pres = presentCounts[i];
                final leav = leaveCounts[i];
                return BarTooltipItem(
                  '${translation(context: context, 'Present')}: $pres\n${translation(context: context, 'Leave')}: $leav',
                  theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final String itemId;
  final List<int> weekdays;
  final String? selectedUser;
  const _CalendarGrid({
    required this.attendance,
    required this.itemId,
    required this.weekdays,
    required this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    final dayKeys = normalizedDatesForItem(
      attendance,
      itemId,
      weekdays: weekdays,
    );
    if (dayKeys.isEmpty)
      return SizedBox(
        height: 120,
        child: Center(child: Text(translation(context: context, 'No data'))),
      );

    final locale = Localizations.localeOf(context).toString();
    final scheduledDays = dayKeys.map(parseDateKey).toList();
    // Determine continuous range (include other days)
    scheduledDays.sort();
    final minDate = scheduledDays.first;
    final maxDate = scheduledDays.last;
    final rangeStart = minDate.subtract(
      Duration(days: minDate.weekday - 1),
    ); // Monday
    final rangeEnd = maxDate.add(Duration(days: 7 - maxDate.weekday)); // Sunday

    // Build weekly columns
    final List<DateTime> weekStarts = [];
    for (
      DateTime w = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      w.isBefore(rangeEnd) || w.isAtSameMomentAs(rangeEnd);
      w = w.add(const Duration(days: 7))
    ) {
      weekStarts.add(w);
    }

    Color bgFor(DateTime d) {
      final key = formatDateKey(d);
      final rec = (attendance[key] as Map?)?[itemId] as Map?;
      if (rec == null) {
        return Colors.transparent; // other day: no fill
      }
      if (selectedUser == 'all') {
        // Aggregate view: Show opacity based on attendance rate
        final t = totalsForDate(attendance, key, itemId);
        final total = t.present + t.onLeave + t.absent + t.defaulted;
        final rosterSize = t.rosterSize > 0
            ? t.rosterSize
            : (total > 0 ? total : 1);
        final rate = (t.present + t.onLeave) / rosterSize;
        if (rate > 0)
          return Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.15 + (rate * 0.75));
        return Colors.transparent;
      }

      final present =
          ((rec['present'] as List?)?.cast<String>() ?? const <String>[])
              .contains(selectedUser);
      final leave =
          ((rec['onLeave'] as List?)?.cast<String>() ?? const <String>[])
              .contains(selectedUser);
      final absent =
          ((rec['absent'] as List?)?.cast<String>() ?? const <String>[])
              .contains(selectedUser);
      final def =
          ((rec['default'] as List?)?.cast<String>() ?? const <String>[])
              .contains(selectedUser);
      if (present)
        return Theme.of(context).colorScheme.primary.withOpacity(0.85);
      if (leave) return Theme.of(context).colorScheme.primary.withOpacity(0.4);
      if (absent) return Theme.of(context).colorScheme.error.withOpacity(0.85);
      if (def) return Colors.transparent; // default: no fill
      return Colors.transparent; // other
    }

    Color textColorFor(Color bg, DateTime d) {
      final key = formatDateKey(d);
      final rec = (attendance[key] as Map?)?[itemId] as Map?;
      if (rec == null) {
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.2);
      }
      if (bg.opacity == 0)
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      return bg.computeLuminance() < 0.5
          ? Colors.white
          : Theme.of(context).colorScheme.onSurface;
    }

    Border? borderFor(Color bg, DateTime d) {
      final key = formatDateKey(d);
      final rec = (attendance[key] as Map?)?[itemId] as Map?;
      if (rec == null) return null; // completely non-existent schedule days
      if (bg.opacity == 0)
        return Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
          width: 1,
        );
      return null;
    }

    const double cellSize = 24;
    const double hGap = 3;
    const double vGap = 3;
    final double columnWidth = cellSize + hGap * 2;

    return SizedBox(
      height: 7 * (cellSize + vGap) + 28,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month labels row
            Row(
              children: [
                for (int wi = 0; wi < weekStarts.length; wi++)
                  SizedBox(
                    width: columnWidth,
                    child: () {
                      final start = weekStarts[wi];
                      final days = [
                        for (int d = 0; d < 7; d++)
                          start.add(Duration(days: d)),
                      ];
                      final hasMonthStart = days.any((d) => d.day == 1);
                      if (!hasMonthStart) return const SizedBox.shrink();
                      return Center(
                        child: Text(
                          DateFormat('MMM', locale).format(
                            days.firstWhere(
                              (d) => d.day == 1,
                              orElse: () => start,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      );
                    }(),
                  ),
              ],
            ),
            // Grid rows (7 days stacked per column)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final ws in weekStarts)
                  SizedBox(
                    width: columnWidth,
                    child: Column(
                      children: [
                        for (int d = 0; d < 7; d++)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: vGap / 2,
                              horizontal: hGap,
                            ),
                            child: Builder(
                              builder: (context) {
                                final date = ws.add(Duration(days: d));
                                final bg = bgFor(date);
                                final tc = textColorFor(bg, date);
                                return Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: borderFor(bg, date),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${date.day}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: tc,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesList extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final String itemId;
  final List<int> weekdays;
  final String? selectedUser;
  const _SeriesList({
    required this.attendance,
    required this.itemId,
    required this.weekdays,
    required this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    final runs = computeBestUserSeries(
      attendance,
      itemId,
      userId: selectedUser,
      weekdays: weekdays,
      limit: 10,
    );
    if (runs.isEmpty)
      return SizedBox(
        height: 100,
        child: Center(child: Text(translation(context: context, 'No data'))),
      );
    final maxLen = runs.fold<int>(0, (p, e) => math.max(p, e.length));
    final theme = Theme.of(context);
    return Column(
      children: [
        for (int i = 0; i < runs.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    DateFormat(
                      'dd.MM.yyyy',
                      Localizations.localeOf(context).toString(),
                    ).format(runs[i].start),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final width =
                          (runs[i].length / (maxLen == 0 ? 1 : maxLen)) *
                          c.maxWidth;
                      // Build segments for the run
                      final segments = <Widget>[];
                      DateTime d = runs[i].start;

                      // Merge adjacent segments of same color
                      Color? lastColor;
                      int currentFlex = 0;

                      void flush() {
                        if (currentFlex > 0 && lastColor != null) {
                          segments.add(
                            Expanded(
                              flex: currentFlex,
                              child: Container(color: lastColor),
                            ),
                          );
                        }
                      }

                      while (!d.isAfter(runs[i].end)) {
                        final k = formatDateKey(d);
                        final rec = (attendance[k] as Map?)?[itemId] as Map?;
                        Color color = Colors.transparent;
                        if (rec != null) {
                          final present =
                              ((rec['present'] as List?)?.cast<String>() ??
                                      const <String>[])
                                  .contains(selectedUser);
                          final leave =
                              ((rec['onLeave'] as List?)?.cast<String>() ??
                                      const <String>[])
                                  .contains(selectedUser);
                          final absent =
                              ((rec['absent'] as List?)?.cast<String>() ??
                                      const <String>[])
                                  .contains(selectedUser);
                          if (present)
                            color = theme.colorScheme.primary.withOpacity(0.85);
                          else if (leave)
                            color = theme.colorScheme.primary.withOpacity(0.45);
                          else if (absent)
                            color = theme.colorScheme.error.withOpacity(0.85);
                        }

                        if (color != lastColor) {
                          flush();
                          lastColor = color;
                          currentFlex = 0;
                        }
                        currentFlex++;
                        d = d.add(const Duration(days: 1));
                      }
                      flush();

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: width,
                            height: 24,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.dividerColor.withOpacity(0.08),
                            ),
                            child: Row(children: segments),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                '${runs[i].length}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black.withOpacity(0.4),
                                      offset: const Offset(0.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    DateFormat(
                      'dd.MM.yyyy',
                      Localizations.localeOf(context).toString(),
                    ).format(runs[i].end),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HeatmapBubbles extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final String itemId;
  final List<int> weekdays;
  final String? selectedUser;
  const _HeatmapBubbles({
    required this.attendance,
    required this.itemId,
    required this.weekdays,
    required this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    // Build weekday (rows) x last 13 months (columns) bubble counts
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final months = <DateTime>[
      for (int i = 12; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
    final monthKeys = months
        .map((m) => '${m.year}-${m.month.toString().padLeft(2, '0')}')
        .toList();
    final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
    final Map<int, Map<String, int>> data = {
      for (int wd = 1; wd <= 7; wd++) wd: {for (final mk in monthKeys) mk: 0},
    };

    if (selectedUser == 'all') {
      // Manual aggregate for 'all'
      for (final k in keys) {
        final d = parseDateKey(k);
        final mk = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        if (!monthKeys.contains(mk)) continue;
        final t = totalsForDate(attendance, k, itemId);
        if (t.present + t.onLeave > 0) {
          data[d.weekday]![mk] = (data[d.weekday]![mk] ?? 0) + 1;
        }
      }
    } else {
      for (final k in keys) {
        final d = parseDateKey(k);
        final mk = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        if (!monthKeys.contains(mk)) continue;
        final rec = (attendance[k] as Map?)?[itemId] as Map?;
        final positive =
            ((rec?['present'] as List?)?.cast<String>() ?? const <String>[])
                .contains(selectedUser) ||
            ((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[])
                .contains(selectedUser);
        if (positive) {
          data[d.weekday]![mk] = (data[d.weekday]![mk] ?? 0) + 1;
        }
      }
    }
    int maxCount = 0;
    for (final row in data.values) {
      for (final c in row.values) {
        if (c > maxCount) maxCount = c;
      }
    }
    if (maxCount == 0)
      return SizedBox(
        height: 120,
        child: Center(child: Text(translation(context: context, 'No data'))),
      );

    String wdLabel(int wd) {
      switch (wd) {
        case DateTime.monday:
          return translation('Mo');
        case DateTime.tuesday:
          return translation('Tue');
        case DateTime.wednesday:
          return translation('Wed');
        case DateTime.thursday:
          return translation('Thu');
        case DateTime.friday:
          return translation('Fr');
        case DateTime.saturday:
          return translation('Sat');
        case DateTime.sunday:
          return translation('Sun');
        default:
          return '';
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double labelWidth = 36;
        const double gap = 4;
        const double colWidth = 28;
        // Keep in sync with the right padding used in rows below
        const double rowRightPad = 8.0;
        final double avail = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        int colsToShow = monthKeys.length;
        if (avail.isFinite) {
          // Subtract the weekday label + gap and the right padding from available width
          final usable = math.max(0, avail - (labelWidth + gap) - rowRightPad);
          // Initial estimate of how many columns fit
          int fit = (usable / colWidth).floor();
          colsToShow = fit.clamp(1, monthKeys.length);
          // Verify and adjust to avoid any off-by-one overflow
          double totalWidthFor(int cols) =>
              labelWidth + gap + cols * colWidth + rowRightPad;
          while (colsToShow > 1 && totalWidthFor(colsToShow) > avail) {
            colsToShow--;
          }
        }
        final start = monthKeys.length - colsToShow;
        final visibleKeys = monthKeys.sublist(start);
        final visibleMonths = months.sublist(start);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int wd = 1; wd <= 7; wd++)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4.0, 8.0, 4.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(wdLabel(wd)),
                        ),
                      ),
                      const SizedBox(width: gap),
                      for (final mk in visibleKeys)
                        SizedBox(
                          width: colWidth,
                          height: 20,
                          child: Center(
                            child: _Bubble(
                              size: _bubbleSize(data[wd]![mk]!, maxCount),
                              color: Theme.of(context).colorScheme.primary,
                              faded: data[wd]![mk] == 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Month labels under the heatmap
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: labelWidth + gap),
                    for (final m in visibleMonths)
                      SizedBox(
                        width: colWidth,
                        child: Text(
                          DateFormat('MMM', locale).format(m),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _bubbleSize(int v, int max) {
    if (v <= 0 || max <= 0) return 6;
    final t = v / max;
    return 6 + t * 10; // 6..16
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;
  final bool faded;
  const _Bubble({required this.size, required this.color, required this.faded});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: faded
            ? Theme.of(context).dividerColor.withOpacity(0.08)
            : color.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Separate widget for user dropdown to avoid rebuilding entire statistics when users list updates
class _UserDropdown extends ConsumerWidget {
  final List<String> roster;
  final String? selectedUser;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String?>? onValidationChange;

  const _UserDropdown({
    required this.roster,
    required this.selectedUser,
    required this.onChanged,
    this.onValidationChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersByCurrentPlaceProvider);
    final users = usersAsync.asData?.value;
    final byId = users == null
        ? <String, String>{}
        : {for (final u in users) u.uid: '${u.firstName} ${u.lastName}'.trim()};
    final uniqueRoster = roster.toSet();
    final items = [
      DropdownMenuItem<String>(
        value: 'all',
        child: Text(translation(context: context, 'All Users')),
      ),
      for (final id in uniqueRoster)
        DropdownMenuItem<String>(value: id, child: Text(byId[id] ?? id)),
    ];

    // Ensure the value exists in items, otherwise reset to a valid value
    final validUser =
        (selectedUser == 'all' || uniqueRoster.contains(selectedUser))
        ? selectedUser
        : 'all';

    // Sync local state if validation changed the value
    if (validUser != selectedUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onValidationChange?.call(validUser);
      });
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: validUser,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
              onChanged: onChanged,
              items: items,
              alignment: Alignment.center,
            ),
          ),
        ),
      ],
    );
  }
}
