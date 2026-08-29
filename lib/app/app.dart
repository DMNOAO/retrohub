import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/auth/auth_provider.dart';
import '../shared/theme/app_appearance.dart';
import '../shared/theme/appearance_provider.dart';
import 'router.dart';

class RetroHubApp extends ConsumerWidget {
  const RetroHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider).value ?? AppAppearance.crystal;
    final auth = ref.watch(authUserProvider);
    return MaterialApp.router(
      title: 'RetroHub',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: appearance.theme,
      builder: (context, child) {
        if (auth.isLoading) return const _StartupScreen();
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: colors.secondary.withValues(alpha: 0.35),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.sports_esports,
                    size: 58,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'RetroHub',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  'Preparando tu biblioteca y tu cuenta…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
