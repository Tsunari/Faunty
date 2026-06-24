import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/core/utils/timestamp_converter.dart';

part 'custom_list.freezed.dart';
part 'custom_list.g.dart';

enum CustomListType {
  @JsonValue('assignment') assignment,
  @JsonValue('attendance') attendance,
  @JsonValue('schedule') schedule
}

@freezed
class IconSpec with _$IconSpec {
  const IconSpec._();

  const factory IconSpec({
    required String kind, // 'material' or 'asset'
    int? codePoint,
    String? fontFamily,
    String? assetPath,
  }) = _IconSpec;

  factory IconSpec.fromJson(Map<String, dynamic> json) => _$IconSpecFromJson(json);

  factory IconSpec.material(int? codePoint, {String? fontFamily}) {
    return IconSpec(kind: 'material', codePoint: codePoint, fontFamily: fontFamily);
  }

  factory IconSpec.asset(String? assetPath) {
    return IconSpec(kind: 'asset', assetPath: assetPath);
  }

  Map<String, dynamic> toMap() => toJson();

  static IconSpec? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return IconSpec.fromJson(map);
  }
}

@freezed
class CustomList with _$CustomList {
  const CustomList._();

  const factory CustomList({
    required String id,
    required String title,
    required CustomListType type,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
    required int order,
    required bool visible,
    @IconSpecConverter() IconSpec? icon,
    @Default(<String, dynamic>{}) Map<String, dynamic> meta,
  }) = _CustomList;

  factory CustomList.fromJson(Map<String, dynamic> json) => _$CustomListFromJson(json);

  factory CustomList.fromMap(String id, Map<String, dynamic> map) {
    return CustomList.fromJson(Map<String, dynamic>.from(map)..['id'] = id);
  }

  Map<String, dynamic> toMap() => toJson()..remove('id');
}

@freezed
class ListItem with _$ListItem {
  const ListItem._();

  const factory ListItem({
    required String id,
    required int order,
    required Map<String, dynamic> payload,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _ListItem;

  factory ListItem.fromJson(Map<String, dynamic> json) => _$ListItemFromJson(json);

  factory ListItem.fromMap(String id, Map<String, dynamic> map) {
    return ListItem.fromJson(Map<String, dynamic>.from(map)..['id'] = id);
  }

  Map<String, dynamic> toMap() => toJson()..remove('id');
}

class IconSpecConverter implements JsonConverter<IconSpec?, Map<String, dynamic>?> {
  const IconSpecConverter();

  @override
  IconSpec? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return IconSpec.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(IconSpec? icon) => icon?.toJson();
}

