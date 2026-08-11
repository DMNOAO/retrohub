import 'package:flutter/material.dart';

enum RetroHubConsoleType {
  gameBoy,
  gameBoyColor,
  gameBoyAdvance,
  superNintendo,
}

class RetroHubConsoleLogo extends StatelessWidget {
  final RetroHubConsoleType console;

  const RetroHubConsoleLogo({
    super.key,
    required this.console,
  });

  @override
  Widget build(BuildContext context) {
    switch (console) {
      case RetroHubConsoleType.gameBoy:
        return _gameBoy();

      case RetroHubConsoleType.gameBoyColor:
        return _gameBoyColor();

      case RetroHubConsoleType.gameBoyAdvance:
        return _gameBoyAdvance();

      case RetroHubConsoleType.superNintendo:
        return _superNintendo();
    }
  }

  Widget _superNintendo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'RETROHUB',
          style: TextStyle(
            color: Color(0xFFE8E6F2),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.5,
            shadows: [Shadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 2))],
          ),
        ),
        Text(
          'SUPER',
          style: TextStyle(
            color: Color(0xFF8E82C4),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 7,
          ),
        ),
      ],
    );
  }

  Widget _gameBoy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "RETROHUB",
          style: TextStyle(
            color: const Color(0xFFB7D44A),
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Text(
          "GAME BOY",
          style: TextStyle(
            color: const Color(0xFF6D7D32),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }

  Widget _gameBoyAdvance() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "RETROHUB",
          style: TextStyle(
            color: Color(0xFF6B56D6),
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Text(
          "ADVANCE",
          style: TextStyle(
            color: Color(0xFFB39DFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }

  Widget _gameBoyColor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "RETROHUB",
          style: TextStyle(
            color: Color(0xFF304FFE),
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
            children: const [
              TextSpan(
                text: "C",
                style: TextStyle(color: Color(0xFFE91E63)),
              ),
              TextSpan(
                text: "O",
                style: TextStyle(color: Color(0xFF5E35B1)),
              ),
              TextSpan(
                text: "L",
                style: TextStyle(color: Color(0xFF64DD17)),
              ),
              TextSpan(
                text: "O",
                style: TextStyle(color: Color(0xFFFFC107)),
              ),
              TextSpan(
                text: "R",
                style: TextStyle(color: Color(0xFF00BCD4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
