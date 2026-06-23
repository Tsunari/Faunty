import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/auth/data/repositories/auth_repository.dart';

part 'user_provider.g.dart';

@riverpod
class UserController extends _$UserController {
  @override
  Stream<UserEntity?> build() {
    return ref.watch(authRepositoryProvider).watchCurrentUser();
  }
}

// Legacy alias for backwards compatibility
final userProvider = userControllerProvider;