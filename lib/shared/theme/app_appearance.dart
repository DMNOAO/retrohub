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
      sprite: 'assets/sprites/pokemon/nds/gen5/0009.png'),
  red('Rojo', 0xFFD71920, 0xFF6E0D12, 0xFFFF5A55, 0xFFFFB09A,
      sprite: 'assets/sprites/pokemon/gb/red_blue/0006.png'),
  yellow('Amarillo', 0xFFFFD51E, 0xFF6B5700, 0xFFFFE66A, 0xFFFFF4AD,
      sprite: 'assets/sprites/pokemon/nds/gen5/0025.png'),
  gold('Oro', 0xFFD99A00, 0xFF674600, 0xFFFFC94D, 0xFFFFE29A,
      sprite: 'assets/sprites/pokemon/nds/gen5/0250.png'),
  silver('Plata', 0xFFB8C5D1, 0xFF465564, 0xFFE2EAF1, 0xFFFFFFFF,
      sprite: 'assets/sprites/pokemon/nds/gen5/0249.png'),
  crystal('Cristal', 0xFF33206E, 0xFF17294F, 0xFF72DDF2, 0xFF9D75EA,
      sprite: 'assets/sprites/pokemon/nds/gen5/0245.png'),
  emerald('Esmeralda', 0xFF08A65C, 0xFF075A36, 0xFF43E391, 0xFFA3F5C6,
      sprite: 'assets/sprites/pokemon/nds/gen5/0384.png'),
  ruby('Rubí', 0xFF9E1833, 0xFF5F1025, 0xFFFF4F66, 0xFF3C8DFF,
      sprite: 'assets/sprites/pokemon/nds/gen5/0383.png'),
  sapphire('Zafiro', 0xFF0756A6, 0xFF082E68, 0xFF43A5FF, 0xFFFF5A5F,
      sprite: 'assets/sprites/pokemon/nds/gen5/0382.png'),
  leafGreen('Verde Hoja', 0xFF62C947, 0xFF286A22, 0xFF91E56E, 0xFFD0F58F,
      sprite: 'assets/sprites/pokemon/nds/gen5/0003.png'),
  fireRed('Rojo Fuego', 0xFFF05A24, 0xFF7A260E, 0xFFFF824C, 0xFFFFC44F,
      sprite: 'assets/sprites/pokemon/nds/gen5/0006.png'),
  white('Blanco', 0xFFFFFFFF, 0xFFDDE2E7, 0xFF20252B, 0xFF54718A,
      sprite: 'assets/sprites/pokemon/nds/gen5/0644.png'),
  black('Negro', 0xFF000000, 0xFF121212, 0xFFFFFFFF, 0xFF9EA7B3,
      sprite: 'assets/sprites/pokemon/nds/gen5/0643.png'),
  white2('Blanco 2', 0xFFF2F4F7, 0xFFD9DEE5, 0xFF2779D8, 0xFFD84A43,
      sprite: 'assets/sprites/pokemon/nds/gen5/0646-white.png'),
  black2('Negro 2', 0xFF0B0D12, 0xFF181D27, 0xFFF1D13A, 0xFF3285E6,
      sprite: 'assets/sprites/pokemon/nds/gen5/0646-black.png'),
  heartGold('HeartGold', 0xFF4A2A0B, 0xFF8A321B, 0xFFFFC934, 0xFF3E9A61,
      sprite: 'assets/sprites/pokemon/nds/gen5/0250.png'),
  soulSilver('SoulSilver', 0xFF101D31, 0xFF243A55, 0xFFE7EEF5, 0xFF5CB9E8,
      sprite: 'assets/sprites/pokemon/nds/gen5/0249.png'),
  diamond('Diamante', 0xFF78BFD0, 0xFF173C56, 0xFF5DE4ED, 0xFFD9E7EC,
      sprite: 'assets/sprites/pokemon/nds/gen5/0483.png'),
  pearl('Perla', 0xFFC64A91, 0xFF4B183A, 0xFFF4EEF5, 0xFFD9A4CF,
      sprite: 'assets/sprites/pokemon/nds/gen5/0484.png'),
  platinum('Platino', 0xFF3A353D, 0xFF17151A, 0xFFD5A62E, 0xFFB92E35,
      sprite: 'assets/sprites/pokemon/nds/gen5/0487-origin.png'),
  shinyUmbreon(
    'Umbreon shiny',
    0xFF080A0C,
    0xFF10171B,
    0xFF4A8DFF,
    0xFFF2D33D,
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
  ),
  gengar(
    'Gengar',
    0xFF522080,
    0xFF1D1028,
    0xFFD94CFF,
    0xFFA98BD4,
    sprite: 'assets/sprites/pokemon/nds/gen5/0094.png',
    category: AppearanceCategory.characters,
  ),
  shinyMetagross(
    'Metagross shiny',
    0xFF9AABB5,
    0xFF34444E,
    0xFFF2C230,
    0xFFE4EDF1,
    sprite: 'assets/sprites/pokemon/gba/ruby_sapphire/shiny/0376.png',
    category: AppearanceCategory.characters,
  ),
  mewtwo(
    'Mewtwo',
    0xFF8A6FB3,
    0xFF2D2040,
    0xFFC9B7E8,
    0xFF7A3DB8,
    sprite: 'assets/sprites/pokemon/nds/gen5/0150.png',
    category: AppearanceCategory.characters,
  ),
  shinyCelebi(
    'Celebi shiny',
    0xFFE783AE,
    0xFF672D4A,
    0xFF45B98C,
    0xFFF7D9B5,
    sprite: 'assets/sprites/pokemon/gba/ruby_sapphire/shiny/0251.png',
    category: AppearanceCategory.characters,
  ),
  cresselia(
    'Cresselia',
    0xFF8A72C2,
    0xFF352654,
    0xFFF1D45C,
    0xFFF08BC3,
    sprite: 'assets/sprites/pokemon/nds/gen5/0488.png',
    category: AppearanceCategory.characters,
  ),
  darkrai(
    'Darkrai',
    0xFF17121F,
    0xFF0B0910,
    0xFFD9344E,
    0xFFB8D7F0,
    sprite: 'assets/sprites/pokemon/nds/gen5/0491.png',
    category: AppearanceCategory.characters,
  ),
  arceus(
    'Arceus',
    0xFFEDE5D1,
    0xFFFFFAEA,
    0xFFD7AE32,
    0xFF55A987,
    sprite: 'assets/sprites/pokemon/nds/gen5/0493.png',
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

  int get catalogOrder => switch (this) {
        AppAppearance.red => 100,
        AppAppearance.blue => 110,
        AppAppearance.yellow => 120,
        AppAppearance.gold => 200,
        AppAppearance.silver => 210,
        AppAppearance.crystal => 220,
        AppAppearance.ruby => 300,
        AppAppearance.sapphire => 310,
        AppAppearance.emerald => 320,
        AppAppearance.fireRed => 330,
        AppAppearance.leafGreen => 340,
        AppAppearance.diamond => 400,
        AppAppearance.pearl => 410,
        AppAppearance.platinum => 420,
        AppAppearance.heartGold => 430,
        AppAppearance.soulSilver => 440,
        AppAppearance.black => 500,
        AppAppearance.white => 510,
        AppAppearance.black2 => 520,
        AppAppearance.white2 => 530,
        AppAppearance.gengar => 1094,
        AppAppearance.mewtwo => 1150,
        AppAppearance.shinyUmbreon => 2197,
        AppAppearance.shinyCelebi => 2251,
        AppAppearance.shinyMetagross => 3376,
        AppAppearance.shinyRayquaza => 3384,
        AppAppearance.cresselia => 4488,
        AppAppearance.darkrai => 4491,
        AppAppearance.arceus => 4493,
      };

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

  static List<AppAppearance> forCategory(AppearanceCategory category) {
    final appearances = AppAppearance.values
        .where((appearance) => appearance.category == category)
        .toList()
      ..sort((first, second) =>
          first.catalogOrder.compareTo(second.catalogOrder));
    return appearances;
  }

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
    if (normalized.contains('heartgold') || normalized.contains('heart gold')) {
      return AppAppearance.heartGold;
    }
    if (normalized.contains('soulsilver') || normalized.contains('soul silver')) {
      return AppAppearance.soulSilver;
    }
    if (normalized.contains('blanco 2') || normalized.contains('blanca 2') || normalized.contains('white 2')) {
      return AppAppearance.white2;
    }
    if (normalized.contains('negro 2') || normalized.contains('negra 2') || normalized.contains('black 2')) {
      return AppAppearance.black2;
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
    if (normalized.contains('blanco') ||
        normalized.contains('blanca') ||
        normalized.contains('white')) {
      return AppAppearance.white;
    }
    if (normalized.contains('negro') ||
        normalized.contains('negra') ||
        normalized.contains('black')) {
      return AppAppearance.black;
    }
    if (normalized.contains('rojo') || normalized.contains(' red')) {
      return AppAppearance.red;
    }
    return null;
  }
}
