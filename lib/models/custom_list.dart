import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomListType { assignment, attendance, schedule }

class IconSpec {
  final String kind; // 'material' or 'asset'
  final int? codePoint; // for material
  final String? fontFamily;
  final String? assetPath;

  IconSpec.material(this.codePoint, {this.fontFamily}) : kind = 'material', assetPath = null;
  IconSpec.asset(this.assetPath) : kind = 'asset', codePoint = null, fontFamily = null;

  Map<String, dynamic> toMap() => {
        'kind': kind,
        if (codePoint != null) 'codePoint': codePoint,
        if (fontFamily != null) 'fontFamily': fontFamily,
        if (assetPath != null) 'assetPath': assetPath,
      };

  static IconSpec? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final kind = map['kind'] as String?;
    if (kind == 'material') return IconSpec.material(map['codePoint'] as int?, fontFamily: map['fontFamily'] as String?);
    if (kind == 'asset') return IconSpec.asset(map['assetPath'] as String?);
    return null;
  }
}

class CustomList {
  final String id;
  final String title;
  final CustomListType type;
  final String createdBy;
  final Timestamp createdAt;
  final int order;
  final bool visible;
  final IconSpec? icon;
  final Map<String, dynamic> meta;

  CustomList({
    required this.id,
    required this.title,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.order,
    required this.visible,
    this.icon,
    this.meta = const {},
  });

  factory CustomList.fromMap(String id, Map<String, dynamic> map) {
    return CustomList(
      id: id,
      title: map['title'] as String? ?? '',
      type: _typeFromString(map['type'] as String? ?? 'assignment'),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      order: map['order'] as int? ?? 0,
      visible: map['visible'] as bool? ?? true,
      icon: IconSpec.fromMap(map['icon'] as Map<String, dynamic>?),
      meta: (map['meta'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': _typeToString(type),
        'createdBy': createdBy,
        'createdAt': createdAt,
        'order': order,
        'visible': visible,
        if (icon != null) 'icon': icon!.toMap(),
        'meta': meta,
      };

  static CustomListType _typeFromString(String s) {
    switch (s) {
      case 'attendance':
        return CustomListType.attendance;
      case 'schedule':
        return CustomListType.schedule;
      default:
        return CustomListType.assignment;
    }
  }

  static String _typeToString(CustomListType t) {
    switch (t) {
      case CustomListType.attendance:
        return 'attendance';
      case CustomListType.schedule:
        return 'schedule';
      default:
        return 'assignment';
    }
  }
}

class ListItem {
  final String id;
  final int order;
  final Map<String, dynamic> payload;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ListItem({required this.id, required this.order, required this.payload, required this.createdAt, this.updatedAt});

  factory ListItem.fromMap(String id, Map<String, dynamic> map) {
    return ListItem(
      id: id,
      order: map['order'] as int? ?? 0,
      payload: (map['payload'] as Map<String, dynamic>?) ?? {},
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'order': order,
        'payload': payload,
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
