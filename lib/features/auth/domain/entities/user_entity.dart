// import '../models/place_model.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';

class UserEntity {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String placeId;
  final bool isPlaceholder;

  UserEntity({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.placeId,
    this.isPlaceholder = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'placeId': placeId,
      'isPlaceholder': isPlaceholder,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      uid: map['uid'] as String,
      email: map['email'] as String,
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      role: UserRoleExtension.fromString(map['role'] as String),
      placeId: map['placeId'] ?? '',
      isPlaceholder: map['isPlaceholder'] as bool? ?? false,
    );
  }
}

extension UserRoleExtension on UserRole {
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.user,
    );
  }
}

//example usage
UserEntity testUser = UserEntity(
  uid: '123',
  email: 'test@example.com',
  firstName: 'Test',
  lastName: 'User',
  role: UserRole.superuser,
  placeId: 'munihFatih',
);