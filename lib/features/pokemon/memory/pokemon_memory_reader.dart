import '../../emulator/data/libretro_bridge.dart';
import '../data/pokemon_hatch_cycles.dart';
import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';
import 'pokemon_addresses.dart';
import 'pokemon_controller_memory_reader.dart';
import 'pokemon_memory_profile_resolver.dart';

class PokemonMemoryReader {
  final LibretroBridge bridge;
  final PokemonGameProfile profile;

  const PokemonMemoryReader({required this.bridge, required this.profile});

  PokemonMemorySnapshot? capture() {
    if (profile.isGen2) {
      final int size = bridge.memoryRegionSize(LibretroMemoryRegion.rtc);
      RuntimeDiagnosticsLog.recordRtc(
        size <= 0
            ? const <int>[]
            : bridge.readMemoryBlock(
                memoryId: LibretroMemoryRegion.rtc,
                offset: 0,
                length: size,
              ),
      );
    }
    return _capture(
      (int offset, int length) => bridge.readMemoryBlock(
        memoryId: LibretroMemoryRegion.systemRam,
        offset: offset,
        length: length,
      ),
    );
  }

  PokemonMemorySnapshot? _capture(
    List<int> Function(int offset, int length) read,
  ) {
    if (!profile.memoryMapVerified || profile.addresses == null) return null;

    final ResolvedPokemonMemoryProfile? resolved =
        PokemonMemoryProfileResolver.resolve(profile: profile, read: read);
    if (resolved == null) return null;

    final PokemonMemoryAddresses a = resolved.addresses;

    int byte(int offset) {
      final List<int> values = read(offset, 1);
      return values.isEmpty ? 0 : values.first;
    }

    int word(int offset) {
      final List<int> values = read(offset, 2);
      return values.length < 2 ? 0 : (values[0] << 8) | values[1];
    }

    final int count = byte(a.partyCount);
    final List<int> species = read(a.partySpecies, 7);
    final List<PokemonPartyMember> party = <PokemonPartyMember>[];

    for (int i = 0; i < count && i < species.length; i++) {
      final int id = species[i];
      final bool isEgg = profile.isGen2 && id == 0xFD;
      final List<int> mon = read(
        a.partyMons + i * a.partyStructLength,
        a.partyStructLength,
      );
      if (mon.length != a.partyStructLength) continue;
      final int internalSpeciesId = isEgg ? mon[0] : id;
      final int dex = PokemonDecoder.dexId(profile, internalSpeciesId);

      bool shiny = false;
      if (!isEgg &&
          profile.isGen2 &&
          a.partyDvOffset != null &&
          mon.length > a.partyDvOffset! + 1) {
        shiny = PokemonDecoder.isGen2Shiny(
          mon[a.partyDvOffset!],
          mon[a.partyDvOffset! + 1],
        );
      }

      final int level = isEgg
          ? 0
          : (a.partyLevelOffset < mon.length ? mon[a.partyLevelOffset] : 0);
      // En Gen II el byte 27 es felicidad para un Pokémon normal y ciclos
      // restantes para un huevo.
      final int? friendship = profile.isGen2 && !isEgg && mon.length > 27
          ? mon[27]
          : null;
      final int? eggCyclesRemaining = profile.isGen2 && isEgg && mon.length > 27
          ? mon[27]
          : null;
      final int? eggCyclesTotal = eggCyclesRemaining == null
          ? null
          : hatchCyclesForPokedexId(dex) ?? eggCyclesRemaining;

      party.add(
        PokemonPartyMember(
          internalSpeciesId: internalSpeciesId,
          pokedexId: dex,
          name: isEgg ? 'Huevo' : PokemonDecoder.pokemonName(dex),
          level: level,
          isShiny: shiny,
          isEgg: isEgg,
          friendship: friendship,
          eggCyclesRemaining: eggCyclesRemaining,
          eggCyclesTotal: eggCyclesTotal,
        ),
      );
    }

    final int map = profile.isGen2 && a.currentMapGroup != null
        ? (byte(a.currentMapGroup!) << 8) | byte(a.currentMap)
        : byte(a.currentMap);

    final int johtoBadges = byte(a.obtainedBadges);
    final int badges =
        johtoBadges | ((a.kantoBadges == null ? 0 : byte(a.kantoBadges!)) << 8);

    final List<int> moneyBytes = read(a.playerMoney, 3);
    final int money = profile.isGen2
        ? PokemonDecoder.decodeUnsignedBigEndian(moneyBytes)
        : _safeBcd(moneyBytes);

    final int? battleState = a.battleMode != null
        ? byte(a.battleMode!)
        : (a.isInBattle != null ? byte(a.isInBattle!) : null);
    final int? otherTrainerClassId = a.otherTrainerClass != null
        ? byte(a.otherTrainerClass!)
        : null;
    final int? otherTrainerIdValue = a.otherTrainerId != null
        ? byte(a.otherTrainerId!)
        : null;
    final int? battleResultRaw = a.battleResult != null
        ? byte(a.battleResult!)
        : null;

    final List<int> seenBytes = read(a.pokedexSeen, a.pokedexBytes);
    final List<int> caughtBytes = read(a.pokedexOwned, a.pokedexBytes);

    List<int> decodedDexIds(List<int> bytes) {
      final result = <int>[];
      final maximum = profile.isGen2 ? 251 : 151;
      for (var byteIndex = 0; byteIndex < bytes.length; byteIndex++) {
        for (var bit = 0; bit < 8; bit++) {
          final dexId = byteIndex * 8 + bit + 1;
          if (dexId <= maximum && (bytes[byteIndex] & (1 << bit)) != 0) {
            result.add(dexId);
          }
        }
      }
      return result;
    }

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      memoryShift: resolved.shift,
      playerName: PokemonDecoder.decodeText(
        read(a.playerName, a.playerNameLength),
      ),
      trainerId: word(a.playerId),
      currentMapId: map,
      playerX: byte(a.playerX),
      playerY: byte(a.playerY),
      money: money,
      badgesMask: badges,
      pokedexSeen: PokemonDecoder.countBits(seenBytes),
      pokedexCaught: PokemonDecoder.countBits(caughtBytes),
      seenPokemonIds: decodedDexIds(seenBytes),
      caughtPokemonIds: decodedDexIds(caughtBytes),
      party: party,
      battleState: battleState,
      otherTrainerClassId: otherTrainerClassId,
      otherTrainerId: otherTrainerIdValue,
      battleResultRaw: battleResultRaw,
    );
  }

  int _safeBcd(List<int> bytes) {
    final int value = PokemonDecoder.decodeBcd(bytes);
    return value < 0 ? 0 : value;
  }
}
