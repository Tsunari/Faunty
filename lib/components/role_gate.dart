import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/user_provider.dart';
import '../models/user_roles.dart';

/// A widget that only renders its child if the current user's role is equal to or higher than [minRole].
/// Optionally, you can provide a [fallback] widget to show if the user does not have permission.
class RoleGate extends ConsumerWidget {
  final UserRole minRole;
  final Widget child;
  final Widget? fallback;
  final List<String>? showChildOnPages;

  const RoleGate({
    super.key,
    required this.minRole,
    required this.child,
    this.fallback,
    this.showChildOnPages,
  });

  /// Returns the index of the role in the hierarchy (lower index = higher privilege).
  int _roleIndex(UserRole role) {
    switch (role) {
      case UserRole.superuser:
        return 0;
      case UserRole.hoca:
        return 1;
      case UserRole.baskan:
        return 2;
      case UserRole.talebe:
        return 3;
      case UserRole.user:
        return 4;
      case UserRole.spectator:
        return 5;
      case UserRole.archived:
        return 6;
      case UserRole.unknown:
        return 7;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    final String? routeName = route?.settings.name;
    return userAsync.when(
      data: (user) {
        // If showChildOnPages is set and routeName matches any, always show child
        if (showChildOnPages != null && routeName != null && showChildOnPages!.contains(routeName)) {
          return child;
        }
        if (user == null) {
          return fallback ?? const SizedBox.shrink();
        }
        final userRole = user.role;
        if (_roleIndex(userRole) <= _roleIndex(minRole)) {
          return child;
        } else {
          return fallback ?? const SizedBox.shrink();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('An error occurred loading user data in RoleGate.', style: TextStyle(color: Colors.red, fontSize: 16)),
            ...[
            const SizedBox(height: 8),
            Text(e.toString(), style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
          ],
        ),
      ),
    );
  }
}
