// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FeedbackReport _$FeedbackReportFromJson(Map<String, dynamic> json) {
  return _FeedbackReport.fromJson(json);
}

/// @nodoc
mixin _$FeedbackReport {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  FeedbackType get type => throw _privateConstructorUsedError;
  FeedbackStatus get status => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String get authorName => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  int get upvoteCount => throw _privateConstructorUsedError;
  List<String> get upvoterIds => throw _privateConstructorUsedError;
  int? get severity => throw _privateConstructorUsedError;
  bool get pinned => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get pinnedAt => throw _privateConstructorUsedError;
  String? get pinnedBy => throw _privateConstructorUsedError;

  /// Serializes this FeedbackReport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedbackReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedbackReportCopyWith<FeedbackReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedbackReportCopyWith<$Res> {
  factory $FeedbackReportCopyWith(
    FeedbackReport value,
    $Res Function(FeedbackReport) then,
  ) = _$FeedbackReportCopyWithImpl<$Res, FeedbackReport>;
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    FeedbackType type,
    FeedbackStatus status,
    String authorId,
    String authorName,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
    int upvoteCount,
    List<String> upvoterIds,
    int? severity,
    bool pinned,
    @NullableTimestampConverter() DateTime? pinnedAt,
    String? pinnedBy,
  });
}

/// @nodoc
class _$FeedbackReportCopyWithImpl<$Res, $Val extends FeedbackReport>
    implements $FeedbackReportCopyWith<$Res> {
  _$FeedbackReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedbackReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? status = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? upvoteCount = null,
    Object? upvoterIds = null,
    Object? severity = freezed,
    Object? pinned = null,
    Object? pinnedAt = freezed,
    Object? pinnedBy = freezed,
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
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as FeedbackType,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as FeedbackStatus,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            authorName: null == authorName
                ? _value.authorName
                : authorName // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            upvoteCount: null == upvoteCount
                ? _value.upvoteCount
                : upvoteCount // ignore: cast_nullable_to_non_nullable
                      as int,
            upvoterIds: null == upvoterIds
                ? _value.upvoterIds
                : upvoterIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            severity: freezed == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as int?,
            pinned: null == pinned
                ? _value.pinned
                : pinned // ignore: cast_nullable_to_non_nullable
                      as bool,
            pinnedAt: freezed == pinnedAt
                ? _value.pinnedAt
                : pinnedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pinnedBy: freezed == pinnedBy
                ? _value.pinnedBy
                : pinnedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FeedbackReportImplCopyWith<$Res>
    implements $FeedbackReportCopyWith<$Res> {
  factory _$$FeedbackReportImplCopyWith(
    _$FeedbackReportImpl value,
    $Res Function(_$FeedbackReportImpl) then,
  ) = __$$FeedbackReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    FeedbackType type,
    FeedbackStatus status,
    String authorId,
    String authorName,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
    int upvoteCount,
    List<String> upvoterIds,
    int? severity,
    bool pinned,
    @NullableTimestampConverter() DateTime? pinnedAt,
    String? pinnedBy,
  });
}

/// @nodoc
class __$$FeedbackReportImplCopyWithImpl<$Res>
    extends _$FeedbackReportCopyWithImpl<$Res, _$FeedbackReportImpl>
    implements _$$FeedbackReportImplCopyWith<$Res> {
  __$$FeedbackReportImplCopyWithImpl(
    _$FeedbackReportImpl _value,
    $Res Function(_$FeedbackReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeedbackReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? status = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? upvoteCount = null,
    Object? upvoterIds = null,
    Object? severity = freezed,
    Object? pinned = null,
    Object? pinnedAt = freezed,
    Object? pinnedBy = freezed,
  }) {
    return _then(
      _$FeedbackReportImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as FeedbackType,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as FeedbackStatus,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorName: null == authorName
            ? _value.authorName
            : authorName // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        upvoteCount: null == upvoteCount
            ? _value.upvoteCount
            : upvoteCount // ignore: cast_nullable_to_non_nullable
                  as int,
        upvoterIds: null == upvoterIds
            ? _value._upvoterIds
            : upvoterIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        severity: freezed == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as int?,
        pinned: null == pinned
            ? _value.pinned
            : pinned // ignore: cast_nullable_to_non_nullable
                  as bool,
        pinnedAt: freezed == pinnedAt
            ? _value.pinnedAt
            : pinnedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pinnedBy: freezed == pinnedBy
            ? _value.pinnedBy
            : pinnedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedbackReportImpl extends _FeedbackReport {
  const _$FeedbackReportImpl({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.authorId,
    required this.authorName,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() required this.updatedAt,
    required this.upvoteCount,
    required final List<String> upvoterIds,
    this.severity,
    this.pinned = false,
    @NullableTimestampConverter() this.pinnedAt,
    this.pinnedBy,
  }) : _upvoterIds = upvoterIds,
       super._();

  factory _$FeedbackReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedbackReportImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final FeedbackType type;
  @override
  final FeedbackStatus status;
  @override
  final String authorId;
  @override
  final String authorName;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;
  @override
  final int upvoteCount;
  final List<String> _upvoterIds;
  @override
  List<String> get upvoterIds {
    if (_upvoterIds is EqualUnmodifiableListView) return _upvoterIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_upvoterIds);
  }

  @override
  final int? severity;
  @override
  @JsonKey()
  final bool pinned;
  @override
  @NullableTimestampConverter()
  final DateTime? pinnedAt;
  @override
  final String? pinnedBy;

  @override
  String toString() {
    return 'FeedbackReport(id: $id, title: $title, description: $description, type: $type, status: $status, authorId: $authorId, authorName: $authorName, createdAt: $createdAt, updatedAt: $updatedAt, upvoteCount: $upvoteCount, upvoterIds: $upvoterIds, severity: $severity, pinned: $pinned, pinnedAt: $pinnedAt, pinnedBy: $pinnedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedbackReportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.upvoteCount, upvoteCount) ||
                other.upvoteCount == upvoteCount) &&
            const DeepCollectionEquality().equals(
              other._upvoterIds,
              _upvoterIds,
            ) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.pinned, pinned) || other.pinned == pinned) &&
            (identical(other.pinnedAt, pinnedAt) ||
                other.pinnedAt == pinnedAt) &&
            (identical(other.pinnedBy, pinnedBy) ||
                other.pinnedBy == pinnedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    type,
    status,
    authorId,
    authorName,
    createdAt,
    updatedAt,
    upvoteCount,
    const DeepCollectionEquality().hash(_upvoterIds),
    severity,
    pinned,
    pinnedAt,
    pinnedBy,
  );

  /// Create a copy of FeedbackReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedbackReportImplCopyWith<_$FeedbackReportImpl> get copyWith =>
      __$$FeedbackReportImplCopyWithImpl<_$FeedbackReportImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedbackReportImplToJson(this);
  }
}

abstract class _FeedbackReport extends FeedbackReport {
  const factory _FeedbackReport({
    required final String id,
    required final String title,
    required final String description,
    required final FeedbackType type,
    required final FeedbackStatus status,
    required final String authorId,
    required final String authorName,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() required final DateTime updatedAt,
    required final int upvoteCount,
    required final List<String> upvoterIds,
    final int? severity,
    final bool pinned,
    @NullableTimestampConverter() final DateTime? pinnedAt,
    final String? pinnedBy,
  }) = _$FeedbackReportImpl;
  const _FeedbackReport._() : super._();

  factory _FeedbackReport.fromJson(Map<String, dynamic> json) =
      _$FeedbackReportImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  FeedbackType get type;
  @override
  FeedbackStatus get status;
  @override
  String get authorId;
  @override
  String get authorName;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;
  @override
  int get upvoteCount;
  @override
  List<String> get upvoterIds;
  @override
  int? get severity;
  @override
  bool get pinned;
  @override
  @NullableTimestampConverter()
  DateTime? get pinnedAt;
  @override
  String? get pinnedBy;

  /// Create a copy of FeedbackReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedbackReportImplCopyWith<_$FeedbackReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
