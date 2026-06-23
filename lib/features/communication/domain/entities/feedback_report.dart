import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/core/utils/timestamp_converter.dart';

part 'feedback_report.freezed.dart';
part 'feedback_report.g.dart';

enum FeedbackType {
  @JsonValue('bug') bug,
  @JsonValue('feature') feature,
  @JsonValue('enhancement') enhancement,
  @JsonValue('ui') ui,
  @JsonValue('performance') performance,
  @JsonValue('other') other
}

extension FeedbackTypeX on FeedbackType {
  String get label {
    switch (this) {
      case FeedbackType.bug:
        return 'Bug';
      case FeedbackType.feature:
        return 'Feature';
      case FeedbackType.enhancement:
        return 'Enhancement';
      case FeedbackType.ui:
        return 'UI';
      case FeedbackType.performance:
        return 'Performance';
      case FeedbackType.other:
        return 'Other';
    }
  }
}

enum FeedbackStatus {
  @JsonValue('open') open,
  @JsonValue('inProgress') inProgress,
  @JsonValue('resolved') resolved,
  @JsonValue('closed') closed
}

extension FeedbackStatusX on FeedbackStatus {
  String get label {
    switch (this) {
      case FeedbackStatus.open:
        return 'Open';
      case FeedbackStatus.inProgress:
        return 'In Progress';
      case FeedbackStatus.resolved:
        return 'Resolved';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }
  bool get isArchived => this == FeedbackStatus.closed || this == FeedbackStatus.resolved;
}

@freezed
class FeedbackReport with _$FeedbackReport {
  const FeedbackReport._();

  const factory FeedbackReport({
    required String id,
    required String title,
    required String description,
    required FeedbackType type,
    required FeedbackStatus status,
    required String authorId,
    required String authorName,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    required int upvoteCount,
    required List<String> upvoterIds,
    int? severity,
    @Default(false) bool pinned,
    @NullableTimestampConverter() DateTime? pinnedAt,
    String? pinnedBy,
  }) = _FeedbackReport;

  factory FeedbackReport.fromJson(Map<String, dynamic> json) => _$FeedbackReportFromJson(json);

  factory FeedbackReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeedbackReport.fromJson(Map<String, dynamic>.from(data)..['id'] = doc.id);
  }

  Map<String, dynamic> toMap() => toJson()..remove('id');
}

