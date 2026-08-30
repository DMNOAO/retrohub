import '../../core/emulation/core_loader.dart';
import '../../data/database/app_database.dart';

enum PortraitCardFamily { classic, exp, trainer }

class PortraitGameFrame {
  final String id;
  final String name;
  final String assetPath;
  final PortraitCardFamily family;

  const PortraitGameFrame({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.family,
  });

  String get typeKey => id
      .replaceFirst('portrait_', '')
      .replaceFirst('_exp', '')
      .replaceFirst('trainer_rocket', 'oscuridad');

  String get energyAssetPath =>
      'assets/frames/portrait/energy/$typeKey.png';
}

class PortraitFrameCatalog {
  static const Map<String, String> _typeNames = <String, String>{
    'agua': 'Agua',
    'electrico': 'Eléctrico',
    'dragon': 'Dragón',
    'fuego': 'Fuego',
    'hada': 'Hada',
    'hoja': 'Hoja',
    'lucha': 'Lucha',
    'metal': 'Metal',
    'normal': 'Normal',
    'oscuridad': 'Oscuridad',
    'psi': 'Psíquico',
  };

  static bool supports(Game game) {
    final title = game.title.toLowerCase();
    final isPokemon = title.contains('pokemon') || title.contains('pokémon');
    return isPokemon &&
        (CoreLoader.isGameBoyRom(game.romPath) ||
            CoreLoader.isGbaRom(game.romPath));
  }

  static List<PortraitGameFrame> forGame(Game game) {
    if (!supports(game)) return const <PortraitGameFrame>[];
    final family = CoreLoader.isGbaRom(game.romPath)
        ? PortraitCardFamily.exp
        : PortraitCardFamily.classic;
    final suffix = family == PortraitCardFamily.exp ? '_exp' : '';
    return <PortraitGameFrame>[
      for (final entry in _typeNames.entries)
        PortraitGameFrame(
          id: 'portrait_${entry.key}$suffix',
          name: 'Carta ${entry.value}',
          assetPath: entry.key == 'dragon' || entry.key == 'hada'
              ? 'assets/frames/portrait/cards/normal$suffix.png'
              : 'assets/frames/portrait/cards/${entry.key}$suffix.png',
          family: family,
        ),
      const PortraitGameFrame(
        id: 'portrait_trainer_rocket',
        name: 'Entrenador Rocket',
        assetPath: 'assets/frames/portrait/cards/trainer_r.png',
        family: PortraitCardFamily.trainer,
      ),
    ];
  }

  static PortraitGameFrame? byId(Game game, String? id) {
    if (id == null) return null;
    for (final frame in forGame(game)) {
      if (frame.id == id) return frame;
    }
    return null;
  }

  static PortraitGameFrame? recommendedFor(Game game) {
    final frames = forGame(game);
    if (frames.isEmpty) return null;
    final title = game.title.toLowerCase();
    final type = switch (title) {
      String value when value.contains('yellow') || value.contains('amarillo') =>
        'electrico',
      String value when value.contains('blue') ||
          value.contains('azul') ||
          value.contains('sapphire') ||
          value.contains('zafiro') ||
          value.contains('silver') ||
          value.contains('plata') =>
        'agua',
      String value when value.contains('red') ||
          value.contains('rojo') ||
          value.contains('ruby') ||
          value.contains('rubi') ||
          value.contains('rubí') =>
        'fuego',
      String value when value.contains('green') ||
          value.contains('verde') ||
          value.contains('emerald') ||
          value.contains('esmeralda') =>
        'hoja',
      String value when value.contains('gold') || value.contains('oro') =>
        'metal',
      String value when value.contains('crystal') || value.contains('cristal') =>
        'psi',
      _ => 'normal',
    };
    return frames.firstWhere(
      (frame) => frame.id.startsWith('portrait_$type'),
      orElse: () => frames.first,
    );
  }
}
