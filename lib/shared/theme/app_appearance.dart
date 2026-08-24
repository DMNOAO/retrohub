import 'package:flutter/material.dart';

import 'app_theme.dart';

enum AppearanceCategory {
  games('Juegos'),
  characters('Personajes');

  final String label;

  const AppearanceCategory(this.label);
}

enum AppAppearance {
  blue('Azul', 0xFF1677D2, 0xFF0B3158, 0xFF65B5FF, 0xFFA8DCFF,
      sprite: 'assets/sprites/pokemon/nds/black_white/009.png'),
  red('Rojo', 0xFFD71920, 0xFF6E0D12, 0xFFFF5A55, 0xFFFFB09A,
      sprite: 'assets/sprites/pokemon/gb/red_blue/0006.png'),
  yellow('Amarillo', 0xFFFFD51E, 0xFF6B5700, 0xFFFFE66A, 0xFFFFF4AD,
      sprite: 'assets/sprites/pokemon/nds/black_white/025.png'),
  gold('Oro', 0xFFD99A00, 0xFF674600, 0xFFFFC94D, 0xFFFFE29A,
      sprite: 'assets/sprites/pokemon/nds/black_white/250.png'),
  silver('Plata', 0xFFB8C5D1, 0xFF465564, 0xFFE2EAF1, 0xFFFFFFFF,
      sprite: 'assets/sprites/pokemon/nds/black_white/249.png'),
  crystal('Cristal', 0xFF13BDD1, 0xFF075564, 0xFF5EE9F4, 0xFFA291FF,
      sprite: 'assets/sprites/pokemon/nds/black_white/245.png'),
  emerald('Esmeralda', 0xFF08A65C, 0xFF075A36, 0xFF43E391, 0xFFA3F5C6,
      sprite: 'assets/sprites/pokemon/nds/black_white/384.png'),
  ruby('Rubí', 0xFFE21855, 0xFF740B31, 0xFFFF5C87, 0xFFFFA6B5,
      sprite: 'assets/sprites/pokemon/nds/black_white/383.png'),
  sapphire('Zafiro', 0xFF1559D6, 0xFF0A2D70, 0xFF5793FF, 0xFF83D9FF,
      sprite: 'assets/sprites/pokemon/nds/black_white/382.png'),
  leafGreen('Verde Hoja', 0xFF62C947, 0xFF286A22, 0xFF91E56E, 0xFFD0F58F,
      sprite: 'assets/sprites/pokemon/nds/black_white/003.png'),
  fireRed('Rojo Fuego', 0xFFF05A24, 0xFF7A260E, 0xFFFF824C, 0xFFFFC44F,
      sprite: 'assets/sprites/pokemon/nds/black_white/006.png'),
  white('Blanco', 0xFFFFFFFF, 0xFFDDE2E7, 0xFF20252B, 0xFF54718A,
      sprite: 'assets/sprites/pokemon/nds/black_white/644.png'),
  black('Negro', 0xFF000000, 0xFF121212, 0xFFFFFFFF, 0xFF9EA7B3,
      sprite: 'assets/sprites/pokemon/nds/black_white/643.png'),
  diamond('Diamante', 0xFF246BB2, 0xFF102B4F, 0xFF58D9E8, 0xFFC7D5E0,
      sprite: 'assets/sprites/pokemon/nds/black_white/483.png'),
  pearl('Perla', 0xFFC64A91, 0xFF4B183A, 0xFFF4EEF5, 0xFFD9A4CF,
      sprite: 'assets/sprites/pokemon/nds/black_white/484.png'),
  platinum('Platino', 0xFF3A353D, 0xFF17151A, 0xFFD5A62E, 0xFFB92E35,
      sprite: 'assets/sprites/pokemon/nds/black_white/487origin.png'),
  shinyUmbreon(
    'Umbreon shiny',
    0xFF080A0C,
    0xFF10171B,
    0xFF35D6E6,
    0xFF4A8DFF,
    sprite: 'assets/sprites/pokemon/gba/ruby_sapphire/shiny/0197.png',
    category: AppearanceCategory.characters,
  ),
  shinyRayquaza(
    'Rayquaza shiny',
    0xFF26332D,
    0xFF111514,
    0xFFF2C230,
    0xFFE23D3D,
    sprite: 'assets/sprites/pokemon/gba/ruby_sapphire/shiny/0384.png',
    category: AppearanceCategory.characters,
  );

  final String label;
  final int _backgroundValue;
  final int _surfaceValue;
  final int _primaryValue;
  final int _secondaryValue;
  final String? spriteAsset;
  final IconData? fallbackIcon;
  final AppearanceCategory category;

  const AppAppearance(
    this.label,
    int background,
    int surface,
    int primary,
    int secondary, {
    String? sprite,
    IconData? icon,
    this.category = AppearanceCategory.games,
  })  : _backgroundValue = background,
        _surfaceValue = surface,
        _primaryValue = primary,
        _secondaryValue = secondary,
        spriteAsset = sprite,
        fallbackIcon = icon;

  Color get background => Color(_backgroundValue);
  Color get surface => Color(_surfaceValue);
  Color get primary => Color(_primaryValue);
  Color get secondary => Color(_secondaryValue);

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

  static AppAppearance? forGameTitle(String title) {
    final normalized = title
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    if (normalized.contains('rojo fuego') || normalized.contains('fire red')) {
      return AppAppearance.fireRed;
    }
    if (normalized.contains('verde hoja') || normalized.contains('leaf green')) {
      return AppAppearance.leafGreen;
    }
    if (normalized.contains('esmeralda') || normalized.contains('emerald')) {
      return AppAppearance.emerald;
    }
    if (normalized.contains('zafiro') || normalized.contains('sapphire')) {
      return AppAppearance.sapphire;
    }
    if (normalized.contains('rubi') || normalized.contains('ruby')) {
      return AppAppearance.ruby;
    }
    if (normalized.contains('cristal') || normalized.contains('crystal')) {
      return AppAppearance.crystal;
    }
    if (normalized.contains('diamante') || normalized.contains('diamond')) {
      return AppAppearance.diamond;
    }
    if (normalized.contains('perla') || normalized.contains('pearl')) {
      return AppAppearance.pearl;
    }
    if (normalized.contains('platino') || normalized.contains('platinum')) {
      return AppAppearance.platinum;
    }
    if (normalized.contains('plata') || normalized.contains('silver')) {
      return AppAppearance.silver;
    }
    if (normalized.contains('oro') || normalized.contains('gold')) {
      return AppAppearance.gold;
    }
    if (normalized.contains('amarillo') || normalized.contains('yellow')) {
      return AppAppearance.yellow;
    }
    if (normalized.contains('azul') || normalized.contains('blue')) {
      return AppAppearance.blue;
    }
    if (normalized.contains('blanco') || normalized.contains('white')) {
      return AppAppearance.white;
    }
    if (normalized.contains('negro') || normalized.contains('black')) {
      return AppAppearance.black;
    }
    if (normalized.contains('rojo') || normalized.contains(' red')) {
      return AppAppearance.red;
    }
    return null;
  }
}
