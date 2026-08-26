import 'dart:developer' as developer;

import '../data/pokemon_hatch_cycles.dart';
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
  static const int _partyPokemonSize = 0xEC;
  static const List<String> _blockOrders = <String>[
    'ABCD', 'ABDC', 'ACBD', 'ACDB', 'ADBC', 'ADCB',
    'BACD', 'BADC', 'BCAD', 'BCDA', 'BDAC', 'BDCA',
    'CABD', 'CADB', 'CBAD', 'CBDA', 'CDAB', 'CDBA',
    'DABC', 'DACB', 'DBAC', 'DBCA', 'DCAB', 'DCBA',
  ];
  static String lastDiagnostic = 'Gen IV reader not started';
  static String? _lastLoggedDiagnostic;
  static String? _lastPartyDecodeError;

  static void recordDiagnostic(String value) {
    lastDiagnostic = value;
    if (_lastLoggedDiagnostic == value) return;
    _lastLoggedDiagnostic = value;
    developer.log(value, name: 'RetroHub.Gen4SaveReader');
  }

  final PokemonGameProfile profile;
  final Gen4SaveRead read;

  const PokemonGen4SaveReader({required this.profile, required this.read});

  PokemonMemorySnapshot? capture() {
    final _Gen4Layout? layout = _Gen4Layout.forVersion(profile.version);
    if (layout == null) {
      recordDiagnostic('unsupported Gen IV layout: ${profile.version.name}');
      return null;
    }

    final int primaryFooter = layout.generalSize - 0x14;
    final int backupFooter = _partitionSize + primaryFooter;
    final List<int> primary = read(primaryFooter, 8);
    final List<int> backup = read(backupFooter, 8);
    if (primary.length != 8 || backup.length != 8) {
      recordDiagnostic(
        'footer read failed: primary=${primary.length}, backup=${backup.length}',
      );
      return null;
    }

    final int blockBase = _newerBlock(primary, backup) == 0
        ? 0
        : _partitionSize;
    final List<int> general = read(blockBase, layout.generalSize);
    if (general.length != layout.generalSize) {
      recordDiagnostic(
        'general block read failed: ${general.length}/${layout.generalSize}',
      );
      return null;
    }

    final int magic = _u32(general, layout.generalSize - 8);
    if (magic != 0x20060623 && magic != 0x20070903) {
      recordDiagnostic(
        'invalid general block magic: 0x${magic.toRadixString(16)}',
      );
      return null;
    }

    final String playerName = _decodeUtf16(
      general,
      layout.trainerOffset,
      8,
    );
    if (playerName.isEmpty) {
      recordDiagnostic('empty player name');
      return null;
    }

    final int progressFlags = general[layout.trainerOffset + 0x1D];
    final List<int> caught = _dexIds(general, layout.dexOffset + 4);
    final List<int> seen = _dexIds(
      general,
      layout.dexOffset + 4 + _dexRegionSize,
    );
    _lastPartyDecodeError = null;
    final List<PokemonPartyMember> party = _readParty(general, layout);
    final int declaredPartyCount = _u32(general, layout.partyOffset);
    recordDiagnostic(
      'SAVE_RAM=${requiredSaveSize} bytes, block=0x${blockBase.toRadixString(16)}, '
      'party=$declaredPartyCount, decoded=${party.length}'
      '${_lastPartyDecodeError == null ? '' : ', error=$_lastPartyDecodeError'}',
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
      party: party,
      gamePlayTimeMinutes:
          _u16(general, layout.trainerOffset + 0x22) * 60 +
          general[layout.trainerOffset + 0x24],
    );
  }

  static List<PokemonPartyMember> _readParty(
    List<int> general,
    _Gen4Layout layout,
  ) {
    final int count = _u32(general, layout.partyOffset);
    if (count < 0 || count > 6) {
      recordDiagnostic('invalid party count: $count');
      return const <PokemonPartyMember>[];
    }

    final List<PokemonPartyMember> party = <PokemonPartyMember>[];
    final int pokemonStart = layout.partyOffset + 4;
    for (int slot = 0; slot < count; slot++) {
      final int offset = pokemonStart + slot * _partyPokemonSize;
      if (offset + _partyPokemonSize > general.length) break;
      final PokemonPartyMember? pokemon = _decodePartyPokemon(
        general.sublist(offset, offset + _partyPokemonSize),
      );
      if (pokemon != null) party.add(pokemon);
    }
    return party;
  }

  static PokemonPartyMember? _decodePartyPokemon(List<int> encrypted) {
    if (encrypted.length != _partyPokemonSize) {
      _lastPartyDecodeError =
          'invalid structure length ${encrypted.length}/$_partyPokemonSize';
      return null;
    }

    final int personality = _u32(encrypted, 0);
    final int storedChecksum = _u16(encrypted, 6);
    final List<int> data = _cryptWords(
      encrypted.sublist(8, 0x88),
      storedChecksum,
    );

    int checksum = 0;
    for (int offset = 0; offset < data.length; offset += 2) {
      checksum = (checksum + _u16(data, offset)) & 0xFFFF;
    }
    if (checksum != storedChecksum) {
      _lastPartyDecodeError =
          'checksum ${checksum.toRadixString(16)}/${storedChecksum.toRadixString(16)}';
      return null;
    }

    final int shuffle = ((personality & 0x3E000) >> 13) % 24;
    final String order = _blockOrders[shuffle];
    final int growth = order.indexOf('A') * 32;
    final int attacks = order.indexOf('B') * 32;
    final int species = _u16(data, growth);
    if (species <= 0 || species > 493) {
      _lastPartyDecodeError = 'invalid species $species';
      return null;
    }

    final int heldItem = _u16(data, growth + 2);
    final int originalTrainerId = _u32(data, growth + 4);
    final int experience = _u32(data, growth + 8);
    final int friendship = data[growth + 0x0C];
    final int ivFlags = _u32(data, attacks + 0x10);
    final bool isEgg = (ivFlags & (1 << 30)) != 0;
    final List<int> moves = <int>[
      for (int index = 0; index < 4; index++)
        _u16(data, attacks + index * 2),
    ].where((int move) => move > 0).toList(growable: false);

    // Los datos de combate que siguen al BoxPokemon usan el PID como semilla
    // y un segundo flujo del mismo LCRNG.
    final List<int> stats = _cryptWords(encrypted.sublist(0x88), personality);
    final int level = stats[4];
    if (level <= 0 || level > 100) {
      _lastPartyDecodeError = 'invalid level $level for species $species';
      return null;
    }

    final int shinyValue =
        (originalTrainerId & 0xFFFF) ^
        (originalTrainerId >> 16) ^
        (personality & 0xFFFF) ^
        (personality >> 16);
    final int? eggCyclesTotal = isEgg
        ? hatchCyclesForPokedexId(species) ?? friendship
        : null;

    return PokemonPartyMember(
      internalSpeciesId: species,
      pokedexId: species,
      name: PokemonDecoder.pokemonName(species),
      level: isEgg ? 0 : level,
      isShiny: shinyValue < 8,
      isEgg: isEgg,
      currentHp: _u16(stats, 6),
      maximumHp: _u16(stats, 8),
      status: _u32(stats, 0),
      friendship: isEgg ? null : friendship,
      experience: experience,
      moveIds: moves,
      attack: _u16(stats, 10),
      defense: _u16(stats, 12),
      speed: _u16(stats, 14),
      specialAttack: _u16(stats, 16),
      specialDefense: _u16(stats, 18),
      abilitySlot: (personality & 1) + 1,
      personality: personality,
      heldItemId: heldItem,
      eggCyclesRemaining: isEgg ? friendship : null,
      eggCyclesTotal: eggCyclesTotal,
    );
  }

  static List<int> _cryptWords(List<int> source, int initialSeed) {
    final List<int> result = List<int>.from(source);
    int seed = initialSeed & 0xFFFFFFFF;
    for (int offset = 0; offset + 1 < result.length; offset += 2) {
      seed = (seed * 0x41C64E6D + 0x6073) & 0xFFFFFFFF;
      final int value = _u16(result, offset) ^ (seed >> 16);
      result[offset] = value & 0xFF;
      result[offset + 1] = value >> 8;
    }
    return result;
  }

  static int _newerBlock(List<int> first, List<int> second) {
    final bool firstErased = first.every((int value) => value == 0xFF);
    final bool secondErased = second.every((int value) => value == 0xFF);
    if (firstErased != secondErased) return firstErased ? 1 : 0;

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
  final int partyOffset;
  final int mapOffset;
  final int xOffset;
  final int yOffset;

  const _Gen4Layout({
    required this.generalSize,
    required this.trainerOffset,
    required this.dexOffset,
    required this.partyOffset,
    required this.mapOffset,
    required this.xOffset,
    required this.yOffset,
  });

  static _Gen4Layout? forVersion(PokemonGameVersion version) => switch (version) {
    PokemonGameVersion.diamond || PokemonGameVersion.pearl => const _Gen4Layout(
      generalSize: 0xC100,
      trainerOffset: 0x64,
      dexOffset: 0x12DC,
      partyOffset: 0x98,
      mapOffset: 0x1238,
      xOffset: 0x1240,
      yOffset: 0x1244,
    ),
    PokemonGameVersion.platinum => const _Gen4Layout(
      generalSize: 0xCF2C,
      trainerOffset: 0x68,
      dexOffset: 0x1328,
      partyOffset: 0x9C,
      mapOffset: 0x1280,
      xOffset: 0x1288,
      yOffset: 0x128C,
    ),
    _ => null,
  };
}
