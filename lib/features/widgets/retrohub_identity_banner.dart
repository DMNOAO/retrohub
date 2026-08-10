import 'dart:async';

import 'package:flutter/material.dart';

import '../emulator/presentation/widget/retrohub_console_logo.dart';

class RetroHubIdentityBanner extends StatefulWidget {
  const RetroHubIdentityBanner({super.key});

  @override
  State<RetroHubIdentityBanner> createState() => _RetroHubIdentityBannerState();
}

class _RetroHubIdentityBannerState extends State<RetroHubIdentityBanner> {
  static const _logos = <RetroHubConsoleType>[
    RetroHubConsoleType.gameBoy,
    RetroHubConsoleType.gameBoyColor,
    RetroHubConsoleType.gameBoyAdvance,
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _logos.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade900, Colors.black],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 650),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: .96, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: FittedBox(
              key: ValueKey(_logos[_index]),
              fit: BoxFit.scaleDown,
              child: RetroHubConsoleLogo(console: _logos[_index]),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Preserva la historia de cada partida',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
