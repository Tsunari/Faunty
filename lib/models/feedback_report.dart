import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { bug, feature, enhancement, ui, performance, other }

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

enum FeedbackStatus { open, inProgress, resolved, closed }

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

class FeedbackReport {
  final String id;
  final String title;
  final String description;
  final FeedbackType type;
  final FeedbackStatus status;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int upvoteCount;
  final List<String> upvoterIds;
  final int? severity; // optional: 1-5 for bugs

  FeedbackReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    required this.upvoteCount,
    required this.upvoterIds,
    this.severity,
  });

  FeedbackReport copyWith({
    String? id,
    String? title,
    String? description,
    FeedbackType? type,
    FeedbackStatus? status,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? upvoteCount,
    List<String>? upvoterIds,
    int? severity,
  }) {
    return FeedbackReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      upvoterIds: upvoterIds ?? this.upvoterIds,
      severity: severity ?? this.severity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'upvoteCount': upvoteCount,
      'upvoterIds': upvoterIds,
      'severity': severity,
    };
  }

  factory FeedbackReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeedbackReport(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FeedbackType.other,
      ),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FeedbackStatus.open,
      ),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      upvoteCount: data['upvoteCount'] ?? 0,
      upvoterIds: List<String>.from(data['upvoterIds'] ?? []),
      severity: data['severity'],
    );
  }
}
