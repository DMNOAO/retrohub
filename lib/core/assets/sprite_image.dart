import 'dart:io';

import 'package:flutter/material.dart';

class SpriteImage extends StatelessWidget {
  final String? path;
  final double size;
  final IconData fallbackIcon;
  final BoxFit fit;
  final bool removeWhiteBackground;

  const SpriteImage({
    super.key,
    required this.path,
    this.size = 48,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.fit = BoxFit.contain,
    this.removeWhiteBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return _fallback();

    final Widget image;
    if (value.startsWith('assets/')) {
      image = Image.asset(
        value,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      image = Image.file(
        File(value),
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    final rendered = removeWhiteBackground
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1, 0, 0, 0, 0,
              0, 1, 0, 0, 0,
              0, 0, 1, 0, 0,
              -1, -1, -1, 1, 510,
            ]),
            child: image,
          )
        : image;

    return SizedBox(width: size, height: size, child: rendered);
  }

  Widget _fallback() {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(fallbackIcon, size: size * .58),
    );
  }
}
