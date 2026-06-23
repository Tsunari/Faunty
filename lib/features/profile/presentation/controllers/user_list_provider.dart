import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/profile/data/repositories/profile_repository.dart';
import 'package:faunty/core/utils/sort_utils.dart';

part 'user_list_provider.g.dart';

@riverpod
Stream<List<UserEntity>> allUsers(AllUsersRef ref) {
  return ref.watch(profileRepositoryProvider).watchAllUsers();
}

@riverpod
Stream<List<UserEntity>> usersByCurrentPlace(UsersByCurrentPlaceRef ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  return ref.watch(profileRepositoryProvider).watchUsersByPlace(user.placeId);
}

@riverpod
Stream<List<UserEntity>> usersByCurrentPlaceWithOptions(
    UsersByCurrentPlaceWithOptionsRef ref, UserSortOption? sort) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  return ref.watch(profileRepositoryProvider).watchUsersByPlace(user.placeId).map((users) {
    if (sort != null) {
      final mutableUsers = List<UserEntity>.from(users);
      mutableUsers.sort((a, b) => compareUsersByOption(a, b, sort));
      return mutableUsers;
    }
    return users;
  });
}

@riverpod
Stream<List<UserEntity>> usersByRoles(UsersByRolesRef ref, String rolesKey) {
  final roleNames = rolesKey.split(',');
  return ref.watch(profileRepositoryProvider).watchUsersByRoles(roleNames);
}

@riverpod
Stream<List<UserEntity>> usersByRolesWithOptions(
    UsersByRolesWithOptionsRef ref, Map<String, dynamic> params) {
  final roleNames = (params['rolesKey'] as String).split(',');
  final UserSortOption? sort = params['sort'] as UserSortOption?;
  return ref.watch(profileRepositoryProvider).watchUsersByRoles(roleNames).map((users) {
    if (sort != null) {
      final mutableUsers = List<UserEntity>.from(users);
      mutableUsers.sort((a, b) => compareUsersByOption(a, b, sort));
      return mutableUsers;
    }
    return users;
  });
}

@riverpod
Stream<List<UserEntity>> usersByRolesAndPlace(UsersByRolesAndPlaceRef ref, String rolesKey) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  final roleNames = rolesKey.split(',');
  return ref.watch(profileRepositoryProvider).watchUsersByPlaceAndRoles(user.placeId, roleNames);
}

@riverpod
Stream<List<UserEntity>> usersByRolesAndPlaceWithOptions(
    UsersByRolesAndPlaceWithOptionsRef ref, Map<String, dynamic> params) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  final roleNames = (params['rolesKey'] as String).split(',');
  final UserSortOption? sort = params['sort'] as UserSortOption?;
  return ref.watch(profileRepositoryProvider).watchUsersByPlaceAndRoles(user.placeId, roleNames).map((users) {
    if (sort != null) {
      final mutableUsers = List<UserEntity>.from(users);
      mutableUsers.sort((a, b) => compareUsersByOption(a, b, sort));
      return mutableUsers;
    }
    return users;
  });
}

// Legacy aliases for backward compatibility
final usersByCurrentPlaceProviderWithOptions = usersByCurrentPlaceWithOptionsProvider;
final usersByRolesProviderWithOptions = usersByRolesWithOptionsProvider;
final usersByRolesAndPlaceProviderWithOptions = usersByRolesAndPlaceWithOptionsProvider;