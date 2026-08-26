import 'dart:io';

import 'package:flutter/material.dart';

class SpriteImage extends StatelessWidget {
  final String? path;
  final double size;
  final IconData fallbackIcon;
  final String? fallbackPath;
  final BoxFit fit;

  const SpriteImage({
    super.key,
    required this.path,
    this.size = 48,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.fallbackPath,
    this.fit = BoxFit.contain,
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
        errorBuilder: (_, __, ___) => _fallbackImage(),
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

    return SizedBox(width: size, height: size, child: image);
  }

  Widget _fallbackImage() {
    final fallback = fallbackPath?.trim();
    if (fallback != null && fallback.isNotEmpty && fallback != path) {
      return Image.asset(
        fallback,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(fallbackIcon, size: size * .58),
    );
  }
}
