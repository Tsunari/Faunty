import 'package:faunty/firestore/feedback_firestore_service.dart';
import 'package:faunty/models/feedback_comment.dart';
import 'package:faunty/models/feedback_report.dart';
import 'package:faunty/state_management/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedbackViewMode { active, archived }

final feedbackViewModeProvider = StateProvider<FeedbackViewMode>((ref) => FeedbackViewMode.active);
final feedbackSearchProvider = StateProvider<String>((ref) => '');
final feedbackTypeFilterProvider = StateProvider<FeedbackType?>((ref) => null);
final feedbackStatusFilterProvider = StateProvider<FeedbackStatus?>((ref) => null);

FeedbackFirestoreService _serviceFor(Ref ref) {
  return FeedbackFirestoreService();
}

final feedbackReportsProvider = StreamProvider<List<FeedbackReport>>((ref) {
  final service = _serviceFor(ref);
  return service.streamReports();
});

final filteredFeedbackReportsProvider = Provider<List<FeedbackReport>>((ref) {
  final reportsAsync = ref.watch(feedbackReportsProvider);
  final search = ref.watch(feedbackSearchProvider).toLowerCase();
  final typeFilter = ref.watch(feedbackTypeFilterProvider);
  final statusFilter = ref.watch(feedbackStatusFilterProvider);
  final viewMode = ref.watch(feedbackViewModeProvider);
  return reportsAsync.maybeWhen(
    data: (reports) {
      final list = reports.where((r) {
        final matchesSearch = search.isEmpty || r.title.toLowerCase().contains(search) || r.description.toLowerCase().contains(search);
        final matchesType = typeFilter == null || r.type == typeFilter;
        final matchesStatus = statusFilter == null || r.status == statusFilter;
        final isArchived = r.status == FeedbackStatus.closed || r.status == FeedbackStatus.resolved;
        final inView = viewMode == FeedbackViewMode.archived ? isArchived : !isArchived;
        return matchesSearch && matchesType && matchesStatus && inView;
      }).toList();
      return list;
    },
    orElse: () => []);
});

final feedbackCommentsProvider = StreamProvider.family<List<FeedbackComment>, String>((ref, reportId) {
  final service = _serviceFor(ref);
  return service.streamComments(reportId);
});

class FeedbackActions {
  FeedbackActions(this.ref);
  final Ref ref;

  Future<void> toggleUpvote(FeedbackReport report) async {
    final user = ref.read(userProvider).asData?.value;
    if (user == null) return;
  await _serviceFor(ref).toggleUpvote(report.id, user.uid);
  }

  Future<void> addReport({
    required String title,
    required String description,
    required FeedbackType type,
    int? severity,
  }) async {
    final user = ref.read(userProvider).asData?.value;
    if (user == null) return;
    final authorName = '${user.firstName} ${user.lastName}'.trim();
    await _serviceFor(ref).addReport(
      title: title,
      description: description,
      type: type,
      authorId: user.uid,
      authorName: authorName,
      severity: severity,
    );
  }

  Future<void> addComment(String reportId, String text) async {
    final user = ref.read(userProvider).asData?.value;
    if (user == null) return;
    final authorName = '${user.firstName} ${user.lastName}'.trim();
    await _serviceFor(ref).addComment(
      reportId: reportId,
      authorId: user.uid,
      authorName: authorName,
      text: text,
    );
  }

  Future<void> updateStatus(String reportId, FeedbackStatus status) async {
  await _serviceFor(ref).updateStatus(reportId, status);
  }

  Future<void> updateType(String reportId, FeedbackType type) async {
    await _serviceFor(ref).updateType(reportId, type);
  }

  Future<void> editReport(String reportId, {String? title, String? description, FeedbackType? type, int? severity}) async {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (type != null) map['type'] = type.name;
    if (severity != null) map['severity'] = severity;
    if (map.isEmpty) return;
    await _serviceFor(ref).updateReportFields(reportId, map);
  }

  Future<void> deleteReport(String reportId) async {
    await _serviceFor(ref).deleteReport(reportId);
  }

  Future<void> editComment(String reportId, String commentId, String newText) async {
    await _serviceFor(ref).updateComment(reportId, commentId, newText);
  }

  Future<void> deleteComment(String reportId, String commentId) async {
    await _serviceFor(ref).deleteComment(reportId, commentId);
  }

  Future<void> setPinned(FeedbackReport report, bool pinned) async {
    final user = ref.read(userProvider).asData?.value;
    if (user == null) return;
    await _serviceFor(ref).setPinned(report.id, pinned: pinned, byUserId: user.uid);
  }
}

final feedbackActionsProvider = Provider<FeedbackActions>((ref) => FeedbackActions(ref));
