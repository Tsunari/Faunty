import 'package:faunty/state_management/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/components/custom_app_bar.dart';
import 'package:faunty/tools/translation_helper.dart';
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          translation(survey['title'], context: context),
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                                        ),
                                        if ((survey['description'] ?? '').toString().trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              translation(survey['description'], context: context),
                                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: translation('Edit', context: context),
                                    onPressed: () async {
                                      String editTitle = survey['title'];
                                      String editDescription = (survey['description'] ?? '').toString();
                                      List<String> editOptions = List<String>.from((survey['options'] as List).map((o) => o['label'].toString()));
                                      List<FocusNode> optionFocusNodes = List.generate(editOptions.length, (_) => FocusNode());
                                      bool allowMultiple = survey['allowMultiple'] == true;
                                      bool updated = false;
                                      bool optionsEdited = false;
                                      bool allowMultipleEdited = false;
                                      // Use persistent controllers and ValueNotifiers instead of StatefulBuilder
                                      final titleController = TextEditingController(text: editTitle);
                                      final descriptionController = TextEditingController(text: editDescription);
                                      final descriptionLengthNotifier = ValueNotifier<int>(descriptionController.text.length);
                                      final optionsEditedNotifier = ValueNotifier<bool>(optionsEdited);
                                      final allowMultipleEditedNotifier = ValueNotifier<bool>(allowMultipleEdited);
                                      final allowMultipleNotifier = ValueNotifier<bool>(allowMultiple);
                                      final optionsNotifier = ValueNotifier<int>(editOptions.length);
                                      final optionControllers = List<TextEditingController>.generate(
                                        editOptions.length,
                                        (i) => TextEditingController(text: editOptions[i]),
                                      );
                                      final removedOptionControllers = <TextEditingController>[];
                                      final removedOptionFocusNodes = <FocusNode>[];
                                      // ensure description length updates
                                      descriptionController.addListener(() {
                                        descriptionLengthNotifier.value = descriptionController.text.length;
                                      });

                                      await showDialog(
                                        context: context,
                                        builder: (context) {
                                          // form key to validate fields inline
                                          final formKey = GlobalKey<FormState>();
                                          return Dialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: SingleChildScrollView(
                                                child: Form(
                                                  key: formKey,
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        translation('Edit Survey', context: context),
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      TextFormField(
                                                        controller: titleController,
                                                        decoration: InputDecoration(
                                                          labelText: translation('Survey Title', context: context),
                                                          border: const OutlineInputBorder(),
                                                        ),
                                                        validator: (val) => (val == null || val.trim().isEmpty) ? translation('Please fill in the title', context: context) : null,
                                                        onChanged: (val) => editTitle = val,
                                                      ),
                                                      const SizedBox(height: 12),
                                                      ValueListenableBuilder<int>(
                                                        valueListenable: descriptionLengthNotifier,
                                                        builder: (context, len, _) {
                                                          return TextFormField(
                                                            controller: descriptionController,
                                                            maxLength: 250,
                                                            inputFormatters: [LengthLimitingTextInputFormatter(250)],
                                                            decoration: InputDecoration(
                                                              labelText: translation('Description (optional)', context: context) + ' (' + len.toString() + '/250)',
                                                              border: const OutlineInputBorder(),
                                                              counterText: '',
                                                            ),
                                                            onChanged: (val) => editDescription = val,
                                                          );
                                                        },
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        translation('Options', context: context),
                                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      ValueListenableBuilder<int>(
                                                        valueListenable: optionsNotifier,
                                                        builder: (context, _, __) {
                                                          return Column(
                                                            children: List.generate(optionControllers.length, (i) {
                                                              return Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.all(8.0),
                                                                      child: TextFormField(
                                                                        focusNode: optionFocusNodes[i],
                                                                        controller: optionControllers[i],
                                                                        decoration: InputDecoration(
                                                                          labelText: translation('Option', context: context) + ' ${i + 1}',
                                                                          border: const OutlineInputBorder(),
                                                                        ),
                                                                        validator: (val) {
                                                                          if (optionsEditedNotifier.value && (val == null || val.trim().isEmpty)) {
                                                                            return translation('Please fill in all fields', context: context);
                                                                          }
                                                                          return null;
                                                                        },
                                                                        onChanged: (val) {
                                                                          editOptions[i] = val;
                                                                          optionsEditedNotifier.value = true;
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                    if (optionControllers.length > 1)
                                                                    IconButton(
                                                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                                      onPressed: () {
                                                                        // remove controller and focus node but defer disposal until after rebuild
                                                                        final removedFocus = optionFocusNodes.removeAt(i);
                                                                        final removedController = optionControllers.removeAt(i);
                                                                        removedOptionFocusNodes.add(removedFocus);
                                                                        removedOptionControllers.add(removedController);
                                                                        editOptions.removeAt(i);
                                                                        optionsEditedNotifier.value = true;
                                                                        optionsNotifier.value = optionsNotifier.value + 1; // trigger rebuild
                                                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                                                          for (final n in removedOptionFocusNodes) {
                                                                            try { n.dispose(); } catch (_) {}
                                                                          }
                                                                          for (final c in removedOptionControllers) {
                                                                            try { c.dispose(); } catch (_) {}
                                                                          }
                                                                          removedOptionFocusNodes.clear();
                                                                          removedOptionControllers.clear();
                                                                        });
                                                                      },
                                                                    ),
                                                                ],
                                                              );
                                                            }),
                                                          );
                                                        },
                                                      ),
                                                      Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: TextButton.icon(
                                                          icon: const Icon(Icons.add),
                                                          label: Text(translation('Add Option', context: context)),
                                                          onPressed: () {
                                                            optionControllers.add(TextEditingController(text: ''));
                                                            optionFocusNodes.add(FocusNode());
                                                            editOptions.add('');
                                                            optionsEditedNotifier.value = true;
                                                            optionsNotifier.value = optionsNotifier.value + 1; // trigger rebuild
                                                            Future.delayed(const Duration(milliseconds: 100), () {
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
                                                          ValueListenableBuilder<bool>(
                                                            valueListenable: allowMultipleNotifier,
                                                              builder: (context, currentAllow, __) {
                                                                return Switch(
                                                                  value: currentAllow,
                                                                  onChanged: (val) {
                                                                    allowMultiple = val;
                                                                    allowMultipleNotifier.value = val;
                                                                    allowMultipleEditedNotifier.value = true;
                                                                  },
                                                                );
                                                              },
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      ValueListenableBuilder<bool>(
                                                        valueListenable: optionsEditedNotifier,
                                                        builder: (context, optEdited, _) {
                                                          return ValueListenableBuilder<bool>(
                                                            valueListenable: allowMultipleEditedNotifier,
                                                            builder: (context, allowEdited, __) {
                                                              if (optEdited || allowEdited) {
                                                                return Padding(
                                                                  padding: const EdgeInsets.only(bottom: 8.0),
                                                                  child: Text(
                                                                    translation('Warning: Changing options or answer mode will reset votes if saved.', context: context),
                                                                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                                                                  ),
                                                                );
                                                              }
                                                              return const SizedBox.shrink();
                                                            },
                                                          );
                                                        },
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
                                                              for (final c in optionControllers) {
                                                                c.dispose();
                                                              }
                                                              titleController.dispose();
                                                              descriptionController.dispose();
                                                              descriptionLengthNotifier.dispose();
                                                              optionsEditedNotifier.dispose();
                                                              allowMultipleEditedNotifier.dispose();
                                                              allowMultipleNotifier.dispose();
                                                              optionsNotifier.dispose();
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Text(translation('Cancel', context: context)),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              // Validate form fields inline
                                                              if (!formKey.currentState!.validate()) {
                                                                return;
                                                              }
                                                              // Rebuild current option texts for capture
                                                              final currentOptions = optionControllers.map((c) => c.text).toList();

                                                              // Capture final values before disposing controllers/notifiers
                                                              final finalTitle = titleController.text;
                                                              final finalDescription = descriptionController.text;
                                                              final finalOptions = currentOptions;
                                                              final finalOptionsEdited = optionsEditedNotifier.value;
                                                              final finalAllowMultipleEdited = allowMultipleEditedNotifier.value;

                                                              for (final node in optionFocusNodes) {
                                                                node.dispose();
                                                              }
                                                              for (final c in optionControllers) {
                                                                c.dispose();
                                                              }
                                                              titleController.dispose();
                                                              descriptionController.dispose();
                                                              descriptionLengthNotifier.dispose();
                                                              optionsEditedNotifier.dispose();
                                                              allowMultipleEditedNotifier.dispose();
                                                              allowMultipleNotifier.dispose();
                                                              optionsNotifier.dispose();

                                                              // write back captured values to outer-scope vars
                                                              editTitle = finalTitle;
                                                              editDescription = finalDescription;
                                                              editOptions = finalOptions;
                                                              optionsEdited = finalOptionsEdited;
                                                              allowMultipleEdited = finalAllowMultipleEdited;

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
                                            ),
                                          );
                                        },
                                      );
                                      if (updated) {
                                        // sync notifier values back to local booleans
                                        optionsEdited = optionsEditedNotifier.value;
                                        allowMultipleEdited = allowMultipleEditedNotifier.value;
                                        // rebuild editOptions from controllers to capture final texts
                                        try {
                                          editOptions = optionControllers.map((c) => c.text).toList();
                                        } catch (_) {}

                                        final Map<String, dynamic> payload = {};
                                        // Always update title and description
                                        payload['title'] = editTitle.trim();
                                        payload['description'] = editDescription.trim();
                                        if (optionsEdited || allowMultipleEdited) {
                                          // Replacing options or changing allowMultiple will reset votes
                                          payload['options'] = [for (var o in editOptions) {'label': o.trim(), 'value': o.trim()}];
                                          payload['allowMultiple'] = allowMultiple;
                                        }
                                        await surveyService.updateSurvey(surveyId, payload);
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
                  String newDescription = '';
                  List<String> newOptions = [''];
                  List<FocusNode> optionFocusNodes = [FocusNode()];
                  bool added = false;
                  bool allowMultiple = false;
                  bool optionsEdited = false;
                  bool allowMultipleEdited = false;
                  // Use controllers and notifiers to avoid setState in the Add dialog
                  final titleController = TextEditingController(text: newTitle);
                  final descriptionController = TextEditingController(text: newDescription);
                  final descriptionLengthNotifier = ValueNotifier<int>(descriptionController.text.length);
                  final optionControllers = List<TextEditingController>.generate(
                    newOptions.length,
                    (i) => TextEditingController(text: newOptions[i]),
                  );
                  final removedOptionControllers = <TextEditingController>[];
                  final removedOptionFocusNodes = <FocusNode>[];
                  final optionsEditedNotifier = ValueNotifier<bool>(optionsEdited);
                  final allowMultipleEditedNotifier = ValueNotifier<bool>(allowMultipleEdited);
                  final allowMultipleNotifier = ValueNotifier<bool>(allowMultiple);
                  final optionsNotifier = ValueNotifier<int>(optionControllers.length);

                  descriptionController.addListener(() {
                    descriptionLengthNotifier.value = descriptionController.text.length;
                  });

                  await showDialog(
                    context: context,
                    builder: (context) {
                      final formKey = GlobalKey<FormState>();
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translation('Add Survey', context: context),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: titleController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      labelText: translation('Survey Title', context: context),
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? translation('Please fill in the title', context: context) : null,
                                  ),
                                  const SizedBox(height: 12),
                                  ValueListenableBuilder<int>(
                                    valueListenable: descriptionLengthNotifier,
                                    builder: (context, len, _) {
                                      return TextFormField(
                                        controller: descriptionController,
                                        maxLength: 250,
                                        inputFormatters: [LengthLimitingTextInputFormatter(250)],
                                        decoration: InputDecoration(
                                          labelText: translation('Description (optional)', context: context) + ' (' + len.toString() + '/250)',
                                          border: const OutlineInputBorder(),
                                          counterText: '',
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    translation('Options', context: context),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  ValueListenableBuilder<int>(
                                    valueListenable: optionsNotifier,
                                    builder: (context, _, __) {
                                      return Column(
                                        children: List.generate(optionControllers.length, (i) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: TextFormField(
                                                    focusNode: optionFocusNodes[i],
                                                    controller: optionControllers[i],
                                                    decoration: InputDecoration(
                                                      labelText: translation('Option', context: context) + ' ${i + 1}',
                                                      border: const OutlineInputBorder(),
                                                    ),
                                                    validator: (val) {
                                                      if (val == null || val.trim().isEmpty) {
                                                        return translation('Please fill in all fields', context: context);
                                                      }
                                                      return null;
                                                    },
                                                    onChanged: (val) {
                                                      newOptions[i] = val;
                                                      optionsEditedNotifier.value = true;
                                                    },
                                                  ),
                                                ),
                                              ),
                                              if (optionControllers.length > 1)
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                  onPressed: () {
                                                    final removedFocus = optionFocusNodes.removeAt(i);
                                                    final removedController = optionControllers.removeAt(i);
                                                    removedOptionFocusNodes.add(removedFocus);
                                                    removedOptionControllers.add(removedController);
                                                    newOptions.removeAt(i);
                                                    optionsEditedNotifier.value = true;
                                                    optionsNotifier.value = optionsNotifier.value + 1; // trigger rebuild
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      for (final n in removedOptionFocusNodes) {
                                                        try { n.dispose(); } catch (_) {}
                                                      }
                                                      for (final c in removedOptionControllers) {
                                                        try { c.dispose(); } catch (_) {}
                                                      }
                                                      removedOptionFocusNodes.clear();
                                                      removedOptionControllers.clear();
                                                    });
                                                  },
                                                ),
                                            ],
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: Text(translation('Add Option', context: context)),
                                      onPressed: () {
                                        optionControllers.add(TextEditingController(text: ''));
                                        optionFocusNodes.add(FocusNode());
                                        newOptions.add('');
                                        optionsEditedNotifier.value = true;
                                        optionsNotifier.value = optionsNotifier.value + 1; // trigger rebuild
                                        Future.delayed(const Duration(milliseconds: 100), () {
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
                                      ValueListenableBuilder<bool>(
                                        valueListenable: allowMultipleNotifier,
                                        builder: (context, currentAllow, __) {
                                          return Switch(
                                            value: currentAllow,
                                            onChanged: (val) {
                                              allowMultiple = val;
                                              allowMultipleNotifier.value = val;
                                              allowMultipleEditedNotifier.value = true;
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // New survey — no need to warn about resetting votes because there are no existing votes yet.
                                  const SizedBox.shrink(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          for (final node in optionFocusNodes) {
                                            node.dispose();
                                          }
                                          for (final c in optionControllers) {
                                            c.dispose();
                                          }
                                          titleController.dispose();
                                          descriptionController.dispose();
                                          descriptionLengthNotifier.dispose();
                                          optionsEditedNotifier.dispose();
                                          allowMultipleEditedNotifier.dispose();
                                          allowMultipleNotifier.dispose();
                                          optionsNotifier.dispose();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(translation('Cancel', context: context)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Validate form fields inline
                                          if (!formKey.currentState!.validate()) {
                                            return;
                                          }
                                          final currentOptions = optionControllers.map((c) => c.text).toList();

                                          // Capture final values
                                          final finalTitle = titleController.text;
                                          final finalDescription = descriptionController.text;
                                          final finalOptions = currentOptions;
                                          final finalOptionsEdited = optionsEditedNotifier.value;
                                          final finalAllowMultipleEdited = allowMultipleEditedNotifier.value;

                                          for (final node in optionFocusNodes) {
                                            node.dispose();
                                          }
                                          for (final c in optionControllers) {
                                            c.dispose();
                                          }
                                          titleController.dispose();
                                          descriptionController.dispose();
                                          descriptionLengthNotifier.dispose();
                                          optionsEditedNotifier.dispose();
                                          allowMultipleEditedNotifier.dispose();
                                          allowMultipleNotifier.dispose();
                                          optionsNotifier.dispose();

                                          newTitle = finalTitle;
                                          newDescription = finalDescription;
                                          newOptions = finalOptions;
                                          optionsEdited = finalOptionsEdited;
                                          allowMultipleEdited = finalAllowMultipleEdited;

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
                        ),
                      );
                    },
                  );
                  if (added) {
                    await surveyService.addSurvey({
                      'title': newTitle.trim(),
                      'description': newDescription.trim(),
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