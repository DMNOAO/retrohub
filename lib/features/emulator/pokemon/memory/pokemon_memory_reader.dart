import '../../data/libretro_bridge.dart';
import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';
import 'pokemon_memory_profile_resolver.dart';

class PokemonMemoryReader {
  final LibretroBridge bridge;
  final PokemonGameProfile profile;

  const PokemonMemoryReader({required this.bridge, required this.profile});

  PokemonMemorySnapshot? capture() {
    if (!profile.memoryMapVerified || profile.addresses == null) return null;

    List<int> read(int offset, int length) => bridge.readMemoryBlock(
          memoryId: LibretroMemoryRegion.systemRam,
          offset: offset,
          length: length,
        );

    final resolved = PokemonMemoryProfileResolver.resolve(
      profile: profile,
      read: read,
    );
    if (resolved == null) return null;
    final addresses = resolved.addresses;

    int byte(int offset) {
      final values = read(offset, 1);
      return values.isEmpty ? 0 : values.first;
    }

    int word(int offset) {
      final values = read(offset, 2);
      return values.length < 2 ? 0 : (values[0] << 8) | values[1];
    }

    final count = byte(addresses.partyCount);
    final species = read(addresses.partySpecies, 7);
    final name = PokemonGen1Decoder.decodePlayerName(
      read(addresses.playerName, 11),
    );

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      playerName: name,
      trainerId: word(addresses.playerId),
      currentMapId: byte(addresses.currentMap),
      playerX: byte(addresses.playerX),
      playerY: byte(addresses.playerY),
      money: PokemonGen1Decoder.decodeBcd(read(addresses.playerMoney, 3)),
      badgesMask: byte(addresses.obtainedBadges),
      partySpeciesIds: species.take(count).toList(growable: false),
    );
  }
}
