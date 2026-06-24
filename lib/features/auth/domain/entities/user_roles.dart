import 'package:freezed_annotation/freezed_annotation.dart';

enum UserRole {
  @JsonValue('Superuser')
  superuser('Superuser'),
  @JsonValue('Hoca')
  hoca('Hoca'),
  @JsonValue('Baskan')
  baskan('Baskan'),
  @JsonValue('Talebe')
  talebe('Talebe'),
  @JsonValue('User')
  user('User'),
  @JsonValue('Spectator')
  spectator('Spectator'),
  @JsonValue('Archived')
  archived('Archived'),
  @JsonValue('Unknown')
  unknown('Unknown');

  final String serializedValue;
  const UserRole(this.serializedValue);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.serializedValue.toLowerCase() == value.toLowerCase() || e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }
}

UserRole userRoleFromString(String role) => UserRole.fromString(role);

