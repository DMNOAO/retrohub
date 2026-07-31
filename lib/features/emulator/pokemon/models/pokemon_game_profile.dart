import '../memory/pokemon_addresses.dart';

enum PokemonGeneration { gen1, gen2, unsupported }

enum PokemonGameVersion {
  redBlue,
  yellow,
  gold,
  silver,
  crystal,
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

  static PokemonGameProfile fromRomPath(String romPath) {
    final normalized = romPath.toLowerCase();

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
    if (normalized.contains('red') || normalized.contains('rojo') ||
        normalized.contains('blue') || normalized.contains('azul')) {
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
}
