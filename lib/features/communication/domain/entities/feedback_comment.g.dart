// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedbackCommentImpl _$$FeedbackCommentImplFromJson(
  Map<String, dynamic> json,
) => _$FeedbackCommentImpl(
  id: json['id'] as String,
  reportId: json['reportId'] as String,
  authorId: json['authorId'] as String,
  authorName: json['authorName'] as String,
  text: json['text'] as String,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$$FeedbackCommentImplToJson(
  _$FeedbackCommentImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'reportId': instance.reportId,
  'authorId': instance.authorId,
  'authorName': instance.authorName,
  'text': instance.text,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};
