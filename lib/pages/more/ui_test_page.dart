import 'package:flutter/material.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:faunty/components/table_widget.dart';
// role gating not needed on the debug UI page
import 'package:faunty/state_management/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/state_management/custom_list_provider.dart';
// custom list model/service used via providers

class UiTestPage extends ConsumerStatefulWidget {
  const UiTestPage({super.key});

  @override
  ConsumerState<UiTestPage> createState() => _UiTestPageState();
}

class _UiTestPageState extends ConsumerState<UiTestPage> {
  bool showColumnHeaders = true;
  final Set<String> _migratedLists = {};

  @override
  Widget build(BuildContext context) {
    // watch custom lists for current place (use globalsProvider for placeId indirectly via user)
    final userAsync = ref.watch(userProvider);
    final user = userAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context: context, 'UI Test Page')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(
            translation(context: context, 'This page is only visible in debug mode.'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),

          // toggle show column headers
          SwitchListTile(
            title: Text(translation(context: context, 'Show column headers')),
            value: showColumnHeaders,
            onChanged: (v) => setState(() => showColumnHeaders = v),
          ),

          const SizedBox(height: 12),

          if (user == null) const CircularProgressIndicator() else
          // Read lists and items from Firestore using providers
          Expanded(child: Builder(builder: (ctx) {
            return ref.watch(customListsProvider(user.placeId)).when(
              data: (lists) {
                if (lists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No lists found'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final svc = ref.read(customListServiceProvider);
                            // Build a minimal CustomList object; createList will write serverTimestamp
                            final sample = CustomList(
                              id: '',
                              title: 'UiTest Sample',
                              type: CustomListType.assignment,
                              createdBy: user.uid,
                              createdAt: Timestamp.now(),
                              order: 0,
                              visible: true,
                            );
                            try {
                              final listId = await svc.createList(user.placeId, sample);
                              // add a couple of items
                              await svc.addItem(user.placeId, listId, {'type': 'assignment', 'left': '08:00', 'right': 'Breakfast'});
                              await svc.addItem(user.placeId, listId, {'type': 'assignment', 'left': '09:00', 'right': 'Meeting'});
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample list created')));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          },
                          child: const Text('Create test list in Firestore'),
                        ),
                      ],
                    ),
                  );
                }
                final first = lists.first;
                final svc = ref.read(customListServiceProvider);
                final key = ListKey(user.placeId, first.id);
                return ref.watch(customListItemsProvider(key)).when(
                  data: (items) {
                    // map ListItem.payload into TableWidget items
                    final mapped = <dynamic>[];
                    // flattened map: each entry corresponds to one TableRow and contains docId and rowIndex if nested
                    final flattened = <Map<String, dynamic>>[];
                    bool hasSubsectionDocs = false;
                    for (final li in items) {
                      final payload = li.payload;
                      final type = payload['type'] as String? ?? 'assignment';
                      if (type == 'subsection') {
                        hasSubsectionDocs = true;
                        final title = payload['title'] as String? ?? '';
                        final rowsData = (payload['rows'] as List<dynamic>?) ?? [];
                        final rows = <Assignment>[];
                        for (int ri = 0; ri < rowsData.length; ri++) {
                          final r = rowsData[ri] as Map<String, dynamic>;
                          rows.add(Assignment(left: r['left'] ?? '', right: r['right'] ?? ''));
                          flattened.add({'docId': li.id, 'isSub': true, 'rowIndex': ri});
                        }
                        mapped.add(Subsection(title: title, rows: rows));
                      } else {
                        final left = payload['left'] as String? ?? '';
                        final right = payload['right'] as String? ?? '';
                        mapped.add(Assignment(left: left, right: right));
                        flattened.add({'docId': li.id, 'isSub': false});
                      }
                    }

                    // If we detect subsection documents and haven't migrated this list yet,
                    // schedule an automatic migration once and show a snackbar on completion.
                    if (hasSubsectionDocs && !_migratedLists.contains(first.id)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        () async {
                          try {
                            await svc.migrateSubsectionsToPerRow(user.placeId, first.id);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-migration complete')));
                            setState(() => _migratedLists.add(first.id));
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-migration failed: $e')));
                          }
                        }();
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TableWidget(
                          items: mapped,
                          showColumnHeaders: showColumnHeaders,
                          leftHeader: translation(context: context, 'Left'),
                          rightHeader: translation(context: context, 'Right'),
                          onSave: (index, left, newValue) async {
                            if (index < 0 || index >= flattened.length) return;
                            final entry = flattened[index];
                            final svc = ref.read(customListServiceProvider);
                            final docId = entry['docId'] as String;
                            if (entry['isSub'] == true) {
                              final rowIndex = entry['rowIndex'] as int;
                              await svc.updateRowInItem(user.placeId, first.id, docId, rowIndex, left ? 'left' : 'right', newValue);
                            } else {
                              final key = left ? 'left' : 'right';
                              await svc.updateItem(user.placeId, first.id, docId, {'payload': {key: newValue}});
                            }
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            );
          })),
        ]),
      ),
    );
  }
}

// TableWidget has been moved to `lib/components/table_widget.dart` and is imported above.

// No local dummy data here — this page reads custom lists from Firestore.

