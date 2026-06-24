import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/globals.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/features/lists/presentation/pages/program_organisation_calendar_v2.dart';
import 'package:faunty/core/utils/pdf_generator/program_pdf_layout.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/presentation/pages/program_organisation_page.dart';
import 'package:faunty/features/lists/presentation/controllers/program_provider.dart';
import 'package:faunty/core/widgets/tab_page.dart';
import 'package:faunty/features/profile/presentation/widgets/navigation_bar.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';


const List<String> weekDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const List<String> weekDaysShort = [
  'Mo', 'Tue', 'Wed', 'Thu', 'Fr', 'Sat', 'Sun'
];

class ProgramPage extends ConsumerStatefulWidget {
  const ProgramPage({super.key});

  @override
  ConsumerState<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends ConsumerState<ProgramPage> {
  String getWeekdayFromDate(DateTime date) {
    // For Firestore key lookup (full name)
    return weekDays[(date.weekday - 1) % 7];
  }
  String getWeekdayShort(DateTime date, BuildContext context) {
    // For UI display (short name, translated)
    final short = weekDaysShort[(date.weekday - 1) % 7];
    return translation(context: context, short);
  }

  int _minutesFromString(String? time) {
    if (time == null || time.isEmpty) return 0;
    final parts = time.split(':');
    try {
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? int.parse(parts[1]) : 0;
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  List<Map<String, dynamic>> _sortedCopyOfEntries(List<dynamic> entries) {
    final copied = entries.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    copied.sort((a, b) => _minutesFromString(a['from'] as String?).compareTo(_minutesFromString(b['from'] as String?)));
    return copied;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final weekProgramAsync = ref.watch(weekProgramProvider);
    return weekProgramAsync.when(
      data: (weekProgram) {
        // Create a sorted copy of the week program (sorted by 'from' time)
        final Map<String, List<Map<String, dynamic>>> sortedWeekProgram = {};
        weekProgram.forEach((day, entries) {
          sortedWeekProgram[day] = _sortedCopyOfEntries(entries ?? []);
        });

        // Build a list of days (date, dayName, dayShort, entries) where entries is not empty
        final List<Map<String, dynamic>> daysWithPrograms = [];
        for (int idx = 0; idx < 7; idx++) {
          final date = now.add(Duration(days: idx));
          final dayName = getWeekdayFromDate(date);
          final dayShort = getWeekdayShort(date, context);
          final entries = sortedWeekProgram[dayName] ?? [];
          if (entries.isNotEmpty) {
            daysWithPrograms.add({
              'date': date,
              'dayName': dayName,
              'dayShort': dayShort,
              'entries': entries,
            });
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(tabAppBarConfigProvider('Program').notifier).state = TabAppBarConfig(
            pdfLayout: ProgramPdfLayout(),
            onGeneratePdf: () async {
              final Map<String, List<Map<String, dynamic>>> pdfData = {};
              for (final dayName in weekDays) {
                final entries = sortedWeekProgram[dayName] ?? [];
                if (entries.isEmpty) {
                  continue;
                }
                pdfData[dayName] = entries.map((e) => {
                  'From': e['from'],
                  'To': e['to'],
                  'Event': e['event'],
                }).toList();
              }
              return pdfData;
            },
          );
        });

        return Scaffold(
          floatingActionButtonLocation: const OffsettedFABLocation(FloatingActionButtonLocation.endFloat, 80.0),
          appBar: null,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: daysWithPrograms.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 96, 24, 96),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: notFoundIconColor(context)),
                          const SizedBox(height: 24),
                          Text(
                            translation(context: context, 'No program entries for this week!'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          RoleGate(
                            minRole: UserRole.baskan,
                            child: Text(
                              translation(context: context, 'Tap the edit button below to add a program for the week.'),
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: daysWithPrograms.length,
                      padding: const EdgeInsets.fromLTRB(12, 96, 12, 96),
                      itemBuilder: (context, idx) {
                        final day = daysWithPrograms[idx];
                        final date = day['date'] as DateTime;
                        final dayShort = day['dayShort'] as String;
                        final entries = day['entries'] as List;
                        final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
                        TimeOfDay nowTime = TimeOfDay.now();
                        int? currentEventIdx;
                        
                        if (isToday) {
                          for (int i = 0; i < entries.length; i++) {
                            final fromParts = (entries[i]['from'] as String).split(':');
                            final toParts = (entries[i]['to'] as String).split(':');
                            final from = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
                            final to = TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1]));
                            bool afterFrom = nowTime.hour > from.hour || (nowTime.hour == from.hour && nowTime.minute >= from.minute);
                            bool beforeTo = nowTime.hour < to.hour || (nowTime.hour == to.hour && nowTime.minute <= to.minute);
                            if (afterFrom && beforeTo) {
                              currentEventIdx = i;
                              break;
                            }
                          }
                        }

                        final theme = Theme.of(context);
                        final colorScheme = theme.colorScheme;

                        return Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isToday 
                                  ? colorScheme.primary.withValues(alpha: 0.3)
                                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: isToday ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? colorScheme.primary
                                            : colorScheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        dayShort,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          translation(context: context, 'Today'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Timeline List of Entries
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: entries.length,
                                  itemBuilder: (context, entryIdx) {
                                    final entry = entries[entryIdx];
                                    final isCurrent = isToday && currentEventIdx == entryIdx;
                                    final isLast = entryIdx == entries.length - 1;

                                    return IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Timeline indicator bar on the left
                                          Column(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: isCurrent ? colorScheme.primary : colorScheme.outlineVariant,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isCurrent 
                                                        ? colorScheme.primaryContainer 
                                                        : colorScheme.surfaceContainer,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                              if (!isLast)
                                                Expanded(
                                                  child: Container(
                                                    width: 2,
                                                    color: isCurrent ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outlineVariant.withValues(alpha: 0.4),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          // Event details card
                                          Expanded(
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isCurrent 
                                                    ? colorScheme.primary.withValues(alpha: 0.06)
                                                    : colorScheme.surface,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isCurrent
                                                      ? colorScheme.primary.withValues(alpha: 0.4)
                                                      : colorScheme.outlineVariant.withValues(alpha: 0.15),
                                                  width: isCurrent ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        '${entry['from']} - ${entry['to']}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                      if (isCurrent)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.primary,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.sensors_rounded, size: 10, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text(
                                                                'LIVE',
                                                                style: TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    entry['event'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                                      fontSize: 14,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          floatingActionButton: RoleGate(
            minRole: UserRole.baskan,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'editProgramFab',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProgramOrganisationPage(
                          weekProgram: weekProgram,
                        ),
                      ),
                    );
                  },
                  tooltip: translation(context: context, 'Edit program'),
                  child: const Icon(Icons.edit),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'newCalendarFab',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProgramOrganisationCalendarV2()),
                    );
                  },
                  tooltip: translation(context: context, 'New calendar UI'),
                  child: const Icon(Icons.calendar_view_day),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading program: $e')),
    );
  }
}