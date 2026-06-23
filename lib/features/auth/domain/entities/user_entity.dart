import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
class UserEntity with _$UserEntity {
  const UserEntity._();

  const factory UserEntity({
    required String uid,
    required String email,
    @Default('') String firstName,
    @Default('') String lastName,
    required UserRole role,
    @Default('') String placeId,
    @Default(false) bool isPlaceholder,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);

  factory UserEntity.fromMap(Map<String, dynamic> map) => UserEntity.fromJson(map);
  
  Map<String, dynamic> toMap() => toJson();
}