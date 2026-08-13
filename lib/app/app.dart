import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/theme/app_appearance.dart';
import '../shared/theme/appearance_provider.dart';
import 'router.dart';

class RetroHubApp extends ConsumerWidget {
  const RetroHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider).value ?? AppAppearance.crystal;
    return MaterialApp.router(
      title: 'RetroHub',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: appearance.theme,
    );
  }
}
