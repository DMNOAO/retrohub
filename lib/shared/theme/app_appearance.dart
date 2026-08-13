import 'package:flutter/material.dart';

import 'app_theme.dart';

enum AppAppearance {
  blue('Azul', 0xFF07162E, 0xFF102B52, 0xFF4EA3FF, 0xFF8DD7FF,
      sprite: 'assets/sprites/pokemon/nds/black_white/009.png'),
  red('Rojo', 0xFF260B0D, 0xFF491517, 0xFFFF5A50, 0xFFFFA268,
      sprite: 'assets/sprites/pokemon/gb/red_blue/0006.png'),
  yellow('Amarillo', 0xFF211B05, 0xFF41370A, 0xFFFFD83D, 0xFFFFF09A,
      sprite: 'assets/sprites/pokemon/nds/black_white/025.png'),
  gold('Oro', 0xFF211805, 0xFF43340D, 0xFFFFC857, 0xFFFFE4A0,
      sprite: 'assets/sprites/pokemon/nds/black_white/250.png'),
  silver('Plata', 0xFF111823, 0xFF273344, 0xFFB9C8DB, 0xFFE4ECF5,
      sprite: 'assets/sprites/pokemon/nds/black_white/249.png'),
  crystal('Cristal', 0xFF061D29, 0xFF0D3A4C, 0xFF41D7E8, 0xFF8B7CFF,
      sprite: 'assets/sprites/pokemon/nds/black_white/245.png'),
  emerald('Esmeralda', 0xFF061E17, 0xFF0C3D2B, 0xFF35D07F, 0xFF95F0B8,
      sprite: 'assets/sprites/pokemon/nds/black_white/384.png'),
  ruby('Rubí', 0xFF250912, 0xFF481323, 0xFFE84E6A, 0xFFFF9D83,
      sprite: 'assets/sprites/pokemon/nds/black_white/383.png'),
  sapphire('Zafiro', 0xFF07162A, 0xFF102D50, 0xFF3E8DFF, 0xFF76D3F5,
      sprite: 'assets/sprites/pokemon/nds/black_white/382.png'),
  leafGreen('Verde Hoja', 0xFF0A2010, 0xFF173D20, 0xFF70C850, 0xFFB6E86D,
      sprite: 'assets/sprites/pokemon/nds/black_white/003.png'),
  fireRed('Rojo Fuego', 0xFF291007, 0xFF4D1E0D, 0xFFFF7038, 0xFFFFC04B,
      sprite: 'assets/sprites/pokemon/nds/black_white/006.png'),
  white('Blanco', 0xFF17191C, 0xFF30343A, 0xFFF2F3F5, 0xFFB9D7EA,
      sprite: 'assets/sprites/pokemon/nds/black_white/644.png'),
  black('Negro', 0xFF050506, 0xFF151519, 0xFF9D88FF, 0xFFE15BDB,
      sprite: 'assets/sprites/pokemon/nds/black_white/643.png');

  final String label;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final String? spriteAsset;
  final IconData? fallbackIcon;

  const AppAppearance(
    this.label,
    int background,
    int surface,
    int primary,
    int secondary, {
    String? sprite,
    IconData? icon,
  })  : background = Color(background),
        surface = Color(surface),
        primary = Color(primary),
        secondary = Color(secondary),
        spriteAsset = sprite,
        fallbackIcon = icon;

  ThemeData get theme => AppTheme.fromPalette(
        background: background,
        surface: surface,
        primary: primary,
        secondary: secondary,
      );

  static AppAppearance fromName(String? value) => AppAppearance.values.firstWhere(
        (appearance) => appearance.name == value,
        orElse: () => AppAppearance.crystal,
      );
}
