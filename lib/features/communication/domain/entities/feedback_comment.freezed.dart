// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FeedbackComment _$FeedbackCommentFromJson(Map<String, dynamic> json) {
  return _FeedbackComment.fromJson(json);
}

/// @nodoc
mixin _$FeedbackComment {
  String get id => throw _privateConstructorUsedError;
  String get reportId => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String get authorName => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FeedbackComment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedbackComment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedbackCommentCopyWith<FeedbackComment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedbackCommentCopyWith<$Res> {
  factory $FeedbackCommentCopyWith(
    FeedbackComment value,
    $Res Function(FeedbackComment) then,
  ) = _$FeedbackCommentCopyWithImpl<$Res, FeedbackComment>;
  @useResult
  $Res call({
    String id,
    String reportId,
    String authorId,
    String authorName,
    String text,
    @TimestampConverter() DateTime createdAt,
  });
}

/// @nodoc
class _$FeedbackCommentCopyWithImpl<$Res, $Val extends FeedbackComment>
    implements $FeedbackCommentCopyWith<$Res> {
  _$FeedbackCommentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedbackComment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportId = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? text = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            reportId: null == reportId
                ? _value.reportId
                : reportId // ignore: cast_nullable_to_non_nullable
                      as String,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            authorName: null == authorName
                ? _value.authorName
                : authorName // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FeedbackCommentImplCopyWith<$Res>
    implements $FeedbackCommentCopyWith<$Res> {
  factory _$$FeedbackCommentImplCopyWith(
    _$FeedbackCommentImpl value,
    $Res Function(_$FeedbackCommentImpl) then,
  ) = __$$FeedbackCommentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String reportId,
    String authorId,
    String authorName,
    String text,
    @TimestampConverter() DateTime createdAt,
  });
}

/// @nodoc
class __$$FeedbackCommentImplCopyWithImpl<$Res>
    extends _$FeedbackCommentCopyWithImpl<$Res, _$FeedbackCommentImpl>
    implements _$$FeedbackCommentImplCopyWith<$Res> {
  __$$FeedbackCommentImplCopyWithImpl(
    _$FeedbackCommentImpl _value,
    $Res Function(_$FeedbackCommentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeedbackComment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportId = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? text = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$FeedbackCommentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        reportId: null == reportId
            ? _value.reportId
            : reportId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorName: null == authorName
            ? _value.authorName
            : authorName // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedbackCommentImpl extends _FeedbackComment {
  const _$FeedbackCommentImpl({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.authorName,
    required this.text,
    @TimestampConverter() required this.createdAt,
  }) : super._();

  factory _$FeedbackCommentImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedbackCommentImplFromJson(json);

  @override
  final String id;
  @override
  final String reportId;
  @override
  final String authorId;
  @override
  final String authorName;
  @override
  final String text;
  @override
  @TimestampConverter()
  final DateTime createdAt;

  @override
  String toString() {
    return 'FeedbackComment(id: $id, reportId: $reportId, authorId: $authorId, authorName: $authorName, text: $text, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedbackCommentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reportId, reportId) ||
                other.reportId == reportId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reportId,
    authorId,
    authorName,
    text,
    createdAt,
  );

  /// Create a copy of FeedbackComment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedbackCommentImplCopyWith<_$FeedbackCommentImpl> get copyWith =>
      __$$FeedbackCommentImplCopyWithImpl<_$FeedbackCommentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedbackCommentImplToJson(this);
  }
}

abstract class _FeedbackComment extends FeedbackComment {
  const factory _FeedbackComment({
    required final String id,
    required final String reportId,
    required final String authorId,
    required final String authorName,
    required final String text,
    @TimestampConverter() required final DateTime createdAt,
  }) = _$FeedbackCommentImpl;
  const _FeedbackComment._() : super._();

  factory _FeedbackComment.fromJson(Map<String, dynamic> json) =
      _$FeedbackCommentImpl.fromJson;

  @override
  String get id;
  @override
  String get reportId;
  @override
  String get authorId;
  @override
  String get authorName;
  @override
  String get text;
  @override
  @TimestampConverter()
  DateTime get createdAt;

  /// Create a copy of FeedbackComment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedbackCommentImplCopyWith<_$FeedbackCommentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
