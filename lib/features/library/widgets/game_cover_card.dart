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
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
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
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: widget.coverPath == null
                        ? Container(
                            color: Colors.black26,
                            child: const Icon(
                              Icons.videogame_asset,
                              size: 48,
                              color: Colors.white38,
                            ),
                          )
                        : Image.asset(
                            widget.coverPath!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.console,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
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