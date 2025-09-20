import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tools/translation_helper.dart';
import 'stats_utils.dart';
import '../../../state_management/user_list_provider.dart';

class StatisticsWidgets extends StatefulWidget {
	final Map<String, dynamic> attendance;
	final String itemId;
	final Map<String, dynamic> itemMeta;

	const StatisticsWidgets({super.key, required this.attendance, required this.itemId, required this.itemMeta});

	@override
	State<StatisticsWidgets> createState() => _StatisticsWidgetsState();
}

class _StatisticsWidgetsState extends State<StatisticsWidgets> {
	TimeGranularity _ratingSpan = TimeGranularity.week;
	TimeGranularity _historySpan = TimeGranularity.month;
	String? _selectedUser;

	List<int> get _weekdays => ((widget.itemMeta['weekdays'] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5, 6, 7]);

	@override
	Widget build(BuildContext context) {
		final roster = (widget.attendance['roster'] as List?)?.cast<String>() ?? const <String>[];
		final keys = normalizedDatesForItem(widget.attendance, widget.itemId, weekdays: _weekdays);
			_selectedUser ??= roster.isNotEmpty ? roster.first : null;

		// Overview metrics
			final weekSeries = _computeUserRatingSeries(granularity: TimeGranularity.week);
			final monthSeries = _computeUserRatingSeries(granularity: TimeGranularity.month);
			final yearSeries = _computeUserRatingSeries(granularity: TimeGranularity.year);

			final currentRating = weekSeries.isEmpty ? 0.0 : weekSeries.last.rating;
			final monthDelta = monthSeries.length >= 2 ? (monthSeries.last.rating - monthSeries[monthSeries.length - 2].rating) : 0.0;
			final yearDelta = yearSeries.length >= 2 ? (yearSeries.last.rating - yearSeries[yearSeries.length - 2].rating) : 0.0;

		return SingleChildScrollView(
			padding: const EdgeInsets.all(12),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
								// User selection
											if (roster.isNotEmpty)
												Padding(
													padding: const EdgeInsets.only(bottom: 8.0),
													child: Consumer(
														builder: (context, ref, _) {
															final usersAsync = ref.watch(usersByCurrentPlaceProvider);
															final users = usersAsync.asData?.value;
															final options = <DropdownMenuItem<String>>[];
															if (users != null) {
																final byId = {for (final u in users) u.uid: '${u.firstName} ${u.lastName}'.trim()};
																for (final id in roster) {
																	final label = byId[id] ?? id;
																	options.add(DropdownMenuItem(value: id, child: Text(label)));
																}
															} else {
																for (final id in roster) {
																	options.add(DropdownMenuItem(value: id, child: Text(id)));
																}
															}
															return Row(
																children: [
																	Text(translation(context: context, 'User'), style: Theme.of(context).textTheme.bodyMedium),
																	const SizedBox(width: 8),
																	DropdownButton<String>(
																		value: _selectedUser,
																		onChanged: (v) => setState(() => _selectedUser = v),
																		items: options,
																	),
																],
															);
														},
													),
												),

								_OverviewCard(
						rating: currentRating,
						monthDelta: monthDelta,
						yearDelta: yearDelta,
						total: keys.length,
					),
								Padding(
									padding: const EdgeInsets.only(top: 6.0),
									child: Text(
										translation(context: context, 'Rating is the percent of attended scheduled days in the latest period. Month/Year are changes vs previous period.'),
										style: Theme.of(context).textTheme.bodySmall,
									),
								),
					const SizedBox(height: 16),
					_SectionHeader(
									title: translation(context: context, 'Rating'),
						trailing: _SpanDropdown(value: _ratingSpan, onChanged: (v) => setState(() => _ratingSpan = v)),
					),
					const SizedBox(height: 8),
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 8.0),
									child: _RatingChart(
										attendance: widget.attendance,
										itemId: widget.itemId,
										weekdays: _weekdays,
										granularity: _ratingSpan,
										selectedUser: _selectedUser,
									),
								),
					const SizedBox(height: 24),
					_SectionHeader(
									title: translation(context: context, 'History'),
						trailing: _SpanDropdown(value: _historySpan, onChanged: (v) => setState(() => _historySpan = v)),
					),
					const SizedBox(height: 8),
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 8.0),
									child: _HistoryBars(
										attendance: widget.attendance,
										itemId: widget.itemId,
										weekdays: _weekdays,
										granularity: _historySpan,
										selectedUser: _selectedUser,
									),
								),
								Padding(
									padding: const EdgeInsets.only(top: 6.0),
									child: Text(
										translation(context: context, 'Stacked bars show attended days per period: Present (bottom) + On leave (top).'),
										style: Theme.of(context).textTheme.bodySmall,
									),
								),
					const SizedBox(height: 24),
								_SectionHeader(title: translation(context: context, 'Calendar')),
					const SizedBox(height: 8),
								_CalendarGrid(attendance: widget.attendance, itemId: widget.itemId, weekdays: _weekdays, selectedUser: _selectedUser),
					const SizedBox(height: 24),
								_SectionHeader(title: translation(context: context, 'Best Streaks')),
					const SizedBox(height: 8),
								_SeriesList(attendance: widget.attendance, itemId: widget.itemId, weekdays: _weekdays, selectedUser: _selectedUser),
					const SizedBox(height: 24),
								_SectionHeader(title: translation(context: context, 'Frequency')),
					const SizedBox(height: 8),
								_HeatmapBubbles(attendance: widget.attendance, itemId: widget.itemId, weekdays: _weekdays, selectedUser: _selectedUser),
					const SizedBox(height: 24),
				],
			),
		);
	}

				// --------- Per-user computations ---------
				List<RatingPoint> _computeUserRatingSeries({required TimeGranularity granularity}) {
					final k = normalizedDatesForItem(widget.attendance, widget.itemId, weekdays: _weekdays);
					if (k.isEmpty) return const [];
					final buckets = <String, List<String>>{};
					for (final dayKey in k) {
						final dt = parseDateKey(dayKey);
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
						(buckets[formatDateKey(start)] ??= <String>[]).add(dayKey);
					}
					final entries = buckets.entries.toList()
						..sort((a, b) => parseDateKey(a.key).compareTo(parseDateKey(b.key)));
					final points = <RatingPoint>[];
					for (final e in entries) {
						final keys = e.value;
						int positive = 0;
						for (final dk in keys) {
							final rec = (widget.attendance[dk] as Map?)?[widget.itemId] as Map?;
							final present = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(_selectedUser);
							final onLeave = ((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(_selectedUser);
							if (present || onLeave) positive++;
						}
						final rating = keys.isEmpty ? 0.0 : positive / keys.length;
						points.add(RatingPoint(parseDateKey(e.key), rating));
					}
					return points;
				}
}

class _OverviewCard extends StatelessWidget {
	final double rating; // 0..1
	final double monthDelta;
	final double yearDelta;
	final int total;
	const _OverviewCard({required this.rating, required this.monthDelta, required this.yearDelta, required this.total});

	@override
	Widget build(BuildContext context) {
		final color = Theme.of(context).colorScheme.primary;
		return Card(
			clipBehavior: Clip.antiAlias,
			child: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Row(
					children: [
						SizedBox(
							width: 80,
							height: 80,
							child: PieChart(
								PieChartData(
									sectionsSpace: 0,
									centerSpaceRadius: 28,
									startDegreeOffset: -90,
									sections: [
										PieChartSectionData(value: (rating * 100).clamp(0, 100), color: color, radius: 12, showTitle: false),
										PieChartSectionData(value: 100 - (rating * 100).clamp(0, 100), color: Theme.of(context).dividerColor.withOpacity(0.25), radius: 12, showTitle: false),
									],
								),
							),
						),
						const SizedBox(width: 16),
						Expanded(
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceAround,
												children: [
													_Metric(label: translation(context: context, 'Rating'), value: _pct(rating), highlight: true),
													_Metric(label: translation(context: context, 'Month'), value: _signedPct(monthDelta)),
													_Metric(label: translation(context: context, 'Year'), value: _signedPct(yearDelta)),
													_Metric(label: translation(context: context, 'Total'), value: '$total'),
												],
							),
						)
					],
				),
			),
		);
	}

	static String _pct(double v) => '${(v * 100).round()}%';
	static String _signedPct(double v) => (v >= 0 ? '+' : '') + '${(v * 100).round()}%';
}

class _Metric extends StatelessWidget {
	final String label;
	final String value;
	final bool highlight;
	const _Metric({required this.label, required this.value, this.highlight = false});

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final color = highlight ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color;
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
				const SizedBox(height: 4),
				Text(label, style: theme.textTheme.bodyMedium),
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
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
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
		return DropdownButton<TimeGranularity>(
			value: value,
			underline: const SizedBox.shrink(),
			onChanged: (v) {
				if (v != null) onChanged(v);
			},
					items: [
						DropdownMenuItem(value: TimeGranularity.week, child: Text(translation('Week'))),
						DropdownMenuItem(value: TimeGranularity.month, child: Text(translation('Month'))),
						DropdownMenuItem(value: TimeGranularity.quarter, child: Text(translation('Quarter'))),
						DropdownMenuItem(value: TimeGranularity.year, child: Text(translation('Year'))),
					],
		);
	}
}

class _RatingChart extends StatelessWidget {
	final Map<String, dynamic> attendance;
	final String itemId;
	final List<int> weekdays;
	final TimeGranularity granularity;
		final String? selectedUser;
		const _RatingChart({required this.attendance, required this.itemId, required this.weekdays, required this.granularity, required this.selectedUser});

	@override
	Widget build(BuildContext context) {
			// Per-user series
			final locale = Localizations.localeOf(context).toString();
			final series = (context.findAncestorStateOfType<_StatisticsWidgetsState>()?._computeUserRatingSeries(granularity: granularity)) ?? const <RatingPoint>[];
		if (series.isEmpty) {
				return SizedBox(height: 180, child: Center(child: Text(translation(context: context, 'No data'))));
		}
		final spots = <FlSpot>[];
		for (int i = 0; i < series.length; i++) {
			spots.add(FlSpot(i.toDouble(), series[i].rating * 100));
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
		return SizedBox(
			height: 220,
			child: LineChart(
				LineChartData(
						minX: -0.3,
						maxX: spots.length - 1 + 0.3,
					minY: 0,
					maxY: 100,
					gridData: FlGridData(show: true, horizontalInterval: 20, drawVerticalLine: false),
					titlesData: FlTitlesData(
						leftTitles: AxisTitles(
								axisNameWidget: Text(translation('%')),
							axisNameSize: 18,
							sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 20, getTitlesWidget: (v, _) => Text('${v.toInt()}%')),
						),
						bottomTitles: AxisTitles(
							sideTitles: SideTitles(
								showTitles: true,
								reservedSize: 28,
								interval: math.max(1, (series.length / 6).floor()).toDouble(),
								getTitlesWidget: (value, meta) {
									final idx = value.toInt();
									if (idx < 0 || idx >= bottomLabels.length) return const SizedBox.shrink();
									return Padding(
										padding: const EdgeInsets.only(top: 6.0),
										child: Text(bottomLabels[idx], style: Theme.of(context).textTheme.bodySmall),
									);
								},
							),
						),
						rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
						topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
					),
					lineTouchData: LineTouchData(enabled: true),
					lineBarsData: [
						LineChartBarData(
							spots: spots,
							isCurved: true,
							color: Theme.of(context).colorScheme.primary,
							barWidth: 3,
							dotData: FlDotData(show: true),
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
		const _HistoryBars({required this.attendance, required this.itemId, required this.weekdays, required this.granularity, required this.selectedUser});

	@override
	Widget build(BuildContext context) {
			final bars = _computeUserHistory(attendance, itemId, weekdays, granularity, selectedUser);
		if (bars.isEmpty) {
			return SizedBox(height: 200, child: Center(child: Text(translation(context: context, 'No data'))));
		}
			final groups = <BarChartGroupData>[];
			final monthLabels = <String>[];
			for (int i = 0; i < bars.length; i++) {
				final b = bars[i];
				final total = (b.present + b.onLeave).toDouble();
				groups.add(
					BarChartGroupData(
						x: i,
						barsSpace: 6,
						barRods: [
							BarChartRodData(
								toY: total,
								width: 16,
								rodStackItems: [
									BarChartRodStackItem(0, b.present.toDouble(), Theme.of(context).colorScheme.primary),
									BarChartRodStackItem(b.present.toDouble(), total, Theme.of(context).colorScheme.tertiary),
								],
							),
						],
					),
				);
				final m = DateFormat('MMM', Localizations.localeOf(context).toString()).format(b.start);
				final yearSuffix = granularity == TimeGranularity.year ? '${b.start.year}' : '';
				monthLabels.add('$m${yearSuffix.isNotEmpty ? '\n$yearSuffix' : ''}');
			}
		final interval = math.max(1, (bars.length / 6).floor());
		return SizedBox(
			height: 240,
			child: BarChart(
				BarChartData(
					barGroups: groups,
					gridData: FlGridData(show: true, drawVerticalLine: false),
					titlesData: FlTitlesData(
						leftTitles: AxisTitles(
								axisNameWidget: Text(translation('Days')),
								axisNameSize: 18,
								sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(v.toInt().toString())),
						),
						bottomTitles: AxisTitles(
							sideTitles: SideTitles(
								showTitles: true,
								reservedSize: 34,
								interval: interval.toDouble(),
								getTitlesWidget: (value, meta) {
									final i = value.toInt();
									if (i < 0 || i >= monthLabels.length) return const SizedBox.shrink();
									return Padding(
										padding: const EdgeInsets.only(top: 6.0),
										child: Text(monthLabels[i], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
									);
								},
							),
						),
						rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
						topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
					),
								// Disable touch to avoid rare IndexError on web hover in fl_chart
								barTouchData: BarTouchData(enabled: false),
				),
			),
		);
	}

		List<HistoryBar> _computeUserHistory(Map<String, dynamic> attendance, String itemId, List<int> weekdays, TimeGranularity granularity, String? userId) {
			final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
			final buckets = <String, List<String>>{};
			for (final k in keys) {
				final dt = parseDateKey(k);
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
				(buckets[formatDateKey(start)] ??= <String>[]).add(k);
			}
			final bars = <HistoryBar>[];
			final entries = buckets.entries.toList()
				..sort((a, b) => parseDateKey(a.key).compareTo(parseDateKey(b.key)));
			for (final e in entries) {
				int p = 0, l = 0;
				for (final day in e.value) {
					final rec = (attendance[day] as Map?)?[itemId] as Map?;
					final pres = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
					final leave = ((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
					if (pres) p += 1;
					if (leave) l += 1;
				}
				bars.add(HistoryBar(parseDateKey(e.key), present: p, onLeave: l));
			}
			return bars;
		}
}

class _CalendarGrid extends StatelessWidget {
	final Map<String, dynamic> attendance;
	final String itemId;
	final List<int> weekdays;
	final String? selectedUser;
	const _CalendarGrid({required this.attendance, required this.itemId, required this.weekdays, required this.selectedUser});

	@override
	Widget build(BuildContext context) {
			// Per-user active days
			final all = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
			final Set<String> active = {
				for (final k in all)
					if (() {
						final rec = (attendance[k] as Map?)?[itemId] as Map?;
						final p = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(selectedUser);
						final l = ((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(selectedUser);
						return p || l;
					}())
						k
			};
		if (active.isEmpty) return SizedBox(height: 120, child: Center(child: Text(translation(context: context, 'No data'))));
		// Group by month
		final Map<String, List<String>> byMonth = {};
		for (final k in active) {
			final d = parseDateKey(k);
			final id = '${d.year}-${d.month.toString().padLeft(2, '0')}'
					' ${DateFormat('MMM', Localizations.localeOf(context).toString()).format(DateTime(d.year, d.month))}';
			(byMonth[id] ??= <String>[]).add(k);
		}
		final entries = byMonth.entries.toList()
			..sort((a, b) {
				final ad = parseDateKey(a.value.first);
				final bd = parseDateKey(b.value.first);
				return ad.compareTo(bd);
			});
		return Wrap(
			spacing: 10,
			runSpacing: 10,
			children: [
				for (final e in entries)
					_MonthBlock(title: e.key, dayKeys: e.value..sort())
			],
		);
	}
}

class _MonthBlock extends StatelessWidget {
	final String title;
	final List<String> dayKeys;
	const _MonthBlock({required this.title, required this.dayKeys});

	@override
	Widget build(BuildContext context) {
		final firstDay = parseDateKey(dayKeys.first);
		final lastOfMonth = DateTime(firstDay.year, firstDay.month + 1, 0);
		final totalDays = lastOfMonth.day;
		final active = dayKeys.toSet();
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(8.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(title, style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 6),
						Wrap(
							spacing: 4,
							runSpacing: 4,
							children: [
								for (int d = 1; d <= totalDays; d++)
									_DayDot(active: active.contains(formatDateKey(DateTime(firstDay.year, firstDay.month, d))))
							],
						),
					],
				),
			),
		);
	}
}

class _DayDot extends StatelessWidget {
	final bool active;
	const _DayDot({required this.active});
	@override
	Widget build(BuildContext context) {
		final c = active ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor;
		return Container(
			width: 18,
			height: 18,
			decoration: BoxDecoration(color: c.withOpacity(active ? 0.9 : 0.08), borderRadius: BorderRadius.circular(4), border: Border.all(color: c, width: 1)),
		);
	}
}

class _SeriesList extends StatelessWidget {
	final Map<String, dynamic> attendance;
	final String itemId;
	final List<int> weekdays;
	final String? selectedUser;
	const _SeriesList({required this.attendance, required this.itemId, required this.weekdays, required this.selectedUser});

	@override
	Widget build(BuildContext context) {
			final runs = _computeBestUserSeries(attendance, itemId, weekdays, selectedUser, 10);
		if (runs.isEmpty) return SizedBox(height: 100, child: Center(child: Text(translation(context: context, 'No data'))));
			final maxLen = runs.fold<int>(0, (p, e) => math.max(p, e.length));
			return Column(
				children: [
					for (int i = 0; i < runs.length; i++)
						Padding(
							padding: const EdgeInsets.symmetric(vertical: 8.0),
							child: Row(
								children: [
									SizedBox(width: 90, child: Text(formatDateKey(runs[i].start), textAlign: TextAlign.right)),
									const SizedBox(width: 8),
									Expanded(
										child: LayoutBuilder(
											builder: (context, c) {
												final width = (runs[i].length / (maxLen == 0 ? 1 : maxLen)) * c.maxWidth;
												return Stack(
													children: [
														Container(height: 24, decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.4), borderRadius: BorderRadius.circular(12))),
														Container(width: width, height: 24, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(i == 0 ? 0.9 : 0.5), borderRadius: BorderRadius.circular(12))),
														Positioned.fill(child: Center(child: Text('${runs[i].length}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary))))
													],
												);
											},
										),
									),
									const SizedBox(width: 8),
									SizedBox(width: 90, child: Text(formatDateKey(runs[i].end))),
								],
							),
						),
				],
			);
	}

		List<SeriesRun> _computeBestUserSeries(Map<String, dynamic> attendance, String itemId, List<int> weekdays, String? userId, int limit) {
			final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
			if (keys.isEmpty) return const [];
			DateTime? runStart;
			DateTime? lastDate;
			final runs = <SeriesRun>[];
			for (final k in keys) {
				final dt = parseDateKey(k);
				final rec = (attendance[k] as Map?)?[itemId] as Map?;
				final positive = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(userId) ||
						((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(userId);
				if (positive) {
					if (runStart == null) {
						runStart = dt;
					} else if (lastDate != null) {
						final expectedNext = lastDate.add(const Duration(days: 1));
						if (dt.isAfter(expectedNext)) {
							runs.add(SeriesRun(runStart, lastDate));
							runStart = dt;
						}
					}
					lastDate = dt;
				} else {
					if (runStart != null && lastDate != null) runs.add(SeriesRun(runStart, lastDate));
					runStart = null;
					lastDate = null;
				}
			}
			if (runStart != null && lastDate != null) runs.add(SeriesRun(runStart, lastDate));
			runs.sort((a, b) => b.length.compareTo(a.length));
			return runs.take(limit).toList();
		}
}

class _HeatmapBubbles extends StatelessWidget {
	final Map<String, dynamic> attendance;
	final String itemId;
	final List<int> weekdays;
	final String? selectedUser;
	const _HeatmapBubbles({required this.attendance, required this.itemId, required this.weekdays, required this.selectedUser});

	@override
	Widget build(BuildContext context) {
		// Build weekday (rows) x last 13 months (columns) bubble counts
		final locale = Localizations.localeOf(context).toString();
		final now = DateTime.now();
		final months = <DateTime>[for (int i = 12; i >= 0; i--) DateTime(now.year, now.month - i, 1)];
		final monthKeys = months.map((m) => '${m.year}-${m.month.toString().padLeft(2, '0')}').toList();
		final keys = normalizedDatesForItem(attendance, itemId, weekdays: weekdays);
		final Map<int, Map<String, int>> data = {for (int wd = 1; wd <= 7; wd++) wd: {for (final mk in monthKeys) mk: 0}};
			for (final k in keys) {
			final d = parseDateKey(k);
			final mk = '${d.year}-${d.month.toString().padLeft(2, '0')}';
			if (!monthKeys.contains(mk)) continue;
				final rec = (attendance[k] as Map?)?[itemId] as Map?;
				final positive = ((rec?['present'] as List?)?.cast<String>() ?? const <String>[]).contains(selectedUser) ||
						((rec?['onLeave'] as List?)?.cast<String>() ?? const <String>[]).contains(selectedUser);
				if (positive) {
				data[d.weekday]![mk] = (data[d.weekday]![mk] ?? 0) + 1;
			}
		}
		int maxCount = 0;
		for (final row in data.values) {
			for (final c in row.values) {
				if (c > maxCount) maxCount = c;
			}
		}
		if (maxCount == 0) return SizedBox(height: 120, child: Center(child: Text(translation(context: context, 'No data'))));

			String wdLabel(int wd) {
			switch (wd) {
					case DateTime.monday:
						return translation('Mon.');
					case DateTime.tuesday:
						return translation('Tue.');
					case DateTime.wednesday:
						return translation('Wed.');
					case DateTime.thursday:
						return translation('Thu.');
					case DateTime.friday:
						return translation('Fri.');
					case DateTime.saturday:
						return translation('Sat.');
					case DateTime.sunday:
						return translation('Sun.');
				default:
					return '';
			}
		}

			return Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					for (int wd = 1; wd <= 7; wd++)
						Padding(
							padding: const EdgeInsets.symmetric(vertical: 4.0),
							child: Center(
								child: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										SizedBox(width: 36, child: Align(alignment: Alignment.centerRight, child: Text(wdLabel(wd)))),
										const SizedBox(width: 4),
										for (final mk in monthKeys)
											SizedBox(
												width: 28,
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
					// Month labels under the heatmap, centered
					Center(
						child: Row(
							mainAxisSize: MainAxisSize.min,
							children: [
								const SizedBox(width: 36 + 4),
								for (final m in months)
									SizedBox(
										width: 28,
										child: Text(
											DateFormat('MMM', locale).format(m),
											textAlign: TextAlign.center,
											style: Theme.of(context).textTheme.bodySmall,
										),
									),
							],
						),
					),
				],
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
				color: faded ? Theme.of(context).dividerColor.withOpacity(0.3) : color.withOpacity(0.85),
				shape: BoxShape.circle,
			),
		);
	}
}


