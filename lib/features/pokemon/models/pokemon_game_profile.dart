import '../memory/pokemon_addresses.dart';

enum PokemonGeneration { gen1, gen2, gen3, gen4, unsupported }

enum PokemonGameVersion {
  redBlue,
  yellow,
  gold,
  silver,
  crystal,
  ruby,
  sapphire,
  emerald,
  fireRed,
  leafGreen,
  diamond,
  pearl,
  platinum,
  heartGold,
  soulSilver,
  unsupported,
}

class PokemonGameProfile {
  final PokemonGameVersion version;
  final PokemonGeneration generation;
  final String displayName;
  final bool memoryMapVerified;
  final PokemonMemoryAddresses? addresses;

  const PokemonGameProfile({
    required this.version,
    required this.generation,
    required this.displayName,
    required this.memoryMapVerified,
    required this.addresses,
  });

  bool get isGen1 => generation == PokemonGeneration.gen1;
  bool get isGen2 => generation == PokemonGeneration.gen2;
  bool get isGen3 => generation == PokemonGeneration.gen3;
  bool get isGen4 => generation == PokemonGeneration.gen4;

  /// Identifica la versión usando primero el título conservado en la
  /// biblioteca. La ruta queda como respaldo para instalaciones antiguas
  /// cuyas ROM todavía mantienen el nombre original.
  static PokemonGameProfile fromGameIdentity({
    required String gameTitle,
    required String romPath,
  }) {
    final normalized = _normalize('$gameTitle $romPath');

    // Gen IV debe resolverse antes que Gen I/II. Los títulos de ROM suelen
    // incluir región, revisión y grupo, pero conservan el nombre del juego.
    if (normalized.contains('platinum') || normalized.contains('platino')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.platinum,
        generation: PokemonGeneration.gen4,
        displayName: 'Pokémon Platinum',
        memoryMapVerified: false,
        addresses: null,
      );
    }
    if (normalized.contains('heartgold') ||
        normalized.contains('heart gold') ||
        normalized.contains('oro heartgold') ||
        normalized.contains('oro heart gold')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.heartGold,
        generation: PokemonGeneration.gen4,
        displayName: 'Pokémon HeartGold',
        memoryMapVerified: false,
        addresses: null,
      );
    }
    if (normalized.contains('soulsilver') ||
        normalized.contains('soul silver') ||
        normalized.contains('plata soulsilver') ||
        normalized.contains('plata soul silver')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.soulSilver,
        generation: PokemonGeneration.gen4,
        displayName: 'Pokémon SoulSilver',
        memoryMapVerified: false,
        addresses: null,
      );
    }
    if (normalized.contains('diamond') || normalized.contains('diamante')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.diamond,
        generation: PokemonGeneration.gen4,
        displayName: 'Pokémon Diamond',
        memoryMapVerified: false,
        addresses: null,
      );
    }
    if (normalized.contains('pearl') || normalized.contains('perla')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.pearl,
        generation: PokemonGeneration.gen4,
        displayName: 'Pokémon Pearl',
        memoryMapVerified: false,
        addresses: null,
      );
    }

    // Gen III debe resolverse antes que Gen I: "FireRed" también contiene
    // "red" y, sin este orden, podía activar por error el mapa de memoria
    // de Pokémon Red/Blue sobre una ROM de GBA.
    if (normalized.contains('firered') ||
        normalized.contains('fire red') ||
        normalized.contains('rojo fuego')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.fireRed,
        generation: PokemonGeneration.gen3,
        displayName: 'Pokémon FireRed',
        memoryMapVerified: false,
        addresses: null,
      );
    }
    if (normalized.contains('leafgreen') ||
        normalized.contains('leaf green') ||
        normalized.contains('verde hoja')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.leafGreen,
        generation: PokemonGeneration.gen3,
        displayName: 'Pokémon LeafGreen',
        memoryMapVerified: false,
        addresses: null,
      );
    }
    if (normalized.contains('emerald') || normalized.contains('esmeralda')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.emerald,
        generation: PokemonGeneration.gen3,
        displayName: 'Pokémon Emerald',
        memoryMapVerified: false,
        addresses: null,
      );
    }
    if (normalized.contains('sapphire') || normalized.contains('zafiro')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.sapphire,
        generation: PokemonGeneration.gen3,
        displayName: 'Pokémon Sapphire',
        memoryMapVerified: true,
        addresses: null,
      );
    }
    if (normalized.contains('ruby') || normalized.contains('rubi')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.ruby,
        generation: PokemonGeneration.gen3,
        displayName: 'Pokémon Ruby',
        memoryMapVerified: true,
        addresses: null,
      );
    }

    if (normalized.contains('crystal') || normalized.contains('cristal')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.crystal,
        generation: PokemonGeneration.gen2,
        displayName: 'Pokémon Crystal',
        memoryMapVerified: true,
        addresses: PokemonMemoryAddresses.crystal,
      );
    }
    if (normalized.contains('silver') || normalized.contains('plata')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.silver,
        generation: PokemonGeneration.gen2,
        displayName: 'Pokémon Silver',
        memoryMapVerified: true,
        addresses: PokemonMemoryAddresses.goldSilver,
      );
    }
    if (normalized.contains('gold') || normalized.contains('oro')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.gold,
        generation: PokemonGeneration.gen2,
        displayName: 'Pokémon Gold',
        memoryMapVerified: true,
        addresses: PokemonMemoryAddresses.goldSilver,
      );
    }
    if (normalized.contains('yellow') || normalized.contains('amarillo')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.yellow,
        generation: PokemonGeneration.gen1,
        displayName: 'Pokémon Yellow',
        memoryMapVerified: true,
        addresses: PokemonMemoryAddresses.yellow,
      );
    }
    if (normalized.contains('red') ||
        normalized.contains('rojo') ||
        normalized.contains('blue') ||
        normalized.contains('azul')) {
      return const PokemonGameProfile(
        version: PokemonGameVersion.redBlue,
        generation: PokemonGeneration.gen1,
        displayName: 'Pokémon Red/Blue',
        memoryMapVerified: true,
        addresses: PokemonMemoryAddresses.redBlue,
      );
    }
    return const PokemonGameProfile(
      version: PokemonGameVersion.unsupported,
      generation: PokemonGeneration.unsupported,
      displayName: 'Juego no reconocido',
      memoryMapVerified: false,
      addresses: null,
    );
  }

  static PokemonGameProfile fromRomPath(String romPath) {
    return fromGameIdentity(gameTitle: '', romPath: romPath);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .trim();
  }
}
