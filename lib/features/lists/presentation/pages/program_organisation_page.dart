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
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: Text(translation(context: context, 'Save as template')),
                    content: SizedBox(
                      width: 300,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => tabIndex = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: tabIndex == 0 ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Override existing',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: tabIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => tabIndex = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: tabIndex == 1 ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Create new',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: tabIndex == 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (tabIndex == 0 && templates.isNotEmpty) ...[
                            DropdownButton<String>(
                              isExpanded: true,
                              value: selectedTemplate,
                              hint: Text(translation(context: context, 'Select template to override')),
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
                              decoration: InputDecoration(labelText: translation(context: context, 'Template name')),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          if (tabIndex == 1)
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.trim().isNotEmpty) {
                                Navigator.pop(context, nameController.text.trim());
                              }
                            },
                            child: const Text('Create'),
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
                                      showCustomSnackBar(context, 'Template "$selectedTemplate" overridden.'); // TODO: Localize
                                    }
                                  },
                            child: Text(translation(context: context, 'Override')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              if (result != null && result.isNotEmpty) {
                await service.setTemplate(result, localWeekProgram);
                if (!mounted) return;
                setState(() {
                  loadedTemplateName = result;
                });
                if (context.mounted) {
                  showCustomSnackBar(context, 'Template "$result" saved.'); // TODO: Localize
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
                icon: const Icon(Icons.folder_special), //#icon load template
                tooltip: translation(context: context, 'Load template'),
                onPressed: () async {
                  final service = ref.read(programFirestoreServiceProvider);
                  var templates = await service.getTemplates();
                  if (!mounted) return;
                  final selected = await showDialog<String>(
                    context: context, // TODO: Solution for this
                    builder: (context) => _TemplateSelectionDialog(
                      templates: templates,
                      // loadedTemplateName: loadedTemplateName, // TODO: Cool? not cool?
                      onDelete: (name) async {
                        await service.deleteTemplate(name);
                        if (context.mounted) {
                          showCustomSnackBar(context, 'Template "$name" deleted.'); // TODO: Localize
                        }
                      },
                      onUpdate: (name) async {
                        await service.setTemplate(name, localWeekProgram);
                        if (context.mounted) {
                          showCustomSnackBar(context, 'Template "$name" updated.'); // TODO: Localize
                        }
                        // Fetch latest templates after update and update dialog state
                        templates = await service.getTemplates();
                        return templates;
                      },
                    ),
                  );
                  // Always fetch latest templates after dialog closes
                  templates = await service.getTemplates();
                  if (selected != null && templates.containsKey(selected)) {
                    setState(() {
                      // Deep copy to avoid reference issues
                      localWeekProgram = {
                        for (final day in weekDays)
                          day: (templates[selected]![day] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? []
                      };
                      loadedTemplateName = selected;
                    });
                    if (context.mounted) {
                      showCustomSnackBar(context, 'Template "$selected" loaded.'); // TODO: Localize
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
          // Sort all days before saving
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      actionsPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(translation(context: context, 'Select a template')),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: _templates.isEmpty
            ? SizedBox(
                height: 48,
                child: Center(
                  child: Text(translation(context: context, 'No templates found'), style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _templates.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                itemBuilder: (context, idx) {
                  final name = _templates.keys.elementAt(idx);
                  final isCurrent = widget.loadedTemplateName == name;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, name),
                      child: Container(
                        decoration: isCurrent
                            ? BoxDecoration(
                                border: Border.all(color: Colors.teal, width: 2),
                                // borderRadius: BorderRadius.circular(10),
                                color: theme.colorScheme.secondary.withOpacity(0.08),
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            // IconButton(
                            //   icon: const Icon(Icons.system_update_alt, color: Colors.blueAccent),
                            //   tooltip: 'Update template with current configuration',
                            //   onPressed: () async {
                            //     final updatedTemplates = await widget.onUpdate(name);
                            //     setState(() {
                            //       _templates.clear();
                            //       _templates.addAll(updatedTemplates);
                            //     });
                            //   },
                            // ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: translation(context: context, 'Delete template'),
                              onPressed: () async {
                                final confirm = await showDeleteDialog(context: context);
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: Text(translation(context: context, 'Close')),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              textStyle: theme.textTheme.labelLarge,
              padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
            ),
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
        final dayLabel = translation(context: context, dayName);
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
    final sortedEntries = _sortEntries(List<Map<String, String>>.from(entries));
    return Card(
      color: Theme.of(context).colorScheme.onInverseSurface,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dayLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    hint: const Text('Copy', style: TextStyle(fontSize: 12)),
                    value: null,
                    style: const TextStyle(fontSize: 12),
                    isDense: true,
                    alignment: Alignment.centerLeft,
                    underline: const SizedBox.shrink(),
                    iconSize: 18,
                    items: [
                      ...List.generate(7, (i) => DropdownMenuItem<String>(
                        value: _weekDayName(i, false),
                        child: Text(_weekDayName(i, true), style: const TextStyle(fontSize: 12)),
                      ))
                    ],
                    onChanged: (copyDay) {
                      if (copyDay != null && copyDay != dayName) {
                        // Copy entries from selected day into current day
                        final copied = weekProgram[copyDay]?.map((e) => Map<String, String>.from(e)).toList() ?? [];
                        onChanged(_sortEntries(copied));
                      }
                    },
                    dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...sortedEntries.asMap().entries.map((entryMap) {
                    final entry = entryMap.value;
                    final entryIdx = entryMap.key;
                    return _ProgramEntryTile(
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
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final newEntry = await _showAddEditDialog(context);
                        if (newEntry != null) {
                          final newEntries = List<Map<String, String>>.from(sortedEntries);
                          newEntries.add(newEntry);
                          onChanged(_sortEntries(newEntries));
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add event'),
                    ),
                  ),
                ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 4.0),
      child: GestureDetector(
        onTap: () async {
          final result = await _showAddEditDialog(context, entry: entry);
          if (result != null) {
            onChanged(result);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                '${entry['from']} - ${entry['to']}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry['event']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete event',
                onPressed: onDelete,
              ),
            ],
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
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(entry == null ? translation(context: context, 'Add new event') : translation(context: context, 'Edit event')),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
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
                          child: Text(fromTime == null
                              ? translation(context: context, 'Select start time')
                              : ('${fromTime!.hour.toString().padLeft(2, '0')}:${fromTime!.minute.toString().padLeft(2, '0')}')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
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
                          child: Text(toTime == null
                              ? translation(context: context, 'Select end time')
                              : ('${toTime!.hour.toString().padLeft(2, '0')}:${toTime!.minute.toString().padLeft(2, '0')}')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: eventController,
                    decoration: InputDecoration(labelText: translation(context: context, 'Title')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translation(context: context, 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  if (fromTime != null && toTime != null && eventController.text.isNotEmpty) {
                    String fromStr = '${fromTime!.hour.toString().padLeft(2, '0')}:${fromTime!.minute.toString().padLeft(2, '0')}';
                    String toStr = '${toTime!.hour.toString().padLeft(2, '0')}:${toTime!.minute.toString().padLeft(2, '0')}';
                    Navigator.pop(context, {
                      'from': fromStr,
                      'to': toStr,
                      'event': eventController.text,
                    });
                  }
                },
                child: Text(entry == null ? translation(context: context, 'Add') : translation(context: context, 'Save')),
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
      tooltip: translation(context: context, 'Save and go back'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: isDark ? Colors.black : Colors.white,
      child: const Icon(Icons.save),
    );
  }
}