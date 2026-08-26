import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/pokemon_hatch_cycles.dart';
import '../decoder/pokemon_decoder.dart';
import '../decoder/gen5_ability_data.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';

typedef Gen5SaveRead = List<int> Function(int offset, int length);

/// Lector del guardado de Pokémon Blanco y Negro.
///
/// Gen V divide el guardado principal en bloques con CRC independientes. Los
/// campos usados por la bitácora están en bloques estables del archivo SRAM de
/// 512 KiB, por lo que no se deben tratar como el bloque general de Gen IV.
final class PokemonGen5SaveReader {
  static const int requiredSaveSize = 0x80000;
  static const int _partyOffset = 0x18E00;
  static const int _partyCountOffset = _partyOffset + 4;
  static const int _partyStart = _partyOffset + 8;
  static const int _partyPokemonSize = 0xDC;
  static const int _trainerOffset = 0x19400;
  static const int _positionOffset = 0x19500;
  static const int _miscOffset = 0x21200;
  static const int _eventWorkOffset = 0x20100;
  static const int _eventFlagOffset = _eventWorkOffset + 0x27C;
  static const int _trainerDefeatedFlagStart = 0x550;
  static const int _trainerDefeatedFlagCount = 0xB60 - _trainerDefeatedFlagStart;
  static const int _dexOffset = 0x21600;
  static const int _dexBitBytes = 0x54;
  static const List<String> _blockOrders = <String>[
    'ABCD', 'ABDC', 'ACBD', 'ACDB', 'ADBC', 'ADCB',
    'BACD', 'BADC', 'BCAD', 'BCDA', 'BDAC', 'BDCA',
    'CABD', 'CADB', 'CBAD', 'CBDA', 'CDAB', 'CDBA',
    'DABC', 'DACB', 'DBAC', 'DBCA', 'DCAB', 'DCBA',
  ];

  static String lastDiagnostic = 'Gen V reader not started';
  static String? _lastLoggedDiagnostic;

  static void recordDiagnostic(String value) {
    lastDiagnostic = value;
    if (_lastLoggedDiagnostic == value) return;
    _lastLoggedDiagnostic = value;
    developer.log(value, name: 'RetroHub.Gen5SaveReader');
    debugPrint('[RetroHub.Gen5SaveReader] $value');
  }

  final PokemonGameProfile profile;
  final Gen5SaveRead read;

  const PokemonGen5SaveReader({required this.profile, required this.read});

  PokemonMemorySnapshot? capture() {
    if (profile.version != PokemonGameVersion.black &&
        profile.version != PokemonGameVersion.white) {
      recordDiagnostic('unsupported Gen V layout: ${profile.version.name}');
      return null;
    }

    final List<int> trainer = read(_trainerOffset, 0x68);
    final List<int> position = read(_positionOffset, 0x9C);
    final List<int> misc = read(_miscOffset, 0xEC);
    final List<int> dex = read(_dexOffset, 0x4D4);
    if (trainer.length != 0x68 ||
        position.length != 0x9C ||
        misc.length != 0xEC ||
        dex.length != 0x4D4) {
      recordDiagnostic('incomplete Gen V save blocks');
      return null;
    }

    final String playerName = _decodeString(trainer, 4, 8);
    if (playerName.isEmpty) {
      recordDiagnostic('empty Gen V player name');
      return null;
    }

    final List<int> countBytes = read(_partyCountOffset, 1);
    if (countBytes.isEmpty || countBytes.first > 6) {
      recordDiagnostic('invalid Gen V party count');
      return null;
    }
    final int count = countBytes.first;
    final List<PokemonPartyMember> party = <PokemonPartyMember>[];
    for (int slot = 0; slot < count; slot++) {
      final List<int> encrypted = read(
        _partyStart + slot * _partyPokemonSize,
        _partyPokemonSize,
      );
      final PokemonPartyMember? member = _decodePartyPokemon(encrypted);
      if (member != null) party.add(member);
    }

    final List<int> caught = _dexIds(dex, 0x08);
    final Set<int> seenSet = <int>{};
    for (int region = 0; region < 4; region++) {
      seenSet.addAll(_dexIds(dex, 0x5C + region * _dexBitBytes));
    }
    final List<int> seen = seenSet.toList()..sort();
    final int packedDexFlags = _u32(dex, 4);
    final List<int> defeatedTrainers = _defeatedTrainerIds();

    recordDiagnostic(
      'SAVE_RAM=$requiredSaveSize bytes, BW blocks valid, '
      'party=$count, decoded=${party.length}, seen=${seen.length}, '
      'caught=${caught.length}, defeatedTrainers=${defeatedTrainers.length}',
    );

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      memoryShift: 0,
      playerName: playerName,
      trainerId: _u16(trainer, 0x14),
      isFemale: trainer[0x21] == 1,
      currentMapId: _u32(position, 0x80),
      playerX: _u16(position, 0x86),
      playerY: _u16(position, 0x8E),
      money: _u32(misc, 0),
      badgesMask: misc[4],
      pokedexSeen: seen.length,
      pokedexCaught: caught.length,
      nationalDexUnlocked: (packedDexFlags & 1) != 0,
      seenPokemonIds: seen,
      caughtPokemonIds: caught,
      party: party,
      defeatedTrainerIds: defeatedTrainers,
      gamePlayTimeMinutes: _u16(trainer, 0x24) * 60 + trainer[0x26],
    );
  }

  List<int> _defeatedTrainerIds() {
    final List<int> flags = read(_eventFlagOffset, 0xB60 ~/ 8);
    if (flags.length != 0xB60 ~/ 8) return const <int>[];
    final List<int> result = <int>[];
    for (int trainerId = 1; trainerId < _trainerDefeatedFlagCount; trainerId++) {
      final int flag = _trainerDefeatedFlagStart + trainerId;
      if ((flags[flag >> 3] & (1 << (flag & 7))) != 0) result.add(trainerId);
    }
    return result;
  }

  static PokemonPartyMember? _decodePartyPokemon(List<int> encrypted) {
    if (encrypted.length != _partyPokemonSize) return null;
    final int personality = _u32(encrypted, 0);
    final int storedChecksum = _u16(encrypted, 6);
    final List<int> data = _cryptWords(encrypted.sublist(8, 0x88), storedChecksum);
    int checksum = 0;
    for (int offset = 0; offset < data.length; offset += 2) {
      checksum = (checksum + _u16(data, offset)) & 0xFFFF;
    }
    if (checksum != storedChecksum) return null;

    final String order = _blockOrders[((personality & 0x3E000) >> 13) % 24];
    final int growth = order.indexOf('A') * 32;
    final int attacks = order.indexOf('B') * 32;
    final int species = _u16(data, growth);
    if (species <= 0 || species > 649) return null;

    final int originalTrainerId = _u32(data, growth + 4);
    final int friendship = data[growth + 0x0C];
    final int ivFlags = _u32(data, attacks + 0x10);
    final bool isEgg = (ivFlags & (1 << 30)) != 0;
    final int abilityId = data[growth + 0x0D];
    final List<int> speciesAbilities =
        gen5SpeciesAbilities[species] ?? const <int>[];
    final int abilityIndex = speciesAbilities.indexOf(abilityId);
    final List<int> stats = _cryptWords(encrypted.sublist(0x88), personality);
    final int level = stats[4];
    if (level <= 0 || level > 100) return null;

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
      experience: _u32(data, growth + 8),
      moveIds: <int>[
        for (int index = 0; index < 4; index++) _u16(data, attacks + index * 2),
      ].where((int move) => move > 0).toList(growable: false),
      attack: _u16(stats, 10),
      defense: _u16(stats, 12),
      speed: _u16(stats, 14),
      specialAttack: _u16(stats, 16),
      specialDefense: _u16(stats, 18),
      abilitySlot: abilityIndex >= 0 ? abilityIndex + 1 : 1,
      personality: personality,
      heldItemId: _u16(data, growth + 2),
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

  static List<int> _dexIds(List<int> bytes, int offset) {
    final List<int> result = <int>[];
    for (int id = 1; id <= 649; id++) {
      final int bit = id - 1;
      if ((bytes[offset + (bit >> 3)] & (1 << (bit & 7))) != 0) result.add(id);
    }
    return result;
  }

  static String _decodeString(List<int> bytes, int offset, int maximum) {
    final List<int> glyphs = <int>[];
    for (int index = 0; index < maximum; index++) {
      final int value = _u16(bytes, offset + index * 2);
      if (value == 0 || value == 0xFFFF) break;
      glyphs.add(value);
    }
    return String.fromCharCodes(glyphs)
        .replaceAll(String.fromCharCode(0x246D), '♂')
        .replaceAll(String.fromCharCode(0x246E), '♀')
        .trim();
  }

  static int _u16(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);
  static int _u32(List<int> bytes, int offset) =>
      _u16(bytes, offset) | (_u16(bytes, offset + 2) << 16);
}
