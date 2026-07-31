import 'package:flutter/material.dart';

import 'router.dart';

class RetroHubApp extends StatelessWidget {
  const RetroHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RetroHub',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData.dark(useMaterial3: true),
    );
  }
}