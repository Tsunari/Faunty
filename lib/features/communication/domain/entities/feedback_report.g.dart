// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedbackReportImpl _$$FeedbackReportImplFromJson(Map<String, dynamic> json) =>
    _$FeedbackReportImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$FeedbackTypeEnumMap, json['type']),
      status: $enumDecode(_$FeedbackStatusEnumMap, json['status']),
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      upvoteCount: (json['upvoteCount'] as num).toInt(),
      upvoterIds: (json['upvoterIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      severity: (json['severity'] as num?)?.toInt(),
      pinned: json['pinned'] as bool? ?? false,
      pinnedAt: const NullableTimestampConverter().fromJson(json['pinnedAt']),
      pinnedBy: json['pinnedBy'] as String?,
    );

Map<String, dynamic> _$$FeedbackReportImplToJson(
  _$FeedbackReportImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'type': _$FeedbackTypeEnumMap[instance.type]!,
  'status': _$FeedbackStatusEnumMap[instance.status]!,
  'authorId': instance.authorId,
  'authorName': instance.authorName,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
  'upvoteCount': instance.upvoteCount,
  'upvoterIds': instance.upvoterIds,
  'severity': instance.severity,
  'pinned': instance.pinned,
  'pinnedAt': const NullableTimestampConverter().toJson(instance.pinnedAt),
  'pinnedBy': instance.pinnedBy,
};

const _$FeedbackTypeEnumMap = {
  FeedbackType.bug: 'bug',
  FeedbackType.feature: 'feature',
  FeedbackType.enhancement: 'enhancement',
  FeedbackType.ui: 'ui',
  FeedbackType.performance: 'performance',
  FeedbackType.other: 'other',
};

const _$FeedbackStatusEnumMap = {
  FeedbackStatus.open: 'open',
  FeedbackStatus.inProgress: 'inProgress',
  FeedbackStatus.resolved: 'resolved',
  FeedbackStatus.closed: 'closed',
};
