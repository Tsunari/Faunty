import 'package:faunty/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state_management/user_provider.dart';
import '../../models/user_roles.dart';


class UserWelcomePage extends ConsumerStatefulWidget {
  const UserWelcomePage({super.key});

  @override
  ConsumerState<UserWelcomePage> createState() => _UserWelcomePageState();
}

class _UserWelcomePageState extends ConsumerState<UserWelcomePage> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAsync = ref.watch(userProvider);

    userAsync.when(
      data: (user) {
        if (userAsync is AsyncData && !_navigated && user != null && user.role != UserRole.user && user.role != UserRole.unknown) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
        }
        // check if user is logged in if not go to login page
        if (userAsync is AsyncData && userAsync.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != '/login') {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          });
        }
      },
      loading: () {},
      error: (e, st) {},
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha((100)),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha((0.18 * 255).toInt()),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 44,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Faunty!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is pending approval or further setup.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.logout, size: 20, color: colorScheme.onPrimary),
                    label: Text('Logout', style: TextStyle(fontSize: 16, color: colorScheme.onPrimary)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => logout(context: context, ref: ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}