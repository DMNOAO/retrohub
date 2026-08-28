import '../../core/emulation/core_loader.dart';
import '../../data/database/app_database.dart';

class GameFrame {
  final String id;
  final String name;
  final String assetPath;
  final double viewportLeft;
  final double viewportTop;
  final double viewportWidth;
  final double viewportHeight;
  final double gameAspectRatio;
  final List<String> titleHints;

  const GameFrame({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.viewportLeft,
    required this.viewportTop,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.gameAspectRatio,
    this.titleHints = const <String>[],
  });

  bool matchesTitle(String title) {
    final normalized = title.toLowerCase();
    return titleHints.any(normalized.contains);
  }
}

class FrameCatalog {
  static const double _gbLeft = 257 / 1280;
  static const double _gbTop = 24 / 720;
  static const double _gbWidth = 767 / 1280;
  static const double _gbHeight = 672 / 720;
  static const double _fourThreeLeft = 201 / 1280;
  static const double _fourThreeTop = 24 / 720;
  static const double _fourThreeWidth = 877 / 1280;
  static const double _fourThreeHeight = 672 / 720;

  static const List<GameFrame> gameBoy = <GameFrame>[
    GameFrame(
      id: 'gb_pokemon_green',
      name: 'Pokémon Verde',
      assetPath: 'assets/frames/gb/pokemon/pokemon_green_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      titleHints: <String>['green', 'verde'],
    ),
    GameFrame(
      id: 'gb_pokemon_red',
      name: 'Pokémon Rojo',
      assetPath: 'assets/frames/gb/pokemon/pokemon_red_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      titleHints: <String>['red', 'rojo'],
    ),
    GameFrame(
      id: 'gb_pokemon_blue',
      name: 'Pokémon Azul',
      assetPath: 'assets/frames/gb/pokemon/pokemon_blue_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      titleHints: <String>['blue', 'azul'],
    ),
    GameFrame(
      id: 'gb_pokemon_yellow',
      name: 'Pokémon Amarillo',
      assetPath: 'assets/frames/gb/pokemon/pokemon_yellow_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      titleHints: <String>['yellow', 'amarillo'],
    ),
    GameFrame(
      id: 'gb_super_game_boy_cabin',
      name: 'Cabaña Super Game Boy',
      assetPath: 'assets/frames/gb/generic/super_game_boy_cabin_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
    ),
  ];

  static const List<GameFrame> gameBoyColor = <GameFrame>[
    GameFrame(
      id: 'gbc_pokemon_gold',
      name: 'Pokémon Oro',
      assetPath: 'assets/frames/gbc/pokemon/pokemon_gold_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      titleHints: <String>['gold', 'oro'],
    ),
    GameFrame(
      id: 'gbc_pokemon_silver',
      name: 'Pokémon Plata',
      assetPath: 'assets/frames/gbc/pokemon/pokemon_silver_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      titleHints: <String>['silver', 'plata'],
    ),
    GameFrame(
      id: 'gbc_pokemon_crystal',
      name: 'Pokémon Cristal',
      assetPath: 'assets/frames/gbc/pokemon/pokemon_crystal_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      titleHints: <String>['crystal', 'cristal'],
    ),
  ];

  static const List<GameFrame> superNintendo = <GameFrame>[
    GameFrame(
      id: 'snes_box',
      name: 'Caja Super Nintendo',
      assetPath: 'assets/frames/snes/generic/snes_box_16x9.png',
      viewportLeft: _fourThreeLeft,
      viewportTop: _fourThreeTop,
      viewportWidth: _fourThreeWidth,
      viewportHeight: _fourThreeHeight,
      gameAspectRatio: 4 / 3,
    ),
    GameFrame(
      id: 'snes_cartridge',
      name: 'Cartucho Super Nintendo',
      assetPath: 'assets/frames/snes/generic/snes_cartridge_16x9.png',
      viewportLeft: _fourThreeLeft,
      viewportTop: _fourThreeTop,
      viewportWidth: _fourThreeWidth,
      viewportHeight: _fourThreeHeight,
      gameAspectRatio: 4 / 3,
    ),
    GameFrame(
      id: 'snes_trinitron',
      name: 'Televisor Trinitron',
      assetPath: 'assets/frames/snes/generic/trinitron_16x9.png',
      viewportLeft: _fourThreeLeft,
      viewportTop: _fourThreeTop,
      viewportWidth: _fourThreeWidth,
      viewportHeight: _fourThreeHeight,
      gameAspectRatio: 4 / 3,
    ),
  ];

  static List<GameFrame> forGame(Game game) {
    final title = game.title.toLowerCase();
    final console = game.console.toLowerCase();
    final isSnes = CoreLoader.isSnesRom(game.romPath) ||
        console.contains('snes') ||
        console.contains('super nintendo');
    final isGba = CoreLoader.isGbaRom(game.romPath) ||
        console.contains('gba') ||
        console.contains('advance');
    final isKnownGameBoyTitle = gameBoy.any((frame) => frame.matchesTitle(title));
    final isKnownGameBoyColorTitle =
        gameBoyColor.any((frame) => frame.matchesTitle(title));

    if (isSnes) return superNintendo;
    if (isGba) return const <GameFrame>[];
    if (isKnownGameBoyTitle) return gameBoy;
    if (isKnownGameBoyColorTitle) {
      return <GameFrame>[...gameBoyColor, gameBoy.last];
    }

    final isGameBoy = CoreLoader.isGameBoyRom(game.romPath) ||
        console.contains('game boy') ||
        console == 'gb' ||
        console == 'gbc';
    if (!isGameBoy) return const <GameFrame>[];

    final isGameBoyColor = game.romPath.toLowerCase().endsWith('.gbc') ||
        console.contains('color') ||
        console == 'gbc';
    return isGameBoyColor
        ? <GameFrame>[...gameBoyColor, gameBoy.last]
        : gameBoy;
  }

  static GameFrame? byId(Game game, String? id) {
    if (id == null) return null;
    for (final frame in forGame(game)) {
      if (frame.id == id) return frame;
    }
    return null;
  }

  static GameFrame? recommendedFor(Game game) {
    for (final frame in forGame(game)) {
      if (frame.matchesTitle(game.title)) return frame;
    }
    return null;
  }
}
