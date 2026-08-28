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
  final int backgroundColorValue;
  final List<String> titleHints;
  final bool onlyForMatchingTitle;

  const GameFrame({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.viewportLeft,
    required this.viewportTop,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.gameAspectRatio,
    required this.backgroundColorValue,
    this.titleHints = const <String>[],
    this.onlyForMatchingTitle = false,
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
  static const double _adaptedLeft = 240 / 1280;
  static const double _adaptedTop = 52 / 720;
  static const double _adaptedWidth = 800 / 1280;
  static const double _adaptedHeight = 616 / 720;

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
      backgroundColorValue: 0xFF90C860,
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
      backgroundColorValue: 0xFFC888A8,
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
      backgroundColorValue: 0xFF5088D0,
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
      backgroundColorValue: 0xFF78C878,
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
      backgroundColorValue: 0xFF011000,
    ),
    GameFrame(
      id: 'gb_dmg_cyan',
      name: 'DMG Cian',
      assetPath: 'assets/frames/gb/generic/dmg_cyan_16x9.png',
      viewportLeft: _adaptedLeft,
      viewportTop: _adaptedTop,
      viewportWidth: _adaptedWidth,
      viewportHeight: _adaptedHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFF03A4F6,
    ),
    GameFrame(
      id: 'gb_dmg_red',
      name: 'DMG Rojo',
      assetPath: 'assets/frames/gb/generic/dmg_red_16x9.png',
      viewportLeft: _adaptedLeft,
      viewportTop: _adaptedTop,
      viewportWidth: _adaptedWidth,
      viewportHeight: _adaptedHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFFF60303,
    ),
    GameFrame(
      id: 'gb_dmg_turquoise',
      name: 'DMG Turquesa',
      assetPath: 'assets/frames/gb/generic/dmg_turquoise_16x9.png',
      viewportLeft: _adaptedLeft,
      viewportTop: _adaptedTop,
      viewportWidth: _adaptedWidth,
      viewportHeight: _adaptedHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFF03F6F6,
    ),
    GameFrame(
      id: 'gb_dmg_yellow_green',
      name: 'DMG Amarillo/Verde',
      assetPath: 'assets/frames/gb/generic/dmg_yellow_green_16x9.png',
      viewportLeft: _adaptedLeft,
      viewportTop: _adaptedTop,
      viewportWidth: _adaptedWidth,
      viewportHeight: _adaptedHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFFCEF603,
    ),
    GameFrame(
      id: 'gb_zelda_links_awakening',
      name: 'Zelda: Link’s Awakening',
      assetPath: 'assets/frames/gb/games/zelda_links_awakening_16x9.png',
      viewportLeft: _adaptedLeft,
      viewportTop: _adaptedTop,
      viewportWidth: _adaptedWidth,
      viewportHeight: _adaptedHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFFF3EBF3,
      titleHints: <String>['zelda', 'link awakening', "link's awakening"],
      onlyForMatchingTitle: true,
    ),
    GameFrame(
      id: 'gb_pokemon_picross',
      name: 'Pokémon Picross',
      assetPath: 'assets/frames/gb/games/pokemon_picross_16x9.png',
      viewportLeft: _adaptedLeft,
      viewportTop: _adaptedTop,
      viewportWidth: _adaptedWidth,
      viewportHeight: _adaptedHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFF000000,
      titleHints: <String>['picross'],
      onlyForMatchingTitle: true,
    ),
    GameFrame(
      id: 'gb_tetris',
      name: 'Tetris',
      assetPath: 'assets/frames/gb/games/tetris_16x9.png',
      viewportLeft: _adaptedLeft,
      viewportTop: _adaptedTop,
      viewportWidth: _adaptedWidth,
      viewportHeight: _adaptedHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFF0038C0,
      titleHints: <String>['tetris'],
      onlyForMatchingTitle: true,
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
      backgroundColorValue: 0xFFF8D078,
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
      backgroundColorValue: 0xFFC0C8D8,
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
      backgroundColorValue: 0xFFB08840,
      titleHints: <String>['crystal', 'cristal'],
    ),
    GameFrame(
      id: 'gbc_pokemon_trading_card_game',
      name: 'Pokémon Trading Card Game',
      assetPath: 'assets/frames/gbc/games/pokemon_trading_card_game_16x9.png',
      viewportLeft: _gbLeft,
      viewportTop: _gbTop,
      viewportWidth: _gbWidth,
      viewportHeight: _gbHeight,
      gameAspectRatio: 10 / 9,
      backgroundColorValue: 0xFFE8CFAF,
      titleHints: <String>['trading card', 'pokemon tcg', 'cartas pokemon'],
      onlyForMatchingTitle: true,
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
      backgroundColorValue: 0xFF4D113F,
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
      backgroundColorValue: 0xFF7D7785,
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
      backgroundColorValue: 0xFF171717,
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
    if (isKnownGameBoyTitle) return _visibleForTitle(gameBoy, title);
    if (isKnownGameBoyColorTitle) {
      return <GameFrame>[
        ..._visibleForTitle(gameBoyColor, title),
        ..._genericGameBoyFrames,
      ];
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
        ? <GameFrame>[
            ..._visibleForTitle(gameBoyColor, title),
            ..._genericGameBoyFrames,
          ]
        : _visibleForTitle(gameBoy, title);
  }

  static List<GameFrame> _visibleForTitle(
    List<GameFrame> frames,
    String title,
  ) {
    return frames
        .where((frame) =>
            !frame.onlyForMatchingTitle || frame.matchesTitle(title))
        .toList(growable: false);
  }

  static Iterable<GameFrame> get _genericGameBoyFrames => gameBoy.where(
        (frame) =>
            frame.id == 'gb_super_game_boy_cabin' ||
            frame.id.startsWith('gb_dmg_'),
      );

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
