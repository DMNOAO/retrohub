import 'package:flutter/material.dart';

class GameCoverCard extends StatefulWidget {
  final String title;
  final String console;
  final String? coverPath;
  final VoidCallback onTap;

  const GameCoverCard({
    super.key,
    required this.title,
    required this.console,
    required this.coverPath,
    required this.onTap,
  });

  @override
  State<GameCoverCard> createState() => _GameCoverCardState();
}

class _GameCoverCardState extends State<GameCoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered
                    ? const Color(0xFF8B5CF6)
                    : Colors.white.withOpacity(0.08),
                width: _hovered ? 2 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
              color: const Color(0xFF15151F),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Expanded(,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: widget.coverPath == null
                        ? const Icon(
                            Icons.videogame_asset,
                            size: 48,
                            color: Colors.white38,
                          )
                        : Image.asset(
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.videogame_asset,
                              size: 48,
                              color: Colors.white38,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.console,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}