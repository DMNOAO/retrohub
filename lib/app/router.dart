import 'package:go_router/go_router.dart';

import '../features/shell/main_shell.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
    ),
  ],
);