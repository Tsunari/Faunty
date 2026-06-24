import 'package:faunty/core/widgets/custom_confirm_dialog.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/features/lists/presentation/controllers/program_provider.dart';

class ProgramOrganisationPage extends ConsumerStatefulWidget {
  final Map<String, List<Map<String, String>>> weekProgram;
  const ProgramOrganisationPage({super.key, required this.weekProgram});

  @override
  ConsumerState<ProgramOrganisationPage> createState() => _ProgramOrganisationPageState();
}

class _ProgramOrganisationPageState extends ConsumerState<ProgramOrganisationPage> {
  String? loadedTemplateName;
  late Map<String, List<Map<String, String>>> localWeekProgram;
  final List<String> weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  List<Map<String, String>> _sortEntries(List<Map<String, String>> entries) {
    entries.sort((a, b) {
      final aTime = a['from'] ?? '';
      final bTime = b['from'] ?? '';
      return aTime.compareTo(bTime);
    });
    return entries;
  }

  @override
  void initState() {
    super.initState();
    localWeekProgram = {
      for (final day in weekDays)
        day: _sortEntries(widget.weekProgram[day]?.map((entry) => Map<String, String>.from(entry)).toList() ?? [])
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Organisation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add), //#Icon Save as Template
            tooltip: translation(context: context, 'Save as template'),
            onPressed: () async {
              final nameController = TextEditingController();
              final service = ref.read(programFirestoreServiceProvider);
              final templates = await service.getTemplates();
              String? selectedTemplate;
              int tabIndex = templates.isNotEmpty ? 0 : 1;
              if (!context.mounted) return;
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  final theme = Theme.of(context);
                  return StatefulBuilder(
                    builder: (context, setState) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          Icon(Icons.bookmark_add_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            translation('Save as template', context: context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: SizedBox(
                        width: 320,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: SegmentedButton<int>(
                                segments: [
                                  ButtonSegment<int>(
                                    value: 0,
                                    label: Text(translation('Override existing', context: context)),
                                    icon: const Icon(Icons.edit_note_rounded),
                                    enabled: templates.isNotEmpty,
                                  ),
                                  ButtonSegment<int>(
                                    value: 1,
                                    label: Text(translation('Create new', context: context)),
                                    icon: const Icon(Icons.add_circle_outline_rounded),
                                  ),
                                ],
                                selected: {tabIndex},
                                onSelectionChanged: (val) {
                                  setState(() => tabIndex = val.first);
                                },
                                showSelectedIcon: false,
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor: theme.colorScheme.primaryContainer,
                                  selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (tabIndex == 0 && templates.isNotEmpty) ...[
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: selectedTemplate,
                                decoration: InputDecoration(
                                  labelText: translation('Select template to override', context: context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                items: templates.keys.map((name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                )).toList(),
                                onChanged: (val) => setState(() => selectedTemplate = val),
                              ),
                            ],
                            if (tabIndex == 1) ...[
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: translation('Template name', context: context),
                                  prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(translation('Cancel', context: context)),
                        ),
                        if (tabIndex == 1)
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.trim().isNotEmpty) {
                                Navigator.pop(context, nameController.text.trim());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            child: Text(translation('Create', context: context)),
                          ), 
                        if (tabIndex == 0)
                          ElevatedButton(
                            onPressed: selectedTemplate == null
                                ? null
                                : () async {
                                    await service.setTemplate(selectedTemplate!, localWeekProgram);
                                    setState(() {});
                                    if (context.mounted) {
                                      Navigator.pop(context, selectedTemplate);
                                      showCustomSnackBar(context, 'Template "$selectedTemplate" overridden.');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            child: Text(translation('Override', context: context)),
                          ),
                      ],
                    ),
                  );
                },
              );
              if (result != null && result.isNotEmpty) {
                await service.setTemplate(result, localWeekProgram);
                if (!mounted) return;
                setState(() {
                  loadedTemplateName = result;
                });
                if (context.mounted) {
                  showCustomSnackBar(context, 'Template "$result" saved.');
                }
              }
            },
          ),
          FutureBuilder<Map<String, Map<String, List<Map<String, String>>>>> (
            future: ref.read(programFirestoreServiceProvider).getTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final templates = snapshot.data ?? {};
              if (templates.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.folder_special_rounded),
                tooltip: translation('Load template', context: context),
                onPressed: () async {
                  final service = ref.read(programFirestoreServiceProvider);
                  var templates = await service.getTemplates();
                  if (!mounted) return;
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) => _TemplateSelectionDialog(
                      templates: templates,
                      onDelete: (name) async {
                        await service.deleteTemplate(name);
                        if (context.mounted) {
                          showCustomSnackBar(context, 'Template "$name" deleted.');
                        }
                      },
                      onUpdate: (name) async {
                        await service.setTemplate(name, localWeekProgram);
                        if (context.mounted) {
                          showCustomSnackBar(context, 'Template "$name" updated.');
                        }
                        templates = await service.getTemplates();
                        return templates;
                      },
                    ),
                  );
                  templates = await service.getTemplates();
                  if (selected != null && templates.containsKey(selected)) {
                    setState(() {
                      localWeekProgram = {
                        for (final day in weekDays)
                          day: (templates[selected]![day] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? []
                      };
                      loadedTemplateName = selected;
                    });
                    if (context.mounted) {
                      showCustomSnackBar(context, 'Template "$selected" loaded.');
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: _ProgramList(
            weekDays: weekDays,
            localWeekProgram: localWeekProgram,
            isDark: isDark,
            onChanged: (day, entries) {
              setState(() {
                localWeekProgram[day] = _sortEntries(List<Map<String, String>>.from(entries));
              });
            },
          ),
        ),
      ),
      floatingActionButton: _SaveFab(
        isDark: isDark,
        onSave: () async {
          final sortedWeekProgram = {
            for (final day in weekDays)
              day: _sortEntries(List<Map<String, String>>.from(localWeekProgram[day]!))
          };
          final service = ref.read(programFirestoreServiceProvider);
          await service.setWeekProgram(sortedWeekProgram);
          if (context.mounted) Navigator.pop(context, sortedWeekProgram);
        },
      ),
    );
  }
}

class _TemplateSelectionDialog extends StatefulWidget {
  final Map<String, Map<String, List<Map<String, String>>>> templates;
  final String? loadedTemplateName;
  final Future<void> Function(String name) onDelete;
  final Future<Map<String, Map<String, List<Map<String, String>>>>> Function(String name) onUpdate;
  const _TemplateSelectionDialog({required this.templates, required this.onDelete, required this.onUpdate, this.loadedTemplateName});

  @override
  State<_TemplateSelectionDialog> createState() => _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<_TemplateSelectionDialog> {
  late Map<String, Map<String, List<Map<String, String>>>> _templates;

  @override
  void initState() {
    super.initState();
    _templates = Map<String, Map<String, List<Map<String, String>>>>.from(widget.templates);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.folder_special_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            translation('Select a template', context: context),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: _templates.isEmpty
            ? SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 40, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text(
                        translation('No templates found', context: context),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final name = _templates.keys.elementAt(idx);
                  final isCurrent = widget.loadedTemplateName == name;
                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: isCurrent
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                        : theme.colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context, name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                  color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              tooltip: translation('Delete template', context: context),
                              onPressed: () async {
                                final confirm = await showDeleteDialog(context: context, thingToDelete: name);
                                if (confirm == true) {
                                  await widget.onDelete(name);
                                  setState(() {
                                    _templates.remove(name);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          label: Text(translation('Close', context: context)),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _ProgramList extends StatelessWidget {
  final List<String> weekDays;
  final Map<String, List<Map<String, String>>> localWeekProgram;
  final bool isDark;
  final void Function(String day, List<Map<String, String>> entries) onChanged;
  const _ProgramList({required this.weekDays, required this.localWeekProgram, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: 7,
      itemBuilder: (context, idx) {
        final dayName = weekDays[idx];
        final dayLabel = translation(dayName, context: context);
        return _ProgramDayCard(
          dayName: dayName,
          dayLabel: dayLabel,
          entries: localWeekProgram[dayName]!,
          weekProgram: localWeekProgram,
          isDark: isDark,
          onChanged: (entries) => onChanged(dayName, entries),
        );
      },
    );
  }
}

class _ProgramDayCard extends StatelessWidget {
  final String dayName;
  final String dayLabel;
  final List<Map<String, String>> entries;
  final Map<String, List<Map<String, String>>> weekProgram;
  final bool isDark;
  final void Function(List<Map<String, String>> entries) onChanged;
  const _ProgramDayCard({required this.dayName, required this.dayLabel, required this.entries, required this.weekProgram, required this.isDark, required this.onChanged});

  List<Map<String, String>> _sortEntries(List<Map<String, String>> entries) {
    entries.sort((a, b) {
      final aTime = a['from'] ?? '';
      final bTime = b['from'] ?? '';
      return aTime.compareTo(bTime);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortedEntries = _sortEntries(List<Map<String, String>>.from(entries));
    return Card(
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.copy_all_rounded, color: colorScheme.primary),
                  tooltip: translation('Copy from another day', context: context),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                  onSelected: (copyDay) {
                    if (copyDay != dayName) {
                      final copied = weekProgram[copyDay]?.map((e) => Map<String, String>.from(e)).toList() ?? [];
                      onChanged(_sortEntries(copied));
                    }
                  },
                  itemBuilder: (context) {
                    return List.generate(7, (i) {
                      final wDayName = _weekDayName(i, false);
                      final wDayLabel = _weekDayName(i, true);
                      return PopupMenuItem<String>(
                        value: wDayName,
                        enabled: wDayName != dayName,
                        child: Text(wDayLabel),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    translation('No events planned', context: context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedEntries.length,
                itemBuilder: (context, entryIdx) {
                  final entry = sortedEntries[entryIdx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _ProgramEntryTile(
                      entry: entry,
                      isDark: isDark,
                      onChanged: (updated) {
                        final newEntries = List<Map<String, String>>.from(sortedEntries);
                        newEntries[entryIdx] = updated;
                        onChanged(_sortEntries(newEntries));
                      },
                      onDelete: () {
                        final newEntries = List<Map<String, String>>.from(sortedEntries);
                        newEntries.removeAt(entryIdx);
                        onChanged(_sortEntries(newEntries));
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final newEntry = await _showAddEditDialog(context);
                  if (newEntry != null) {
                    final newEntries = List<Map<String, String>>.from(sortedEntries);
                    newEntries.add(newEntry);
                    onChanged(_sortEntries(newEntries));
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(translation('Add event', context: context)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekDayName(int idx, bool translated) {
    final days = translated ? [translation('Monday'), translation('Tuesday'), translation('Wednesday'), translation('Thursday'), translation('Friday'), translation('Saturday'), translation('Sunday')] : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[idx];
  }
}

class _ProgramEntryTile extends StatelessWidget {
  final Map<String, String> entry;
  final bool isDark;
  final void Function(Map<String, String> updated) onChanged;
  final VoidCallback onDelete;
  const _ProgramEntryTile({required this.entry, required this.isDark, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await _showAddEditDialog(context, entry: entry);
              if (result != null) {
                onChanged(result);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry['from']} - ${entry['to']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      entry['event'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                    tooltip: translation('Delete event', context: context),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Map<String, String>?> _showAddEditDialog(BuildContext context, {Map<String, String>? entry}) async {
  TimeOfDay? fromTime = entry != null ? _parseTime(entry['from']) : null;
  TimeOfDay? toTime = entry != null ? _parseTime(entry['to']) : null;
  final eventController = TextEditingController(text: entry?['event'] ?? '');
  final theme = Theme.of(context);
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(
                  entry == null ? Icons.add_circle_outline_rounded : Icons.edit_calendar_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  entry == null ? translation('Add new event', context: context) : translation('Edit event', context: context),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translation('Time Slot', context: context),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: fromTime ?? TimeOfDay.now(),
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => fromTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 18),
                          label: Text(fromTime == null
                              ? translation('Start', context: context)
                              : ('${fromTime!.hour.toString().padLeft(2, '0')}:${fromTime!.minute.toString().padLeft(2, '0')}')),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: toTime ?? TimeOfDay.now(),
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => toTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time_filled_rounded, size: 18),
                          label: Text(toTime == null
                              ? translation('End', context: context)
                              : ('${toTime!.hour.toString().padLeft(2, '0')}:${toTime!.minute.toString().padLeft(2, '0')}')),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: eventController,
                    decoration: InputDecoration(
                      labelText: translation('Title', context: context),
                      prefixIcon: const Icon(Icons.title_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translation('Cancel', context: context)),
              ),
              ElevatedButton(
                onPressed: (fromTime != null && toTime != null && eventController.text.trim().isNotEmpty)
                    ? () {
                        String fromStr = '${fromTime!.hour.toString().padLeft(2, '0')}:${fromTime!.minute.toString().padLeft(2, '0')}';
                        String toStr = '${toTime!.hour.toString().padLeft(2, '0')}:${toTime!.minute.toString().padLeft(2, '0')}';
                        Navigator.pop(context, {
                          'from': fromStr,
                          'to': toStr,
                          'event': eventController.text.trim(),
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: Text(entry == null ? translation('Add', context: context) : translation('Save', context: context)),
              ),
            ],
          );
        },
      );
    },
  );
}

TimeOfDay? _parseTime(String? time) {
  if (time == null) return null;
  final parts = time.split(':');
  if (parts.length != 2) return null;
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

class _SaveFab extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onSave;
  const _SaveFab({required this.isDark, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onSave,
      tooltip: translation('Save and go back', context: context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      child: const Icon(Icons.save_rounded),
    );
  }
}