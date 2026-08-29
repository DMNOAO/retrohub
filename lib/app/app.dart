import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/auth/auth_provider.dart';
import '../features/widgets/retrohub_identity_banner.dart';
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
                  width: 270,
                  height: 142,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.surface,
                        Color.lerp(colors.surface, colors.primary, .34)!,
                        Color.lerp(colors.surface, colors.secondary, .24)!,
                      ],
                    ),
                    border: Border.all(color: colors.outline, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: colors.secondary.withValues(alpha: 0.35),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: List<Color>.generate(
                        18,
                        (index) => index.isEven
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: .035),
                      ),
                    ),
                  ),
                  child: const Center(
                    child: RetroHubAnimatedConsoleLogo(
                      interval: Duration(milliseconds: 420),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'INICIANDO SISTEMA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: colors.primary, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Biblioteca  •  Cuenta  •  Partidas',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 26),
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
