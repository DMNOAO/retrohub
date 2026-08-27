import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/pokemon_hatch_cycles.dart';
import '../decoder/pokemon_decoder.dart';
import '../decoder/gen5_ability_data.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';

typedef Gen5SaveRead = List<int> Function(int offset, int length);

/// Lector del guardado de Pokémon Blanco/Negro y Blanco 2/Negro 2.
///
/// Gen V divide el guardado principal en bloques con CRC independientes. Los
/// campos usados por la bitácora están en bloques estables del archivo SRAM de
/// 512 KiB, por lo que no se deben tratar como el bloque general de Gen IV.
final class PokemonGen5SaveReader {
  static const int requiredSaveSize = 0x80000;
  static const int _partyPokemonSize = 0xDC;
  static const int _trainerDefeatedFlagStart = 0x550;
  static const int _dexBitBytes = 0x54;
  // PlayerSaveData documentado por Swan para B2W2. PlaceNameZoneID se conserva
  // en el diagnóstico, pero PKSM valida empíricamente que el Map ID persistido
  // para la posición está en 0x80 y las coordenadas en 0x86/0x8E.
  static const int _placeNameZoneIdOffset = 0x76;
  static const int _zoneIdOffset = 0x80;
  static const List<String> _blockOrders = <String>[
    'ABCD', 'ABDC', 'ACBD', 'ACDB', 'ADBC', 'ADCB',
    'BACD', 'BADC', 'BCAD', 'BCDA', 'BDAC', 'BDCA',
    'CABD', 'CADB', 'CBAD', 'CBDA', 'CDAB', 'CDBA',
    'DABC', 'DACB', 'DBAC', 'DBCA', 'DCAB', 'DCBA',
  ];

  static String lastDiagnostic = 'Gen V reader not started';
  static String? _lastLoggedDiagnostic;
  static final Map<PokemonGameVersion, Set<int>> _lastEventWorkFlags =
      <PokemonGameVersion, Set<int>>{};

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
    final _Gen5SaveLayout? layout = _Gen5SaveLayout.forVersion(profile.version);
    if (layout == null) {
      recordDiagnostic('unsupported Gen V layout: ${profile.version.name}');
      return null;
    }

    final List<int> trainer = read(layout.trainerOffset, layout.trainerLength);
    final List<int> position = read(layout.positionOffset, layout.positionLength);
    final List<int> misc = read(layout.miscOffset, layout.miscLength);
    final List<int> dex = read(layout.dexOffset, layout.dexLength);
    if (trainer.length != layout.trainerLength ||
        position.length != layout.positionLength ||
        misc.length != layout.miscLength ||
        dex.length != layout.dexLength) {
      recordDiagnostic('incomplete Gen V save blocks');
      return null;
    }

    final String playerName = _decodeString(trainer, 4, 8);
    if (playerName.isEmpty) {
      recordDiagnostic('empty Gen V player name');
      return null;
    }

    final List<int> countBytes = read(layout.partyOffset + 4, 1);
    if (countBytes.isEmpty || countBytes.first > 6) {
      recordDiagnostic('invalid Gen V party count');
      return null;
    }
    final int count = countBytes.first;
    final List<PokemonPartyMember> party = <PokemonPartyMember>[];
    for (int slot = 0; slot < count; slot++) {
      final List<int> encrypted = read(
        layout.partyOffset + 8 + slot * _partyPokemonSize,
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
    if (!layout.hasVerifiedTrainerFlags) {
      _recordEventWorkChanges(layout);
    }
    final List<int> defeatedTrainers = _changedTrainerFlagIds(layout);
    final List<List<int>> badgeTeams = layout.hasBadgeTeams
        ? _decodeBadgeTeams(misc)
        : const <List<int>>[];
    final List<int> hallOfFameSpeciesIds = layout.hallOfFameOffset == null
        ? const <int>[]
        : _decodeHallOfFameSpecies(
            read(layout.hallOfFameOffset!, layout.hallOfFameLength),
          );
    final int placeNameZoneId = layout.hasPlaceNameZoneId
        ? _u16(position, _placeNameZoneIdOffset)
        : _u32(position, _zoneIdOffset);
    final int zoneId = _u32(position, _zoneIdOffset);
    final int playerX = _u16(position, 0x86);
    final int playerY = _u16(position, 0x8E);

    recordDiagnostic(
      'SAVE_RAM=$requiredSaveSize bytes, ${layout.label} blocks valid, '
      'party=$count, decoded=${party.length}, seen=${seen.length}, '
      'caught=${caught.length}, placeNameZone=$placeNameZoneId, zone=$zoneId, '
      'position=($playerX,$playerY), '
      'money=${_u32(misc, 0)}, badges=0x${misc[4].toRadixString(16)}, '
      'badgeTeams=${badgeTeams.where((team) => team.isNotEmpty).length}, '
      'hallOfFame=${hallOfFameSpeciesIds.length}, '
      'defeatedTrainers=${defeatedTrainers.length}',
    );

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      memoryShift: 0,
      playerName: playerName,
      trainerId: _u16(trainer, 0x14),
      isFemale: trainer[0x21] == 1,
      currentMapId: zoneId,
      playerX: playerX,
      playerY: playerY,
      money: _u32(misc, 0),
      badgesMask: misc[4],
      pokedexSeen: seen.length,
      pokedexCaught: caught.length,
      nationalDexUnlocked: (packedDexFlags & 1) != 0,
      seenPokemonIds: seen,
      caughtPokemonIds: caught,
      party: party,
      badgeTeams: badgeTeams,
      hallOfFameSpeciesIds: hallOfFameSpeciesIds,
      leagueWins: hallOfFameSpeciesIds.isEmpty ? 0 : 1,
      defeatedTrainerIds: defeatedTrainers,
      gamePlayTimeMinutes: _u16(trainer, 0x24) * 60 + trainer[0x26],
    );
  }

  /// B2W2 usa EventWork para las victorias, pero todavía no conocemos qué
  /// índices corresponden a TrainerFlag. Registrar únicamente las transiciones
  /// permite obtener esa tabla de una partida real sin convertir flags de
  /// historia, diálogos o objetos en falsos combates de la bitácora.
  void _recordEventWorkChanges(_Gen5SaveLayout layout) {
    final int byteCount = layout.eventFlagCount ~/ 8;
    final List<int> flags = read(layout.eventFlagOffset, byteCount);
    if (flags.length != byteCount) return;
    final current = <int>{};
    for (int flag = 0; flag < layout.eventFlagCount; flag++) {
      if ((flags[flag >> 3] & (1 << (flag & 7))) != 0) current.add(flag);
    }
    final previous = _lastEventWorkFlags[profile.version];
    _lastEventWorkFlags[profile.version] = current;
    if (previous == null) {
      debugPrint(
        '[RetroHub.Gen5Battle] EventWork baseline: ${current.length} flags set',
      );
      return;
    }
    final activated = current.difference(previous).toList()..sort();
    final cleared = previous.difference(current).toList()..sort();
    if (activated.isEmpty && cleared.isEmpty) return;
    debugPrint(
      '[RetroHub.Gen5Battle] EventWork changed: '
      'set=${activated.join(',')} cleared=${cleared.join(',')}',
    );
  }

  /// Devuelve los IDs de entrenador con su bandera persistente activa.
  ///
  /// Blanco/Negro reserva las banderas desde 0x550. Los comandos de script
  /// TrainerFlagSet/Get reciben el trainerId y el juego aplica internamente
  /// esa base; por eso aquí se devuelve el índice relativo como trainerId.
  List<int> _changedTrainerFlagIds(_Gen5SaveLayout layout) {
    final List<int> flags = read(
      layout.eventFlagOffset,
      layout.eventFlagCount ~/ 8,
    );
    if (flags.length != layout.eventFlagCount ~/ 8) return const <int>[];
    final List<int> result = <int>[];
    // En B2W2 aún no está verificada la relación flag -> trainerId. Devolver
    // los índices absolutos permite detectar únicamente flags recién
    // activadas; el tracker exige además que un TRData real haya aparecido en
    // RAM antes de registrar la victoria, por lo que una flag de historia por
    // sí sola nunca crea un combate falso.
    if (!layout.hasVerifiedTrainerFlags) {
      for (int flag = 0; flag < layout.eventFlagCount; flag++) {
        if ((flags[flag >> 3] & (1 << (flag & 7))) != 0) result.add(flag);
      }
      return result;
    }
    final int trainerFlagCount =
        layout.eventFlagCount - _trainerDefeatedFlagStart;
    for (int trainerId = 1; trainerId < trainerFlagCount; trainerId++) {
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

  /// B2W2 conserva seis especies (u16) por gimnasio a partir de Trainer2+5C.
  static List<List<int>> _decodeBadgeTeams(List<int> trainer2) {
    const int firstTeamOffset = 0x5C;
    const int teamSize = 12;
    return List<List<int>>.generate(8, (int badgeIndex) {
      final int start = firstTeamOffset + badgeIndex * teamSize;
      if (start + teamSize > trainer2.length) return const <int>[];
      return <int>[
        for (int slot = 0; slot < 6; slot++)
          _u16(trainer2, start + slot * 2),
      ].where((int species) => species > 0 && species <= 649).toList(
        growable: false,
      );
    }, growable: false);
  }

  /// La primera entrada del Hall de la Fama usa seis registros de 0x3C bytes.
  static List<int> _decodeHallOfFameSpecies(List<int> hallOfFame) {
    const int memberSize = 0x3C;
    if (hallOfFame.length < memberSize * 6) return const <int>[];
    return <int>[
      for (int slot = 0; slot < 6; slot++) _u16(hallOfFame, slot * memberSize),
    ].where((int species) => species > 0 && species <= 649).toList(
      growable: false,
    );
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

final class _Gen5SaveLayout {
  final String label;
  final int partyOffset;
  final int trainerOffset;
  final int trainerLength;
  final int positionOffset;
  final int positionLength;
  final int miscOffset;
  final int miscLength;
  final int dexOffset;
  final int dexLength;
  final int eventFlagOffset;
  final int eventFlagCount;
  final bool hasVerifiedTrainerFlags;
  final bool hasPlaceNameZoneId;
  final bool hasBadgeTeams;
  final int? hallOfFameOffset;
  final int hallOfFameLength;

  const _Gen5SaveLayout({
    required this.label,
    required this.partyOffset,
    required this.trainerOffset,
    required this.trainerLength,
    required this.positionOffset,
    required this.positionLength,
    required this.miscOffset,
    required this.miscLength,
    required this.dexOffset,
    required this.dexLength,
    required this.eventFlagOffset,
    required this.eventFlagCount,
    this.hasVerifiedTrainerFlags = true,
    this.hasPlaceNameZoneId = false,
    this.hasBadgeTeams = false,
    this.hallOfFameOffset,
    this.hallOfFameLength = 0,
  });

  static const bw = _Gen5SaveLayout(
    label: 'BW',
    partyOffset: 0x18E00,
    trainerOffset: 0x19400,
    trainerLength: 0x68,
    positionOffset: 0x19500,
    positionLength: 0x9C,
    miscOffset: 0x21200,
    miscLength: 0xEC,
    dexOffset: 0x21600,
    dexLength: 0x4D4,
    eventFlagOffset: 0x20100 + 0x27C,
    eventFlagCount: 0xB60,
  );

  static const b2w2 = _Gen5SaveLayout(
    label: 'B2W2',
    partyOffset: 0x18E00,
    trainerOffset: 0x19400,
    trainerLength: 0xB0,
    positionOffset: 0x19500,
    positionLength: 0xA8,
    miscOffset: 0x21100,
    miscLength: 0xF0,
    dexOffset: 0x21400,
    dexLength: 0x4DC,
    eventFlagOffset: 0x1FF00 + 0x35E,
    eventFlagCount: 0xBF8,
    hasVerifiedTrainerFlags: false,
    hasPlaceNameZoneId: true,
    hasBadgeTeams: true,
    hallOfFameOffset: 0x23800,
    hallOfFameLength: 0x16C,
  );

  static _Gen5SaveLayout? forVersion(PokemonGameVersion version) =>
      switch (version) {
        PokemonGameVersion.black || PokemonGameVersion.white => bw,
        PokemonGameVersion.black2 || PokemonGameVersion.white2 => b2w2,
        _ => null,
      };
}
