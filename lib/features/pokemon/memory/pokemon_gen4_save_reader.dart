import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';

typedef Gen4SaveRead = List<int> Function(int offset, int length);

/// Reads the active Gen IV general-save block exposed by melonDS as SRAM.
///
/// Diamante/Perla and Platino share the same logical fields, but use
/// different block sizes and offsets. Keeping those values in [_Gen4Layout]
/// lets the journal model remain common while preserving version differences.
final class PokemonGen4SaveReader {
  static const int requiredSaveSize = 0x80000;
  static const int _partitionSize = 0x40000;
  static const int _dexRegionSize = 0x40;

  final PokemonGameProfile profile;
  final Gen4SaveRead read;

  const PokemonGen4SaveReader({required this.profile, required this.read});

  PokemonMemorySnapshot? capture() {
    final _Gen4Layout? layout = _Gen4Layout.forVersion(profile.version);
    if (layout == null) return null;

    final int primaryFooter = layout.generalSize - 0x14;
    final int backupFooter = _partitionSize + primaryFooter;
    final List<int> primary = read(primaryFooter, 8);
    final List<int> backup = read(backupFooter, 8);
    if (primary.length != 8 || backup.length != 8) return null;

    final int blockBase = _newerBlock(primary, backup) == 0
        ? 0
        : _partitionSize;
    final List<int> general = read(blockBase, layout.generalSize);
    if (general.length != layout.generalSize) return null;

    final int magic = _u32(general, layout.generalSize - 8);
    if (magic != 0x20060623 && magic != 0x20070903) return null;

    final String playerName = _decodeUtf16(
      general,
      layout.trainerOffset,
      8,
    );
    if (playerName.isEmpty) return null;

    final int progressFlags = general[layout.trainerOffset + 0x1D];
    final List<int> caught = _dexIds(general, layout.dexOffset + 4);
    final List<int> seen = _dexIds(
      general,
      layout.dexOffset + 4 + _dexRegionSize,
    );

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      memoryShift: blockBase,
      playerName: playerName,
      trainerId: _u16(general, layout.trainerOffset + 0x10),
      currentMapId: _u16(general, layout.mapOffset),
      playerX: _u16(general, layout.xOffset),
      playerY: _u16(general, layout.yOffset),
      money: _u32(general, layout.trainerOffset + 0x14),
      badgesMask: general[layout.trainerOffset + 0x1A],
      pokedexSeen: seen.length,
      pokedexCaught: caught.length,
      nationalDexUnlocked: (progressFlags & 0x02) != 0,
      seenPokemonIds: seen,
      caughtPokemonIds: caught,
      // Party Pokémon are encrypted in Gen IV. They are intentionally added
      // in the next phase rather than exposing partially decoded data.
      party: const <PokemonPartyMember>[],
      gamePlayTimeMinutes:
          _u16(general, layout.trainerOffset + 0x22) * 60 +
          general[layout.trainerOffset + 0x24],
    );
  }

  static int _newerBlock(List<int> first, List<int> second) {
    final int firstMajor = _u32(first, 0);
    final int secondMajor = _u32(second, 0);
    if (firstMajor != secondMajor) return firstMajor > secondMajor ? 0 : 1;
    final int firstMinor = _u32(first, 4);
    final int secondMinor = _u32(second, 4);
    return firstMinor >= secondMinor ? 0 : 1;
  }

  static List<int> _dexIds(List<int> bytes, int offset) {
    final List<int> result = <int>[];
    for (int id = 1; id <= 493; id++) {
      final int bit = id - 1;
      if ((bytes[offset + (bit >> 3)] & (1 << (bit & 7))) != 0) {
        result.add(id);
      }
    }
    return result;
  }

  static String _decodeUtf16(
    List<int> bytes,
    int offset,
    int maximumCharacters,
  ) {
    final List<int> codeUnits = <int>[];
    for (int index = 0; index < maximumCharacters; index++) {
      final int value = _u16(bytes, offset + index * 2);
      if (value == 0 || value == 0xFFFF) break;
      codeUnits.add(value);
    }
    return String.fromCharCodes(codeUnits).trim();
  }

  static int _u16(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  static int _u32(List<int> bytes, int offset) =>
      _u16(bytes, offset) | (_u16(bytes, offset + 2) << 16);
}

final class _Gen4Layout {
  final int generalSize;
  final int trainerOffset;
  final int dexOffset;
  final int mapOffset;
  final int xOffset;
  final int yOffset;

  const _Gen4Layout({
    required this.generalSize,
    required this.trainerOffset,
    required this.dexOffset,
    required this.mapOffset,
    required this.xOffset,
    required this.yOffset,
  });

  static _Gen4Layout? forVersion(PokemonGameVersion version) => switch (version) {
    PokemonGameVersion.diamond || PokemonGameVersion.pearl => const _Gen4Layout(
      generalSize: 0xC100,
      trainerOffset: 0x64,
      dexOffset: 0x12DC,
      mapOffset: 0x1238,
      xOffset: 0x1240,
      yOffset: 0x1244,
    ),
    PokemonGameVersion.platinum => const _Gen4Layout(
      generalSize: 0xCF2C,
      trainerOffset: 0x68,
      dexOffset: 0x1328,
      mapOffset: 0x1280,
      xOffset: 0x1288,
      yOffset: 0x128C,
    ),
    _ => null,
  };
}
