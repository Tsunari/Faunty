import 'package:faunty/core/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigated) return;
          if (user == null) {
            _navigated = true;
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            return;
          }
          if (user.placeId.isNotEmpty) {
            _navigated = true;
            printInfo("UserEntity in SplashPage: ${user.toMap()}");
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
            return;
          } else {
            _navigated = true;
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }
        });
        // Always return a widget, even though navigation will occur
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error loading user: $err')),
      ),
    );
  }
}