import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/communication/domain/entities/feedback_report.dart';
import 'package:faunty/features/communication/presentation/controllers/feedback_provider.dart';
import 'package:faunty/core/utils/translation_helper.dart';

class NewFeedbackReportSheet extends ConsumerStatefulWidget {
  const NewFeedbackReportSheet({super.key});

  @override
  ConsumerState<NewFeedbackReportSheet> createState() => _NewFeedbackReportSheetState();
}

class _NewFeedbackReportSheetState extends ConsumerState<NewFeedbackReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  FeedbackType _type = FeedbackType.bug;
  int? _severity; // only for bugs
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.read(feedbackActionsProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(translation(context: context, 'New Feedback'), style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: translation(context: context, 'Title'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? translation(context: context, 'Required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: translation(context: context, 'Description'),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? translation(context: context, 'Required') : null,
                ),
                const SizedBox(height: 12),
                Text(translation(context: context, 'Type')), 
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in FeedbackType.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ),
                  ],
                ),
                if (_type == FeedbackType.bug) ...[
                  const SizedBox(height: 12),
                  Text(translation(context: context, 'Severity (1-5)')),
                  Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: (_severity ?? 3).toDouble(),
                    label: (_severity ?? 3).toString(),
                    onChanged: (v) => setState(() => _severity = v.toInt()),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                    label: Text(translation(context: context, 'Submit')),
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _submitting = true);
                            await actions.addReport(
                              title: _titleCtrl.text.trim(),
                              description: _descCtrl.text.trim(),
                              type: _type,
                              severity: _type == FeedbackType.bug ? _severity ?? 3 : null,
                            );
                            if (mounted) Navigator.pop(context);
                          },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}