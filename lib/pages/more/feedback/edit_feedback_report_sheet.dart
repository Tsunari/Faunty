import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/models/feedback_report.dart';
import 'package:faunty/state_management/feedback_provider.dart';
import 'package:faunty/tools/translation_helper.dart';

class EditFeedbackReportSheet extends ConsumerStatefulWidget {
  const EditFeedbackReportSheet({super.key, required this.report});
  final FeedbackReport report;
  @override
  ConsumerState<EditFeedbackReportSheet> createState() => _EditFeedbackReportSheetState();
}

class _EditFeedbackReportSheetState extends ConsumerState<EditFeedbackReportSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  FeedbackType? _type;
  int? _severity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.report.title);
    _descCtrl = TextEditingController(text: widget.report.description);
    _type = widget.report.type;
    _severity = widget.report.severity;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.read(feedbackActionsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(translation(context: context, 'Edit Feedback'), style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(labelText: translation(context: context, 'Title'), border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? translation(context: context, 'Required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(labelText: translation(context: context, 'Description'), border: const OutlineInputBorder(), alignLabelWithHint: true),
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
                      )
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
                    icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                    label: Text(translation(context: context, 'Save')),
                    onPressed: _saving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _saving = true);
                            await actions.editReport(
                              widget.report.id,
                              title: _titleCtrl.text.trim(),
                              description: _descCtrl.text.trim(),
                              type: _type,
                              severity: _type == FeedbackType.bug ? _severity : null,
                            );
                            if (mounted) Navigator.pop(context);
                          },
                  ),
                ),
                const SizedBox(height: 12)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
