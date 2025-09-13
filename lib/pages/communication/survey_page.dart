import 'package:faunty/state_management/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/components/custom_app_bar.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:faunty/components/custom_snackbar.dart';
import 'package:faunty/state_management/survey_provider.dart';
import 'package:faunty/state_management/user_list_provider.dart';

class SurveyPage extends ConsumerStatefulWidget {
  const SurveyPage({super.key});

  @override
  ConsumerState<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends ConsumerState<SurveyPage> {
  // Track pending vote operations to avoid race conditions from fast clicks
  final Set<String> _pendingActions = {};

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final usersByPlaceAsync = ref.watch(usersByCurrentPlaceProvider);
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(translation('Error loading user', context: context))),
      data: (user) {
        if (user == null) {
          return Center(child: Text(translation('No user loaded', context: context)));
        }
        final userId = user.uid;
        final placeId = user.placeId;
        final surveyAsync = ref.watch(surveyProvider(placeId));
        final surveyService = ref.read(surveyFirestoreServiceProvider(placeId));
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return usersByPlaceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(translation('Error loading users', context: context))),
          data: (usersByPlace) {
            final userMap = {for (final u in usersByPlace) u.uid: u};
            return Scaffold(
              appBar: CustomAppBar(
                title: translation('Survey', context: context),
              ),
              body: surveyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text(translation('Error loading surveys', context: context))),
                data: (surveys) {
                  if (surveys.isEmpty) {
                    return Center(child: Text(translation('No surveys available', context: context)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    itemCount: surveys.length,
                    itemBuilder: (context, index) {
                      final survey = surveys[index];
                      final options = (survey['options'] as List)
                          .map((e) => Map<String, dynamic>.from(e as Map))
                          .toList();
                      final surveyId = survey['id'];
                      return Card(
                        color: isDark ? Colors.grey[850] : null,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      translation(survey['title'], context: context),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: translation('Edit', context: context),
                                    onPressed: () async {
                                      String editTitle = survey['title'];
                                      List<String> editOptions = List<String>.from((survey['options'] as List).map((o) => o['label'].toString()));
                                      List<FocusNode> optionFocusNodes = List.generate(editOptions.length, (_) => FocusNode());
                                      bool allowMultiple = survey['allowMultiple'] == true;
                                      bool updated = false;
                                      await showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (context, setStateDialog) {
                                              return Dialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          translation('Edit Survey', context: context),
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        TextField(
                                                          controller: TextEditingController(text: editTitle),
                                                          decoration: InputDecoration(
                                                            labelText: translation('Survey Title', context: context),
                                                            border: const OutlineInputBorder(),
                                                          ),
                                                          onChanged: (val) => editTitle = val,
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Text(
                                                          translation('Options', context: context),
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        ...List.generate(editOptions.length, (i) => Row(
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(8.0),
                                                                child: TextField(
                                                                  focusNode: optionFocusNodes[i],
                                                                  controller: TextEditingController(text: editOptions[i]),
                                                                  decoration: InputDecoration(
                                                                    labelText: translation('Option', context: context) + ' ${i + 1}',
                                                                    border: const OutlineInputBorder(),
                                                                  ),
                                                                  onChanged: (val) => editOptions[i] = val,
                                                                ),
                                                              ),
                                                            ),
                                                            if (editOptions.length > 1)
                                                              IconButton(
                                                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                                onPressed: () {
                                                                  setStateDialog(() {
                                                                    optionFocusNodes[i].dispose();
                                                                    optionFocusNodes.removeAt(i);
                                                                    editOptions.removeAt(i);
                                                                  });
                                                                },
                                                              ),
                                                          ],
                                                        )),
                                                        Align(
                                                          alignment: Alignment.centerLeft,
                                                          child: TextButton.icon(
                                                            icon: const Icon(Icons.add),
                                                            label: Text(translation('Add Option', context: context)),
                                                            onPressed: () {
                                                              setStateDialog(() {
                                                                editOptions.add('');
                                                                optionFocusNodes.add(FocusNode());
                                                              });
                                                              Future.delayed(Duration(milliseconds: 100), () {
                                                                if (optionFocusNodes.isNotEmpty) {
                                                                  optionFocusNodes.last.requestFocus();
                                                                }
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              translation('Allow multiple answers', context: context),
                                                              style: const TextStyle(fontSize: 15),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Switch(
                                                              value: allowMultiple,
                                                              onChanged: (val) {
                                                                setStateDialog(() {
                                                                  allowMultiple = val;
                                                                });
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                          children: [
                                                            TextButton(
                                                              onPressed: () {
                                                                for (final node in optionFocusNodes) {
                                                                  node.dispose();
                                                                }
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text(translation('Cancel', context: context)),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                if (editTitle.trim().isEmpty || editOptions.any((o) => o.trim().isEmpty)) {
                                                                  showCustomSnackBar(context, translation('Please fill in all fields', context: context));
                                                                  return;
                                                                }
                                                                for (final node in optionFocusNodes) {
                                                                  node.dispose();
                                                                }
                                                                updated = true;
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text(translation('Save', context: context)),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                      if (updated) {
                                        await surveyService.updateSurvey(surveyId, {
                                          'title': editTitle.trim(),
                                          'options': [for (var o in editOptions) {'label': o.trim(), 'value': o.trim()}],
                                          'allowMultiple': allowMultiple,
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...options.map<Widget>((option) {
                                final allowMultiple = survey['allowMultiple'] == true;
                                final users = (option['users'] as List?)?.cast<String>() ?? [];
                                final isSelected = users.contains(userId);
                                final count = int.tryParse(option['voteCount']?.toString() ?? '0') ?? 0;
                                final totalVotes = options.fold<int>(0, (sum, o) => sum + (int.tryParse(o['voteCount']?.toString() ?? '0') ?? 0));
                                final percent = totalVotes > 0 ? count / totalVotes : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: LinearProgressIndicator(
                                            value: percent,
                                            backgroundColor: Colors.transparent,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Theme.of(context).colorScheme.primary.withOpacity(0.35),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        elevation: 0.5,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () async {
                                            // serialize actions per survey to avoid race when switching selections
                                            final actionKey = '$surveyId';
                                            if (_pendingActions.contains(actionKey)) return; // ignore rapid duplicate taps
                                            _pendingActions.add(actionKey);
                                            try {
                                              if (allowMultiple) {
                                                if (isSelected) {
                                                  await surveyService.decrementVote(surveyId, option['value'], userId: userId);
                                                } else {
                                                  await surveyService.incrementVote(surveyId, option['value'], userId: userId);
                                                }
                                              } else {
                                                // Single choice: deselect if already selected, otherwise select the tapped option.
                                                // Calling selectOption always will remove the user from any other option and add to the new one atomically.
                                                if (isSelected) {
                                                  await surveyService.decrementVote(surveyId, option['value'], userId: userId);
                                                } else {
                                                  await surveyService.selectOption(surveyId, option['value'], userId: userId);
                                                }
                                              }
                                            } finally {
                                              _pendingActions.remove(actionKey);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            child: Row(
                                              children: [
                                                allowMultiple
                                                    ? Icon(
                                                        isSelected
                                                            ? Icons.check_box
                                                            : Icons.check_box_outline_blank,
                                                        color: Theme.of(context).colorScheme.primary,
                                                        size: 22,
                                                      )
                                                    : Icon(
                                                        isSelected
                                                            ? Icons.radio_button_checked
                                                            : Icons.radio_button_unchecked,
                                                        color: Theme.of(context).colorScheme.primary,
                                                        size: 22,
                                                      ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    translation(option['label'], context: context),
                                                    style: const TextStyle(fontSize: 15),
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    count.toString(),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    translation('Votes for', context: context) + ': ' + translation(survey['title'], context: context),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  ...options.map<Widget>((option) {
                                                    final count = int.tryParse(option['voteCount']?.toString() ?? '0') ?? 0;
                                                    final users = (option['users'] as List?)?.cast<String>() ?? [];
                                                    return Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                translation(option['label'], context: context),
                                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                                              ),
                                                            ),
                                                            Container(
                                                              margin: const EdgeInsets.only(left: 8),
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Text(
                                                                count.toString(),
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Theme.of(context).colorScheme.primary,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (users.isNotEmpty)
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 12, top: 2, bottom: 8),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: users.map<Widget>((u) {
                                                                final userEntity = userMap[u];
                                                                final displayName = userEntity != null
                                                                  ? '${userEntity.firstName} ${userEntity.lastName}'.trim()
                                                                  : u;
                                                                return Text(displayName, style: const TextStyle(fontSize: 13, color: Colors.grey));
                                                              }).toList(),
                                                            ),
                                                          ),
                                                        const Divider(height: 16),
                                                      ],
                                                    );
                                                  }),
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      child: Text(translation('Close', context: context)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Text(translation('View votes', context: context)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  String newTitle = '';
                  List<String> newOptions = [''];
                  List<FocusNode> optionFocusNodes = [FocusNode()];
                  bool added = false;
                  bool allowMultiple = false;
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setStateDialog) {
                          return Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      translation('Add Survey', context: context),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: translation('Survey Title', context: context),
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => newTitle = val,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      translation('Options', context: context),
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.generate(newOptions.length, (i) => Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: TextField(
                                              focusNode: optionFocusNodes[i],
                                              decoration: InputDecoration(
                                                labelText: translation('Option', context: context) + ' ${i + 1}',
                                                border: const OutlineInputBorder(),
                                              ),
                                              onChanged: (val) => newOptions[i] = val,
                                            ),
                                          ),
                                        ),
                                        if (newOptions.length > 1)
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () {
                                              setStateDialog(() {
                                                optionFocusNodes[i].dispose();
                                                optionFocusNodes.removeAt(i);
                                                newOptions.removeAt(i);
                                              });
                                            },
                                          ),
                                      ],
                                    )),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: Text(translation('Add Option', context: context)),
                                        onPressed: () {
                                          setStateDialog(() {
                                            newOptions.add('');
                                            optionFocusNodes.add(FocusNode());
                                          });
                                          Future.delayed(Duration(milliseconds: 100), () {
                                            if (optionFocusNodes.isNotEmpty) {
                                              optionFocusNodes.last.requestFocus();
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text(
                                          translation('Allow multiple answers', context: context),
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch(
                                          value: allowMultiple,
                                          onChanged: (val) {
                                            setStateDialog(() {
                                              allowMultiple = val;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            for (final node in optionFocusNodes) {
                                              node.dispose();
                                            }
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(translation('Cancel', context: context)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (newTitle.trim().isEmpty || newOptions.any((o) => o.trim().isEmpty)) {
                                              showCustomSnackBar(context, translation('Please fill in all fields', context: context));
                                              return;
                                            }
                                            for (final node in optionFocusNodes) {
                                              node.dispose();
                                            }
                                            added = true;
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(translation('Add', context: context)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                  if (added) {
                    await surveyService.addSurvey({
                      'title': newTitle.trim(),
                      'options': [
                        for (var o in newOptions)
                          {'label': o.trim(), 'value': o.trim()},
                      ],
                      'allowMultiple': allowMultiple,
                    });
                  }
                },
                tooltip: translation('Add Survey', context: context),
                child: const Icon(Icons.add),
              ),
            );
          },
        );
      },
    );
  }
}