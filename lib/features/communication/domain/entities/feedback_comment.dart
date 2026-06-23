import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/core/utils/timestamp_converter.dart';

part 'feedback_comment.freezed.dart';
part 'feedback_comment.g.dart';

@freezed
class FeedbackComment with _$FeedbackComment {
  const FeedbackComment._();

  const factory FeedbackComment({
    required String id,
    required String reportId,
    required String authorId,
    required String authorName,
    required String text,
    @TimestampConverter() required DateTime createdAt,
  }) = _FeedbackComment;

  factory FeedbackComment.fromJson(Map<String, dynamic> json) => _$FeedbackCommentFromJson(json);

  factory FeedbackComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeedbackComment.fromJson(Map<String, dynamic>.from(data)..['id'] = doc.id);
  }

  Map<String, dynamic> toMap() => toJson()..remove('id');
}

