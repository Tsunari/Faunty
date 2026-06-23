// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

IconSpec _$IconSpecFromJson(Map<String, dynamic> json) {
  return _IconSpec.fromJson(json);
}

/// @nodoc
mixin _$IconSpec {
  String get kind =>
      throw _privateConstructorUsedError; // 'material' or 'asset'
  int? get codePoint => throw _privateConstructorUsedError;
  String? get fontFamily => throw _privateConstructorUsedError;
  String? get assetPath => throw _privateConstructorUsedError;

  /// Serializes this IconSpec to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IconSpec
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IconSpecCopyWith<IconSpec> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IconSpecCopyWith<$Res> {
  factory $IconSpecCopyWith(IconSpec value, $Res Function(IconSpec) then) =
      _$IconSpecCopyWithImpl<$Res, IconSpec>;
  @useResult
  $Res call({
    String kind,
    int? codePoint,
    String? fontFamily,
    String? assetPath,
  });
}

/// @nodoc
class _$IconSpecCopyWithImpl<$Res, $Val extends IconSpec>
    implements $IconSpecCopyWith<$Res> {
  _$IconSpecCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IconSpec
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? codePoint = freezed,
    Object? fontFamily = freezed,
    Object? assetPath = freezed,
  }) {
    return _then(
      _value.copyWith(
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            codePoint: freezed == codePoint
                ? _value.codePoint
                : codePoint // ignore: cast_nullable_to_non_nullable
                      as int?,
            fontFamily: freezed == fontFamily
                ? _value.fontFamily
                : fontFamily // ignore: cast_nullable_to_non_nullable
                      as String?,
            assetPath: freezed == assetPath
                ? _value.assetPath
                : assetPath // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IconSpecImplCopyWith<$Res>
    implements $IconSpecCopyWith<$Res> {
  factory _$$IconSpecImplCopyWith(
    _$IconSpecImpl value,
    $Res Function(_$IconSpecImpl) then,
  ) = __$$IconSpecImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String kind,
    int? codePoint,
    String? fontFamily,
    String? assetPath,
  });
}

/// @nodoc
class __$$IconSpecImplCopyWithImpl<$Res>
    extends _$IconSpecCopyWithImpl<$Res, _$IconSpecImpl>
    implements _$$IconSpecImplCopyWith<$Res> {
  __$$IconSpecImplCopyWithImpl(
    _$IconSpecImpl _value,
    $Res Function(_$IconSpecImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IconSpec
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? codePoint = freezed,
    Object? fontFamily = freezed,
    Object? assetPath = freezed,
  }) {
    return _then(
      _$IconSpecImpl(
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        codePoint: freezed == codePoint
            ? _value.codePoint
            : codePoint // ignore: cast_nullable_to_non_nullable
                  as int?,
        fontFamily: freezed == fontFamily
            ? _value.fontFamily
            : fontFamily // ignore: cast_nullable_to_non_nullable
                  as String?,
        assetPath: freezed == assetPath
            ? _value.assetPath
            : assetPath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IconSpecImpl extends _IconSpec {
  const _$IconSpecImpl({
    required this.kind,
    this.codePoint,
    this.fontFamily,
    this.assetPath,
  }) : super._();

  factory _$IconSpecImpl.fromJson(Map<String, dynamic> json) =>
      _$$IconSpecImplFromJson(json);

  @override
  final String kind;
  // 'material' or 'asset'
  @override
  final int? codePoint;
  @override
  final String? fontFamily;
  @override
  final String? assetPath;

  @override
  String toString() {
    return 'IconSpec(kind: $kind, codePoint: $codePoint, fontFamily: $fontFamily, assetPath: $assetPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IconSpecImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.codePoint, codePoint) ||
                other.codePoint == codePoint) &&
            (identical(other.fontFamily, fontFamily) ||
                other.fontFamily == fontFamily) &&
            (identical(other.assetPath, assetPath) ||
                other.assetPath == assetPath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, kind, codePoint, fontFamily, assetPath);

  /// Create a copy of IconSpec
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IconSpecImplCopyWith<_$IconSpecImpl> get copyWith =>
      __$$IconSpecImplCopyWithImpl<_$IconSpecImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IconSpecImplToJson(this);
  }
}

abstract class _IconSpec extends IconSpec {
  const factory _IconSpec({
    required final String kind,
    final int? codePoint,
    final String? fontFamily,
    final String? assetPath,
  }) = _$IconSpecImpl;
  const _IconSpec._() : super._();

  factory _IconSpec.fromJson(Map<String, dynamic> json) =
      _$IconSpecImpl.fromJson;

  @override
  String get kind; // 'material' or 'asset'
  @override
  int? get codePoint;
  @override
  String? get fontFamily;
  @override
  String? get assetPath;

  /// Create a copy of IconSpec
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IconSpecImplCopyWith<_$IconSpecImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomList _$CustomListFromJson(Map<String, dynamic> json) {
  return _CustomList.fromJson(json);
}

/// @nodoc
mixin _$CustomList {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  CustomListType get type => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  @IconSpecConverter()
  IconSpec? get icon => throw _privateConstructorUsedError;
  Map<String, dynamic> get meta => throw _privateConstructorUsedError;

  /// Serializes this CustomList to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomListCopyWith<CustomList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomListCopyWith<$Res> {
  factory $CustomListCopyWith(
    CustomList value,
    $Res Function(CustomList) then,
  ) = _$CustomListCopyWithImpl<$Res, CustomList>;
  @useResult
  $Res call({
    String id,
    String title,
    CustomListType type,
    String createdBy,
    @TimestampConverter() DateTime createdAt,
    int order,
    bool visible,
    @IconSpecConverter() IconSpec? icon,
    Map<String, dynamic> meta,
  });

  $IconSpecCopyWith<$Res>? get icon;
}

/// @nodoc
class _$CustomListCopyWithImpl<$Res, $Val extends CustomList>
    implements $CustomListCopyWith<$Res> {
  _$CustomListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? order = null,
    Object? visible = null,
    Object? icon = freezed,
    Object? meta = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as CustomListType,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
            visible: null == visible
                ? _value.visible
                : visible // ignore: cast_nullable_to_non_nullable
                      as bool,
            icon: freezed == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as IconSpec?,
            meta: null == meta
                ? _value.meta
                : meta // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }

  /// Create a copy of CustomList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IconSpecCopyWith<$Res>? get icon {
    if (_value.icon == null) {
      return null;
    }

    return $IconSpecCopyWith<$Res>(_value.icon!, (value) {
      return _then(_value.copyWith(icon: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CustomListImplCopyWith<$Res>
    implements $CustomListCopyWith<$Res> {
  factory _$$CustomListImplCopyWith(
    _$CustomListImpl value,
    $Res Function(_$CustomListImpl) then,
  ) = __$$CustomListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    CustomListType type,
    String createdBy,
    @TimestampConverter() DateTime createdAt,
    int order,
    bool visible,
    @IconSpecConverter() IconSpec? icon,
    Map<String, dynamic> meta,
  });

  @override
  $IconSpecCopyWith<$Res>? get icon;
}

/// @nodoc
class __$$CustomListImplCopyWithImpl<$Res>
    extends _$CustomListCopyWithImpl<$Res, _$CustomListImpl>
    implements _$$CustomListImplCopyWith<$Res> {
  __$$CustomListImplCopyWithImpl(
    _$CustomListImpl _value,
    $Res Function(_$CustomListImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? order = null,
    Object? visible = null,
    Object? icon = freezed,
    Object? meta = null,
  }) {
    return _then(
      _$CustomListImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as CustomListType,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
        visible: null == visible
            ? _value.visible
            : visible // ignore: cast_nullable_to_non_nullable
                  as bool,
        icon: freezed == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as IconSpec?,
        meta: null == meta
            ? _value._meta
            : meta // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomListImpl extends _CustomList {
  const _$CustomListImpl({
    required this.id,
    required this.title,
    required this.type,
    required this.createdBy,
    @TimestampConverter() required this.createdAt,
    required this.order,
    required this.visible,
    @IconSpecConverter() this.icon,
    final Map<String, dynamic> meta = const <String, dynamic>{},
  }) : _meta = meta,
       super._();

  factory _$CustomListImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomListImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final CustomListType type;
  @override
  final String createdBy;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  final int order;
  @override
  final bool visible;
  @override
  @IconSpecConverter()
  final IconSpec? icon;
  final Map<String, dynamic> _meta;
  @override
  @JsonKey()
  Map<String, dynamic> get meta {
    if (_meta is EqualUnmodifiableMapView) return _meta;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_meta);
  }

  @override
  String toString() {
    return 'CustomList(id: $id, title: $title, type: $type, createdBy: $createdBy, createdAt: $createdAt, order: $order, visible: $visible, icon: $icon, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomListImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality().equals(other._meta, _meta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    type,
    createdBy,
    createdAt,
    order,
    visible,
    icon,
    const DeepCollectionEquality().hash(_meta),
  );

  /// Create a copy of CustomList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomListImplCopyWith<_$CustomListImpl> get copyWith =>
      __$$CustomListImplCopyWithImpl<_$CustomListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomListImplToJson(this);
  }
}

abstract class _CustomList extends CustomList {
  const factory _CustomList({
    required final String id,
    required final String title,
    required final CustomListType type,
    required final String createdBy,
    @TimestampConverter() required final DateTime createdAt,
    required final int order,
    required final bool visible,
    @IconSpecConverter() final IconSpec? icon,
    final Map<String, dynamic> meta,
  }) = _$CustomListImpl;
  const _CustomList._() : super._();

  factory _CustomList.fromJson(Map<String, dynamic> json) =
      _$CustomListImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  CustomListType get type;
  @override
  String get createdBy;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  int get order;
  @override
  bool get visible;
  @override
  @IconSpecConverter()
  IconSpec? get icon;
  @override
  Map<String, dynamic> get meta;

  /// Create a copy of CustomList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomListImplCopyWith<_$CustomListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ListItem _$ListItemFromJson(Map<String, dynamic> json) {
  return _ListItem.fromJson(json);
}

/// @nodoc
mixin _$ListItem {
  String get id => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ListItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ListItemCopyWith<ListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ListItemCopyWith<$Res> {
  factory $ListItemCopyWith(ListItem value, $Res Function(ListItem) then) =
      _$ListItemCopyWithImpl<$Res, ListItem>;
  @useResult
  $Res call({
    String id,
    int order,
    Map<String, dynamic> payload,
    @TimestampConverter() DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  });
}

/// @nodoc
class _$ListItemCopyWithImpl<$Res, $Val extends ListItem>
    implements $ListItemCopyWith<$Res> {
  _$ListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? order = null,
    Object? payload = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ListItemImplCopyWith<$Res>
    implements $ListItemCopyWith<$Res> {
  factory _$$ListItemImplCopyWith(
    _$ListItemImpl value,
    $Res Function(_$ListItemImpl) then,
  ) = __$$ListItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    int order,
    Map<String, dynamic> payload,
    @TimestampConverter() DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  });
}

/// @nodoc
class __$$ListItemImplCopyWithImpl<$Res>
    extends _$ListItemCopyWithImpl<$Res, _$ListItemImpl>
    implements _$$ListItemImplCopyWith<$Res> {
  __$$ListItemImplCopyWithImpl(
    _$ListItemImpl _value,
    $Res Function(_$ListItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? order = null,
    Object? payload = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ListItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ListItemImpl extends _ListItem {
  const _$ListItemImpl({
    required this.id,
    required this.order,
    required final Map<String, dynamic> payload,
    @TimestampConverter() required this.createdAt,
    @NullableTimestampConverter() this.updatedAt,
  }) : _payload = payload,
       super._();

  factory _$ListItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ListItemImplFromJson(json);

  @override
  final String id;
  @override
  final int order;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @NullableTimestampConverter()
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ListItem(id: $id, order: $order, payload: $payload, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    order,
    const DeepCollectionEquality().hash(_payload),
    createdAt,
    updatedAt,
  );

  /// Create a copy of ListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ListItemImplCopyWith<_$ListItemImpl> get copyWith =>
      __$$ListItemImplCopyWithImpl<_$ListItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ListItemImplToJson(this);
  }
}

abstract class _ListItem extends ListItem {
  const factory _ListItem({
    required final String id,
    required final int order,
    required final Map<String, dynamic> payload,
    @TimestampConverter() required final DateTime createdAt,
    @NullableTimestampConverter() final DateTime? updatedAt,
  }) = _$ListItemImpl;
  const _ListItem._() : super._();

  factory _ListItem.fromJson(Map<String, dynamic> json) =
      _$ListItemImpl.fromJson;

  @override
  String get id;
  @override
  int get order;
  @override
  Map<String, dynamic> get payload;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @NullableTimestampConverter()
  DateTime? get updatedAt;

  /// Create a copy of ListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ListItemImplCopyWith<_$ListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
