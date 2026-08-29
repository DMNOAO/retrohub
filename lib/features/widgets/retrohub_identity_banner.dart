import 'dart:async';

import 'package:flutter/material.dart';

import '../emulator/presentation/widget/retrohub_console_logo.dart';

class RetroHubIdentityBanner extends StatefulWidget {
  const RetroHubIdentityBanner({super.key});

  @override
  State<RetroHubIdentityBanner> createState() => _RetroHubIdentityBannerState();
}

class _RetroHubIdentityBannerState extends State<RetroHubIdentityBanner> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = Color.lerp(scheme.surface, scheme.primary, .48)!;
    final middle = Color.lerp(scheme.surface, scheme.secondary, .20)!;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [start, middle, scheme.surface],
          stops: const [0, .52, 1],
        ),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: .55),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RetroHubAnimatedConsoleLogo(),
          const SizedBox(height: 12),
          Text(
            'Preserva la historia de cada partida',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurface.withValues(alpha: .75),
            ),
          ),
        ],
      ),
    );
  }
}

class RetroHubAnimatedConsoleLogo extends StatefulWidget {
  final Duration interval;

  const RetroHubAnimatedConsoleLogo({
    super.key,
    this.interval = const Duration(seconds: 5),
  });

  @override
  State<RetroHubAnimatedConsoleLogo> createState() =>
      _RetroHubAnimatedConsoleLogoState();
}

class _RetroHubAnimatedConsoleLogoState
    extends State<RetroHubAnimatedConsoleLogo> {
  static const _logos = <RetroHubConsoleType>[
    RetroHubConsoleType.gameBoy,
    RetroHubConsoleType.gameBoyColor,
    RetroHubConsoleType.gameBoyAdvance,
    RetroHubConsoleType.superNintendo,
    RetroHubConsoleType.nintendoDs,
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .94, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: FittedBox(
        key: ValueKey(_logos[_index]),
        fit: BoxFit.scaleDown,
        child: RetroHubConsoleLogo(console: _logos[_index]),
      ),
    );
  }
}
