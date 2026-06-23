// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      uid: json['uid'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      placeId: json['placeId'] as String? ?? '',
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'role': _$UserRoleEnumMap[instance.role]!,
      'placeId': instance.placeId,
      'isPlaceholder': instance.isPlaceholder,
    };

const _$UserRoleEnumMap = {
  UserRole.superuser: 'Superuser',
  UserRole.hoca: 'Hoca',
  UserRole.baskan: 'Baskan',
  UserRole.talebe: 'Talebe',
  UserRole.user: 'User',
  UserRole.spectator: 'Spectator',
  UserRole.archived: 'Archived',
  UserRole.unknown: 'Unknown',
};
