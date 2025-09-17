import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/models/feedback_report.dart';
import 'package:faunty/state_management/feedback_provider.dart';
import 'package:faunty/state_management/user_provider.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'edit_feedback_report_sheet.dart';

class FeedbackDetailSheet extends ConsumerStatefulWidget {
  const FeedbackDetailSheet({super.key, required this.report});
  final FeedbackReport report;

  @override
  ConsumerState<FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends ConsumerState<FeedbackDetailSheet> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always derive latest report instance from provider to reflect status/type changes.
    final reports = ref.watch(feedbackReportsProvider).maybeWhen(data: (r) => r, orElse: () => <FeedbackReport>[]);
    final report = reports.firstWhere(
      (r) => r.id == widget.report.id,
      orElse: () => widget.report,
    );
    final commentsAsync = ref.watch(feedbackCommentsProvider(report.id));
    final actions = ref.read(feedbackActionsProvider);
    final user = ref.watch(userProvider).asData?.value;
    final canModerate = user != null && (user.role == UserRole.superuser || user.role == UserRole.hoca);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(report.title, style: Theme.of(context).textTheme.titleLarge),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => EditFeedbackReportSheet(report: report),
                      );
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(translation(context: context, 'Delete Feedback')),
                          content: Text(translation(context: context, 'Are you sure? This will remove all comments.')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(translation(context: context, 'Cancel'))),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(translation(context: context, 'Delete'))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await actions.deleteReport(report.id);
                        if (mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (ctx) {
                    final canEdit = user != null && (user.uid == report.authorId || user.role == UserRole.superuser);
                    if (!canEdit) return [];
                    return [
                      PopupMenuItem(value: 'edit', child: Text(translation(context: context, 'Edit'))),
                      PopupMenuItem(value: 'delete', child: Text(translation(context: context, 'Delete'))),
                    ];
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Pill(label: report.type.label),
                _Pill(label: report.status.label),
                if (report.severity != null) _Pill(label: 'S${report.severity}')
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  Text(report.description),
                  const SizedBox(height: 16),
                  if (canModerate) _ModerationPanel(report: report),
                  const Divider(),
                  Text(translation(context: context, 'Comments'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  commentsAsync.when(
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(e.toString()),
                    ),
                    data: (comments) => Column(
                      children: [
                        for (final c in comments)
                          _CommentTile(reportId: report.id, commentId: c.id, authorName: c.authorName, createdAt: c.createdAt, text: c.text, canEdit: user != null && (user.uid == c.authorId || user.role == UserRole.superuser))
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: translation(context: context, 'Add a comment'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = _commentCtrl.text.trim();
                      if (text.isEmpty) return;
                      await actions.addComment(report.id, text);
                      _commentCtrl.clear();
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({
    required this.reportId,
    required this.commentId,
    required this.authorName,
    required this.createdAt,
    required this.text,
    required this.canEdit,
  });
  final String reportId;
  final String commentId;
  final String authorName;
  final DateTime createdAt;
  final String text;
  final bool canEdit;

  String _fmtDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(feedbackActionsProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(authorName),
      subtitle: Text(text),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_fmtDate(createdAt), style: Theme.of(context).textTheme.bodySmall),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  final ctrl = TextEditingController(text: text);
                  final newText = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(translation(context: context, 'Edit Comment')),
                      content: TextField(
                        controller: ctrl,
                        maxLines: 5,
                        decoration: InputDecoration(hintText: translation(context: context, 'Comment')),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(translation(context: context, 'Cancel'))),
                        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(translation(context: context, 'Save'))),
                      ],
                    ),
                  );
                  if (newText != null && newText.isNotEmpty && newText != text) {
                    await actions.editComment(reportId, commentId, newText);
                  }
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(translation(context: context, 'Delete Comment')),
                      content: Text(translation(context: context, 'Are you sure?')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(translation(context: context, 'Cancel'))),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(translation(context: context, 'Delete'))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await actions.deleteComment(reportId, commentId);
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Text(translation(context: context, 'Edit'))),
                PopupMenuItem(value: 'delete', child: Text(translation(context: context, 'Delete'))),
              ],
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
    );
  }
}

class _ModerationPanel extends ConsumerWidget {
  const _ModerationPanel({required this.report});
  final FeedbackReport report;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(feedbackActionsProvider);
    // Get latest version of report to reflect state changes
    final reports = ref.watch(feedbackReportsProvider).maybeWhen(data: (r) => r, orElse: () => <FeedbackReport>[]);
    final current = reports.firstWhere(
      (r) => r.id == report.id,
      orElse: () => report,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(translation(context: context, 'Moderation'), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            DropdownButton<FeedbackStatus>(
              value: current.status,
              onChanged: (val) {
                if (val != null) actions.updateStatus(report.id, val);
              },
              items: [
                for (final s in FeedbackStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
            ),
            DropdownButton<FeedbackType>(
              value: current.type,
              onChanged: (val) {
                if (val != null) actions.updateType(report.id, val);
              },
              items: [
                for (final t in FeedbackType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
            ),
          ],
        )
      ],
    );
  }
}
