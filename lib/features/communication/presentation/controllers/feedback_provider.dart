import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/communication/data/repositories/communication_repository.dart';
import 'package:faunty/features/communication/domain/entities/feedback_comment.dart';
import 'package:faunty/features/communication/domain/entities/feedback_report.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/notifications/data/notification_manager.dart';
import 'package:faunty/features/notifications/data/types/feedback_notifications.dart';

part 'feedback_provider.g.dart';

enum FeedbackViewMode { active, archived }

@riverpod
class FeedbackViewModeState extends _$FeedbackViewModeState {
  @override
  FeedbackViewMode build() => FeedbackViewMode.active;
  set state(FeedbackViewMode val) => super.state = val;
}

@riverpod
class FeedbackSearchState extends _$FeedbackSearchState {
  @override
  String build() => '';
  set state(String val) => super.state = val;
}

@riverpod
class FeedbackTypeFilterState extends _$FeedbackTypeFilterState {
  @override
  FeedbackType? build() => null;
  set state(FeedbackType? val) => super.state = val;
}

@riverpod
class FeedbackStatusFilterState extends _$FeedbackStatusFilterState {
  @override
  FeedbackStatus? build() => null;
  set state(FeedbackStatus? val) => super.state = val;
}

@riverpod
Stream<List<FeedbackReport>> feedbackReports(FeedbackReportsRef ref) {
  return ref.watch(communicationRepositoryProvider).streamReports();
}

@riverpod
List<FeedbackReport> filteredFeedbackReports(FilteredFeedbackReportsRef ref) {
  final reportsAsync = ref.watch(feedbackReportsProvider);
  final search = ref.watch(feedbackSearchStateProvider).toLowerCase();
  final typeFilter = ref.watch(feedbackTypeFilterStateProvider);
  final statusFilter = ref.watch(feedbackStatusFilterStateProvider);
  final viewMode = ref.watch(feedbackViewModeStateProvider);

  return reportsAsync.maybeWhen(
      data: (reports) {
        return reports.where((r) {
          final matchesSearch = search.isEmpty ||
              r.title.toLowerCase().contains(search) ||
              r.description.toLowerCase().contains(search);
          final matchesType = typeFilter == null || r.type == typeFilter;
          final matchesStatus = statusFilter == null || r.status == statusFilter;
          final isArchived =
              r.status == FeedbackStatus.closed || r.status == FeedbackStatus.resolved;
          final inView = viewMode == FeedbackViewMode.archived ? isArchived : !isArchived;
          return matchesSearch && matchesType && matchesStatus && inView;
        }).toList();
      },
      orElse: () => []);
}

@riverpod
Stream<List<FeedbackComment>> feedbackComments(FeedbackCommentsRef ref, String reportId) {
  return ref.watch(communicationRepositoryProvider).streamComments(reportId);
}

class FeedbackActions {
  FeedbackActions(this.ref);
  final Ref ref;

  Future<void> toggleUpvote(FeedbackReport report) async {
    final user = ref.read(userProvider).asData?.value;
    if (user == null) return;
    await ref.read(communicationRepositoryProvider).toggleUpvote(report.id, user.uid);
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
    await ref.read(communicationRepositoryProvider).addReport(
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
    await ref.read(communicationRepositoryProvider).addComment(
          reportId: reportId,
          authorId: user.uid,
          authorName: authorName,
          text: text,
        );

    // Notification Logic
    try {
      final reports = ref.read(feedbackReportsProvider).asData?.value ?? [];
      final report = reports.firstWhere((r) => r.id == reportId,
          orElse: () => throw Exception('Report not found'));

      final comments = ref.read(feedbackCommentsProvider(reportId)).asData?.value ?? [];
      final participantIds = comments.map((c) => c.authorId).toSet();

      final recipients = <String>{};
      if (report.authorId != user.uid) {
        recipients.add(report.authorId);
      }

      for (final pid in participantIds) {
        if (pid != user.uid) {
          recipients.add(pid);
        }
      }

      if (recipients.isNotEmpty) {
        final notification = FeedbackCommentNotification(
          reportTitle: report.title,
          commenterName: authorName,
          commentText: text,
          reportId: reportId,
        );
        await NotificationManager().send(notification, toUserIds: recipients.toList());
      }
    } catch (e) {
      print('Error sending comment notification: $e');
    }
  }

  Future<void> updateStatus(String reportId, FeedbackStatus status) async {
    await ref.read(communicationRepositoryProvider).updateStatus(reportId, status);

    // Notification Logic
    try {
      final user = ref.read(userProvider).asData?.value;
      if (user == null) return;

      final reports = ref.read(feedbackReportsProvider).asData?.value ?? [];
      final report = reports.firstWhere((r) => r.id == reportId,
          orElse: () => throw Exception('Report not found'));

      if (report.authorId != user.uid) {
        final notification = FeedbackStatusNotification(
          reportTitle: report.title,
          newStatus: status,
          reportId: reportId,
        );
        await NotificationManager().send(notification, toUserIds: [report.authorId]);
      }
    } catch (e) {
      print('Error sending status notification: $e');
    }
  }

  Future<void> updateType(String reportId, FeedbackType type) async {
    await ref.read(communicationRepositoryProvider).updateType(reportId, type);
  }

  Future<void> editReport(String reportId,
      {String? title, String? description, FeedbackType? type, int? severity}) async {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (type != null) map['type'] = type.name;
    if (severity != null) map['severity'] = severity;
    if (map.isEmpty) return;
    await ref.read(communicationRepositoryProvider).updateReportFields(reportId, map);
  }

  Future<void> deleteReport(String reportId) async {
    await ref.read(communicationRepositoryProvider).deleteReport(reportId);
  }

  Future<void> editComment(String reportId, String commentId, String newText) async {
    await ref.read(communicationRepositoryProvider).updateComment(reportId, commentId, newText);
  }

  Future<void> deleteComment(String reportId, String commentId) async {
    await ref.read(communicationRepositoryProvider).deleteComment(reportId, commentId);
  }

  Future<void> setPinned(FeedbackReport report, bool pinned) async {
    final user = ref.read(userProvider).asData?.value;
    if (user == null) return;
    await ref.read(communicationRepositoryProvider).setPinned(report.id, pinned: pinned, byUserId: user.uid);
  }
}

@riverpod
FeedbackActions feedbackActions(FeedbackActionsRef ref) {
  return FeedbackActions(ref);
}

// Legacy aliases for backward compatibility
final feedbackViewModeProvider = feedbackViewModeStateProvider;
final feedbackSearchProvider = feedbackSearchStateProvider;
final feedbackTypeFilterProvider = feedbackTypeFilterStateProvider;
final feedbackStatusFilterProvider = feedbackStatusFilterStateProvider;