import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackComment {
  final String id;
  final String reportId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  FeedbackComment({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FeedbackComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeedbackComment(
      id: doc.id,
      reportId: data['reportId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
