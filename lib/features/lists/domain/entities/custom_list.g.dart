// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IconSpecImpl _$$IconSpecImplFromJson(Map<String, dynamic> json) =>
    _$IconSpecImpl(
      kind: json['kind'] as String,
      codePoint: (json['codePoint'] as num?)?.toInt(),
      fontFamily: json['fontFamily'] as String?,
      assetPath: json['assetPath'] as String?,
    );

Map<String, dynamic> _$$IconSpecImplToJson(_$IconSpecImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'codePoint': instance.codePoint,
      'fontFamily': instance.fontFamily,
      'assetPath': instance.assetPath,
    };

_$CustomListImpl _$$CustomListImplFromJson(Map<String, dynamic> json) =>
    _$CustomListImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      type: $enumDecode(_$CustomListTypeEnumMap, json['type']),
      createdBy: json['createdBy'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      order: (json['order'] as num).toInt(),
      visible: json['visible'] as bool,
      icon: json['icon'] == null
          ? null
          : IconSpec.fromJson(json['icon'] as Map<String, dynamic>),
      meta: json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$$CustomListImplToJson(_$CustomListImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': _$CustomListTypeEnumMap[instance.type]!,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'order': instance.order,
      'visible': instance.visible,
      'icon': instance.icon,
      'meta': instance.meta,
    };

const _$CustomListTypeEnumMap = {
  CustomListType.assignment: 'assignment',
  CustomListType.attendance: 'attendance',
  CustomListType.schedule: 'schedule',
};

_$ListItemImpl _$$ListItemImplFromJson(Map<String, dynamic> json) =>
    _$ListItemImpl(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      payload: json['payload'] as Map<String, dynamic>,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$ListItemImplToJson(
  _$ListItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'order': instance.order,
  'payload': instance.payload,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
