import 'package:faunty/models/feedback_report.dart';
import 'package:faunty/state_management/feedback_provider.dart';
import 'package:faunty/state_management/user_provider.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../components/custom_chip.dart';
import 'new_feedback_report_sheet.dart';
import 'feedback_detail_sheet.dart';

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final filteredReports = ref.watch(filteredFeedbackReportsProvider);
  final viewMode = ref.watch(feedbackViewModeProvider);
    final user = ref.watch(userProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context: context, 'Feedback')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<FeedbackViewMode>(
              style: ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(
                  value: FeedbackViewMode.active,
                  label: Text(translation(context: context, 'Active')),
                  icon: const Icon(Icons.inbox_outlined, size: 16),
                ),
                ButtonSegment(
                  value: FeedbackViewMode.archived,
                  label: Text(translation(context: context, 'Archived')),
                  icon: const Icon(Icons.archive_outlined, size: 16),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (s) => ref.read(feedbackViewModeProvider.notifier).state = s.first,
            ),
          ),
          IconButton(
            tooltip: translation(context: context, 'Filters'),
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: translation(context: context, 'Search feedback'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => ref.read(feedbackSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: ref.watch(feedbackReportsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(e.toString())),
              data: (_) {
                if (filteredReports.isEmpty) {
                  return Center(
                    child: Text(translation(context: context, 'No feedback yet')),
                  );
                }
                return ListView.builder(
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _FeedbackCard(report: report, isOwn: user?.uid == report.authorId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const NewFeedbackReportSheet(),
        ),
        icon: const Icon(Icons.add),
        label: Text(translation(context: context, 'New')),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Consumer(
          builder: (context, sheetRef, __) {
            final type = sheetRef.watch(feedbackTypeFilterProvider);
            final status = sheetRef.watch(feedbackStatusFilterProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(translation(context: context, 'Type'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final t in FeedbackType.values)
                          ChoiceChip(
                            label: Text(t.label),
                            selected: type == t,
                            onSelected: (_) => sheetRef.read(feedbackTypeFilterProvider.notifier).state = type == t ? null : t,
                          ),
                        ChoiceChip(
                          label: Text(translation(context: context, 'Any')),
                          selected: type == null,
                          onSelected: (_) => sheetRef.read(feedbackTypeFilterProvider.notifier).state = null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(translation(context: context, 'Status'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in FeedbackStatus.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: status == s,
                            onSelected: (_) => sheetRef.read(feedbackStatusFilterProvider.notifier).state = status == s ? null : s,
                          ),
                        ChoiceChip(
                          label: Text(translation(context: context, 'Any')),
                          selected: status == null,
                          onSelected: (_) => sheetRef.read(feedbackStatusFilterProvider.notifier).state = null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(translation(context: context, 'Close')),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FeedbackCard extends ConsumerWidget {
  const _FeedbackCard({required this.report, required this.isOwn});
  final FeedbackReport report;
  final bool isOwn;

  String _fmtDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d.$m.$y, $h:$min';
  }

  Color _typeColor(BuildContext context) {
    switch (report.type) {
      case FeedbackType.bug:
        return Colors.redAccent;
      case FeedbackType.feature:
        return Colors.indigo;
      case FeedbackType.enhancement:
        return Colors.teal;
      case FeedbackType.ui:
        return Colors.purple;
      case FeedbackType.performance:
        return Colors.orange;
      case FeedbackType.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(feedbackActionsProvider);
    final user = ref.watch(userProvider).asData?.value;
    final upvoted = report.upvoterIds.contains(user?.uid ?? '');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showModalBottomSheet(
          context: context,
            isScrollControlled: true,
          builder: (_) => FeedbackDetailSheet(report: report),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _typeColor(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(report.type.label, style: TextStyle(color: _typeColor(context), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  CustomContainerChip(label: report.status.label),
                  if (report.severity != null) ...[
                    const SizedBox(width: 8),
                    CustomContainerChip(label: 'S${report.severity}')
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: user == null ? null : () => actions.toggleUpvote(report),
                    icon: Icon(upvoted ? Icons.favorite : Icons.favorite_border, color: upvoted ? Colors.pink : null),
                  ),
                  Text(report.upvoteCount.toString()),
                ],
              ),
              const SizedBox(height: 8),
              Text(report.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                report.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${report.authorName} • ${_fmtDate(report.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
