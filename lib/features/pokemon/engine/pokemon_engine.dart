import '../../emulator/data/libretro_bridge.dart';
import '../../game_engine/game_engine.dart';
import '../../game_engine/game_engine_status.dart';
import '../memory/pokemon_memory_reader.dart';
import '../memory/pokemon_memory_profile_resolver.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';

class PokemonEngine implements GameEngine<PokemonMemorySnapshot> {
  final LibretroBridge bridge;
  final PokemonGameProfile profile;

  PokemonEngine({
    required this.bridge,
    required String gameTitle,
    required String romPath,
  }) : profile = PokemonGameProfile.fromGameIdentity(
          gameTitle: gameTitle,
          romPath: romPath,
        );

  @override
  String get engineName => 'Pokémon Engine';

  @override
  String get gameName => profile.displayName;

  @override
  bool get isSupported => profile.memoryMapVerified;

  @override
  PokemonMemorySnapshot? capture() {
    if (!isSupported) return null;
    return PokemonMemoryReader(bridge: bridge, profile: profile).capture();
  }

  GameEngineStatus<PokemonMemorySnapshot> readStatus() {
    final int systemRamSize = bridge.memoryRegionSize(
      LibretroMemoryRegion.systemRam,
    );

    if (systemRamSize <= 0) {
      return GameEngineStatus<PokemonMemorySnapshot>(
        state: GameEngineState.waitingForMemory,
        engineName: engineName,
        gameName: gameName,
        systemRamSize: systemRamSize,
        snapshot: null,
        message: 'La memoria del juego todavía no está disponible.',
      );
    }

    if (!isSupported) {
      return GameEngineStatus<PokemonMemorySnapshot>(
        state: GameEngineState.unsupported,
        engineName: engineName,
        gameName: gameName,
        systemRamSize: systemRamSize,
        snapshot: null,
        message: 'Este juego todavía no tiene un perfil de memoria.',
      );
    }

    try {
      final snapshot = capture();
      if (snapshot == null) {
        return GameEngineStatus<PokemonMemorySnapshot>(
          state: GameEngineState.readError,
          engineName: engineName,
          gameName: gameName,
          systemRamSize: systemRamSize,
          snapshot: null,
          message: PokemonMemoryProfileResolver.lastDiagnostic,
        );
      }
      return GameEngineStatus<PokemonMemorySnapshot>(
        state: GameEngineState.ready,
        engineName: engineName,
        gameName: gameName,
        systemRamSize: systemRamSize,
        snapshot: snapshot,
      );
    } catch (error) {
      return GameEngineStatus<PokemonMemorySnapshot>(
        state: GameEngineState.readError,
        engineName: engineName,
        gameName: gameName,
        systemRamSize: systemRamSize,
        snapshot: null,
        message: error.toString(),
      );
    }
  }

  @override
  void dispose() {}
}
