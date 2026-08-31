import '../decoder/pokemon_decoder.dart';
import '../data/pokemon_hatch_cycles.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';
import '../../emulator/data/libretro_bridge.dart';
import '../../emulator/presentation/widget/libretro_game_view.dart';

/// Lector de los juegos principales de tercera generación.
///
/// Emerald mantiene el progreso en dos bloques alojados dinámicamente en
/// EWRAM. Las direcciones de los punteros globales cambian entre regiones y
/// revisiones, por lo que se usa la dirección inglesa como ruta rápida y se
/// recorre IWRAM como alternativa validada.
final class PokemonEmeraldMemoryReader {
  static const int _fireRedLeafGreenSaveBlock1Size = 0x3D68;
  static const int _fireRedLeafGreenSaveBlock2Size = 0x0F24;
  static const int _fireRedLeafGreenDmaPadding = 0x80;
  static const int _fireRedLeafGreenDexSeen1Offset = 0x05F8;
  static const int _fireRedLeafGreenDexSeen2Offset = 0x3A18;
  static const int _rubySapphireSaveBlock1Address = 0x02025734;
  static const int _rubySapphireSaveBlock2Address = 0x02024EA4;
  static const int _rubySapphireSaveBlock1Size = 0x3AC0;
  static const int _rubySapphireSaveBlock2Size = 0x0890;
  static const int _rubySapphireDexSeen2Offset = 0x0938;
  static const int _rubySapphireDexSeen3Offset = 0x3A8C;
  static const int _englishSaveBlock1PointerAddress = 0x03005D8C;
  static const int _englishSaveBlock2PointerAddress = 0x03005D90;

  static const int _iwramStart = 0x03000000;
  static const int _iwramSize = 0x00008000;
  static const int _ewramStart = 0x02000000;
  static const int _ewramEnd = 0x02040000;

  static const int _saveBlock1Size = 0x3D88;
  static const int _saveBlock2Size = 0x0F2C;
  static const int _partyCountOffset = 0x234;
  static const int _partyOffset = 0x238;
  static const int _partyMemberSize = 100;
  static const int _pokedexOwnedOffset = 0x28;
  static const int _pokedexSeenOffset = 0x5C;
  static const int _pokedexBytes = 52;
  static const int _flagsOffset = 0x1270;
  static const int _firstBadgeFlag = 0x867;
  static const int _nationalDexMagicOffset = 0x1A;
  static const int _nationalDexVarOffset = 0x1428;
  static const int _nationalDexFlag = 0x896;
  static const int _trainerFlagStart = 0x500;
  static const int _lastTrainerId = 854;

  // Variables de batalla de Pokémon Emerald (pret/pokeemerald, revisión
  // inglesa). A diferencia de Gen I/II, BATTLE_TYPE_TRAINER es un bit de
  // gBattleTypeFlags y B_OUTCOME_WON vale 1.
  static const int _battleTypeFlagsAddress = 0x02022FEC;
  static const int _trainerOpponentAddress = 0x02038BCA;
  static const int _battleOutcomeAddress = 0x0203ABF4;
  static const int _battleTypeTrainer = 1 << 3;

  final LibretroGameController? controller;
  final LibretroBridge? bridge;
  final PokemonGameProfile profile;

  const PokemonEmeraldMemoryReader({
    required LibretroGameController this.controller,
    required this.profile,
  }) : bridge = null;

  const PokemonEmeraldMemoryReader.fromBridge({
    required LibretroBridge this.bridge,
    required this.profile,
  }) : controller = null;

  PokemonMemorySnapshot? capture() {
    final bool memoryAvailable =
        controller?.isAttached ?? (bridge?.isGameLoaded ?? false);
    if (!memoryAvailable ||
        profile.version != PokemonGameVersion.emerald &&
            profile.version != PokemonGameVersion.ruby &&
            profile.version != PokemonGameVersion.sapphire &&
            profile.version != PokemonGameVersion.fireRed &&
            profile.version != PokemonGameVersion.leafGreen) {
      return null;
    }

    final _EmeraldSaveBlocks? blocks = _resolveSaveBlocks();
    if (blocks == null) return null;

    final int saveBlock1 = blocks.saveBlock1;
    final int saveBlock2 = blocks.saveBlock2;
    final List<int> nameBytes = _read(saveBlock2, 8);
    final String playerName = PokemonDecoder.decodeGen3Text(nameBytes);
    if (playerName.isEmpty) return null;

    final int trainerId = _u16(saveBlock2 + 0x0A);
    final int hours = _u16(saveBlock2 + 0x0E);
    final int minutes = _u8(saveBlock2 + 0x10);

    final int x = _s16(saveBlock1);
    final int y = _s16(saveBlock1 + 0x02);
    final int mapGroup = _u8(saveBlock1 + 0x04);
    final int mapNumber = _u8(saveBlock1 + 0x05);
    final int currentMapId = (mapGroup << 8) | mapNumber;

    final int money = _readMoney(saveBlock1, saveBlock2);
    final List<PokemonPartyMember> party = _readParty(saveBlock1);
    final List<int> caughtPokemonIds = _readPokedexIds(
      saveBlock2 + _pokedexOwnedOffset,
    );
    final List<int> seenPokemonIds = _readPokedexIds(
      saveBlock2 + _pokedexSeenOffset,
    );
    final int badgesMask = _readBadgesMask(saveBlock1);
    final int nationalMagic = _u8(
      saveBlock2 + (_isFireRedLeafGreen ? 0x1B : _nationalDexMagicOffset),
    );
    final int nationalDexVar = _u16(saveBlock1 + _activeNationalDexVarOffset);
    final bool nationalDexUnlocked = _isFireRedLeafGreen
        ? nationalMagic == 0xB9 &&
              nationalDexVar == 0x6258 &&
              _readFlag(saveBlock1, _activeNationalDexFlag)
        : isNationalDexUnlocked(
            nationalMagic: nationalMagic,
            nationalDexVar: nationalDexVar,
            nationalDexFlagSet: _readFlag(saveBlock1, _activeNationalDexFlag),
          );
    final _EmeraldBattleState? battle =
        profile.version == PokemonGameVersion.emerald
        ? _readBattleState()
        : null;
    final List<int> defeatedTrainerIds = _readDefeatedTrainerIds(saveBlock1);

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      memoryShift: 0,
      playerName: playerName,
      trainerId: trainerId,
      isFemale: _u8(saveBlock2 + 0x08) == 1,
      currentMapId: currentMapId,
      playerX: x,
      playerY: y,
      money: money,
      badgesMask: badgesMask,
      pokedexSeen: seenPokemonIds.length,
      pokedexCaught: caughtPokemonIds.length,
      nationalDexUnlocked: nationalDexUnlocked,
      seenPokemonIds: seenPokemonIds,
      caughtPokemonIds: caughtPokemonIds,
      party: party,
      gamePlayTimeMinutes: hours * 60 + minutes,
      battleState: battle?.state,
      otherTrainerId: battle?.trainerId,
      battleResultRaw: battle?.outcome,
      defeatedTrainerIds: defeatedTrainerIds,
    );
  }

  List<int> _readDefeatedTrainerIds(int saveBlock1) {
    final int flagsOffset = _activeFlagsOffset;
    final int lastTrainerId = _activeLastTrainerId;
    final int firstByte = _trainerFlagStart >> 3;
    final int lastByte = (_trainerFlagStart + lastTrainerId) >> 3;
    final List<int> bytes = _read(
      saveBlock1 + flagsOffset + firstByte,
      lastByte - firstByte + 1,
    );
    return decodeDefeatedTrainerIds(bytes, maximumTrainerId: lastTrainerId);
  }

  static List<int> decodeDefeatedTrainerIds(
    List<int> bytes, {
    int maximumTrainerId = _lastTrainerId,
  }) {
    final int firstByte = _trainerFlagStart >> 3;
    final List<int> result = <int>[];
    for (int trainerId = 1; trainerId <= maximumTrainerId; trainerId++) {
      final int flag = _trainerFlagStart + trainerId;
      final int byteIndex = (flag >> 3) - firstByte;
      if (byteIndex >= bytes.length) break;
      if ((bytes[byteIndex] & (1 << (flag & 7))) != 0) {
        result.add(trainerId);
      }
    }
    return result;
  }

  static int decodeBattleState(int battleTypeFlags) {
    return (battleTypeFlags & _battleTypeTrainer) != 0 ? 2 : 0;
  }

  static bool didPlayerWinBattle(int outcome) => outcome == 1;

  _EmeraldBattleState? _readBattleState() {
    final List<int> flagsBytes = _read(_battleTypeFlagsAddress, 4);
    final List<int> trainerBytes = _read(_trainerOpponentAddress, 2);
    final List<int> outcomeBytes = _read(_battleOutcomeAddress, 1);
    if (flagsBytes.length != 4 ||
        trainerBytes.length != 2 ||
        outcomeBytes.length != 1) {
      return null;
    }

    final int flags = _littleEndian(flagsBytes);
    final int state = decodeBattleState(flags);
    return _EmeraldBattleState(
      state: state,
      trainerId: state == 2 ? _littleEndian(trainerBytes) : null,
      outcome: outcomeBytes.first,
    );
  }

  static bool isNationalDexUnlocked({
    required int nationalMagic,
    required int nationalDexVar,
    required bool nationalDexFlagSet,
  }) {
    return nationalMagic == 0xDA &&
        nationalDexVar == 0x0302 &&
        nationalDexFlagSet;
  }

  bool _readFlag(int saveBlock1, int flag) {
    final value = _u8(saveBlock1 + _activeFlagsOffset + (flag >> 3));
    return (value & (1 << (flag & 7))) != 0;
  }

  List<int> _readPokedexIds(int address) {
    final List<int> bytes = _read(address, _pokedexBytes);
    if (bytes.length != _pokedexBytes) return const <int>[];
    final List<int> ids = <int>[];
    for (int id = 1; id <= 386; id++) {
      final int bit = id - 1;
      if ((bytes[bit >> 3] & (1 << (bit & 7))) != 0) ids.add(id);
    }
    return ids;
  }

  int _readBadgesMask(int saveBlock1) {
    int result = 0;
    for (int badge = 0; badge < 8; badge++) {
      final int flag = _activeFirstBadgeFlag + badge;
      final int value = _u8(saveBlock1 + _activeFlagsOffset + (flag >> 3));
      if ((value & (1 << (flag & 7))) != 0) result |= 1 << badge;
    }
    return result;
  }

  List<PokemonPartyMember> _readParty(int saveBlock1) {
    final int count = _u8(saveBlock1 + _activePartyCountOffset);
    if (count < 0 || count > 6) return const <PokemonPartyMember>[];

    final List<PokemonPartyMember> result = <PokemonPartyMember>[];
    for (int index = 0; index < count; index++) {
      final List<int> bytes = _read(
        saveBlock1 + _activePartyOffset + index * _partyMemberSize,
        _partyMemberSize,
      );
      final PokemonPartyMember? member = _decodePartyMember(bytes);
      if (member == null) return const <PokemonPartyMember>[];
      result.add(member);
    }
    return result;
  }

  PokemonPartyMember? _decodePartyMember(List<int> bytes) {
    if (bytes.length != _partyMemberSize) return null;

    final int personality = _littleEndian(bytes.sublist(0, 4));
    final int originalTrainerId = _littleEndian(bytes.sublist(4, 8));
    final int key = personality ^ originalTrainerId;
    final List<int> decrypted = List<int>.filled(48, 0);
    for (int offset = 0; offset < 48; offset += 4) {
      final int word =
          _littleEndian(bytes.sublist(32 + offset, 36 + offset)) ^ key;
      for (int byte = 0; byte < 4; byte++) {
        decrypted[offset + byte] = (word >> (byte * 8)) & 0xFF;
      }
    }

    int checksum = 0;
    for (int offset = 0; offset < decrypted.length; offset += 2) {
      checksum =
          (checksum + _littleEndian(decrypted.sublist(offset, offset + 2))) &
          0xFFFF;
    }
    final int storedChecksum = _littleEndian(bytes.sublist(28, 30));
    if (checksum != storedChecksum) return null;

    final int internalSpeciesId = internalSpeciesIdFromDecryptedData(
      personality: personality,
      decryptedData: decrypted,
    );
    final int pokedexId = emeraldNationalDexId(internalSpeciesId);
    if (pokedexId < 1 || pokedexId > 386) return null;

    final String nickname = PokemonDecoder.decodeGen3Text(bytes.sublist(8, 18));
    final int level = bytes[84];
    if (level < 1 || level > 100) return null;

    final int trainerHigh = (originalTrainerId >> 16) & 0xFFFF;
    final int trainerLow = originalTrainerId & 0xFFFF;
    final int personalityHigh = (personality >> 16) & 0xFFFF;
    final int personalityLow = personality & 0xFFFF;
    final bool isShiny =
        (trainerHigh ^ trainerLow ^ personalityHigh ^ personalityLow) < 8;
    final int growthOffset = growthSubstructurePosition(personality) * 12;
    final int attacksOffset = attacksSubstructurePosition(personality) * 12;
    final int miscOffset = miscSubstructurePosition(personality) * 12;
    final int friendshipOrEggCycles = decrypted[growthOffset + 9];
    final int heldItemId = _littleEndian(
      decrypted.sublist(growthOffset + 2, growthOffset + 4),
    );
    final int experience = _littleEndian(
      decrypted.sublist(growthOffset + 4, growthOffset + 8),
    );
    final List<int> moveIds = List<int>.generate(
      4,
      (index) => _littleEndian(
        decrypted.sublist(attacksOffset + index * 2, attacksOffset + index * 2 + 2),
      ),
    ).where((move) => move > 0).toList();
    final int ivs = _littleEndian(
      decrypted.sublist(miscOffset + 4, miscOffset + 8),
    );
    final bool isEgg = (ivs & (1 << 30)) != 0;
    final int abilitySlot = ((ivs >> 31) & 1) + 1;
    final int? eggCyclesTotal = isEgg
        ? hatchCyclesForPokedexId(pokedexId) ?? friendshipOrEggCycles
        : null;

    return PokemonPartyMember(
      internalSpeciesId: internalSpeciesId,
      pokedexId: pokedexId,
      name: PokemonDecoder.pokemonName(pokedexId),
      nickname: nickname.isEmpty ? null : nickname,
      level: level,
      isShiny: isShiny,
      isEgg: isEgg,
      status: _littleEndian(bytes.sublist(80, 84)),
      currentHp: _littleEndian(bytes.sublist(86, 88)),
      maximumHp: _littleEndian(bytes.sublist(88, 90)),
      attack: _littleEndian(bytes.sublist(90, 92)),
      defense: _littleEndian(bytes.sublist(92, 94)),
      speed: _littleEndian(bytes.sublist(94, 96)),
      specialAttack: _littleEndian(bytes.sublist(96, 98)),
      specialDefense: _littleEndian(bytes.sublist(98, 100)),
      friendship: isEgg ? null : friendshipOrEggCycles,
      experience: experience,
      moveIds: moveIds,
      abilitySlot: abilitySlot,
      personality: personality,
      heldItemId: heldItemId,
      eggCyclesRemaining: isEgg ? friendshipOrEggCycles : null,
      eggCyclesTotal: eggCyclesTotal,
    );
  }

  static int emeraldNationalDexId(int internalSpeciesId) {
    if (internalSpeciesId >= 1 && internalSpeciesId <= 251) {
      return internalSpeciesId;
    }
    if (internalSpeciesId >= 277 && internalSpeciesId <= 411) {
      return _hoennInternalToNational[internalSpeciesId - 277];
    }
    return 0;
  }

  // Pokémon Emerald numera internamente las especies de Hoenn según su
  // propio orden, no según la Pokédex Nacional. Índice 0 = SPECIES_TREECKO
  // (277), último índice = SPECIES_CHIMECHO (411).
  static const List<int> _hoennInternalToNational = <int>[
    252,
    253,
    254,
    255,
    256,
    257,
    258,
    259,
    260,
    261,
    262,
    263,
    264,
    265,
    266,
    267,
    268,
    269,
    270,
    271,
    272,
    273,
    274,
    275,
    290,
    291,
    292,
    276,
    277,
    285,
    286,
    327,
    278,
    279,
    283,
    284,
    320,
    321,
    300,
    301,
    352,
    343,
    344,
    299,
    324,
    302,
    339,
    340,
    370,
    341,
    342,
    349,
    350,
    318,
    319,
    328,
    329,
    330,
    296,
    297,
    309,
    310,
    322,
    323,
    363,
    364,
    365,
    331,
    332,
    361,
    362,
    337,
    338,
    298,
    325,
    326,
    311,
    312,
    303,
    307,
    308,
    333,
    334,
    360,
    355,
    356,
    315,
    287,
    288,
    289,
    316,
    317,
    357,
    293,
    294,
    295,
    366,
    367,
    368,
    359,
    353,
    354,
    336,
    335,
    369,
    304,
    305,
    306,
    351,
    313,
    314,
    345,
    346,
    347,
    348,
    280,
    281,
    282,
    371,
    372,
    373,
    374,
    375,
    376,
    377,
    378,
    379,
    382,
    383,
    384,
    380,
    381,
    385,
    386,
    358,
  ];

  /// Posición de la subestructura Growth dentro de los cuatro bloques
  /// permutados de un Pokémon de Gen III.
  ///
  /// El orden depende de personality % 24. No se agrupa en seis posiciones
  /// consecutivas: a partir de AGEM las posiciones 1, 2 y 3 se intercalan.
  static int growthSubstructurePosition(int personality) {
    return _growthPositions[personality % 24];
  }

  static int attacksSubstructurePosition(int personality) {
    return _substructureOrders[personality % 24].indexOf('A');
  }

  static const List<String> _substructureOrders = <String>[
    'GAEM', 'GAME', 'GEAM', 'GEMA', 'GMAE', 'GMEA',
    'AGEM', 'AGME', 'AEGM', 'AEMG', 'AMGE', 'AMEG',
    'EGAM', 'EGMA', 'EAGM', 'EAMG', 'EMGA', 'EMAG',
    'MGAE', 'MGEA', 'MAGE', 'MAEG', 'MEGA', 'MEAG',
  ];

  /// Posición de la subestructura Misc, que contiene el flag de huevo en el
  /// bit 30 de la palabra de IVs.
  static int miscSubstructurePosition(int personality) {
    return _miscPositions[personality % 24];
  }

  /// Extrae la especie interna desde los datos ya descifrados y todavía
  /// permutados. Se expone para probar casos reales con distintas
  /// personalidades sin depender del puente nativo.
  static int internalSpeciesIdFromDecryptedData({
    required int personality,
    required List<int> decryptedData,
  }) {
    if (decryptedData.length != 48) return 0;
    final int offset = growthSubstructurePosition(personality) * 12;
    return decryptedData[offset] | (decryptedData[offset + 1] << 8);
  }

  static const List<int> _growthPositions = <int>[
    // GAEM, GAME, GEAM, GEMA, GMAE, GMEA
    0, 0, 0, 0, 0, 0,
    // AGEM, AGME, AEGM, AEMG, AMGE, AMEG
    1, 1, 2, 3, 2, 3,
    // EGAM, EGMA, EAGM, EAMG, EMGA, EMAG
    1, 1, 2, 3, 2, 3,
    // MGAE, MGEA, MAGE, MAEG, MEGA, MEAG
    1, 1, 2, 3, 2, 3,
  ];

  static const List<int> _miscPositions = <int>[
    3,
    2,
    3,
    2,
    1,
    1,
    3,
    2,
    3,
    2,
    1,
    1,
    3,
    2,
    3,
    2,
    1,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  _EmeraldSaveBlocks? _resolveSaveBlocks() {
    if (_isFireRedLeafGreen) {
      // FR/LG aplica el mismo desplazamiento aleatorio (0..0x7C) a ambos
      // bloques. SaveBlock1 queda inmediatamente después de SaveBlock2 y su
      // área DMA. Buscar el nombre y validar la pareja funciona también con
      // ROMs europeas/españolas, sin depender de globals propios de una ROM.
      final List<int> ewram = _read(_ewramStart, _ewramEnd - _ewramStart);
      if (ewram.length != _ewramEnd - _ewramStart) return null;
      final int saveBlockDistance =
          _fireRedLeafGreenSaveBlock2Size + _fireRedLeafGreenDmaPadding;
      for (
        int saveBlock2 = _ewramStart;
        saveBlock2 <=
            _ewramEnd - saveBlockDistance - _fireRedLeafGreenSaveBlock1Size;
        saveBlock2 += 4
      ) {
        final int localOffset = saveBlock2 - _ewramStart;
        if (!isPlausiblePlayerName(
          ewram.sublist(localOffset, localOffset + 8),
        )) {
          continue;
        }
        final int saveBlock1 = saveBlock2 + saveBlockDistance;
        if (_validPair(saveBlock1, saveBlock2)) {
          return _EmeraldSaveBlocks(
            saveBlock1: saveBlock1,
            saveBlock2: saveBlock2,
          );
        }
      }
      return null;
    }
    if (profile.version == PokemonGameVersion.ruby ||
        profile.version == PokemonGameVersion.sapphire) {
      if (_validPair(
        _rubySapphireSaveBlock1Address,
        _rubySapphireSaveBlock2Address,
      )) {
        return const _EmeraldSaveBlocks(
          saveBlock1: _rubySapphireSaveBlock1Address,
          saveBlock2: _rubySapphireSaveBlock2Address,
        );
      }

      // En Ruby/Sapphire ambos bloques son contiguos y SaveBlock1 comienza
      // 0x890 bytes después de SaveBlock2. El barrido validado mantiene el
      // lector operativo si una región o revisión desplaza los globals.
      final List<int> ewram = _read(_ewramStart, _ewramEnd - _ewramStart);
      if (ewram.length != _ewramEnd - _ewramStart) return null;
      for (
        int saveBlock2 = _ewramStart;
        saveBlock2 <= _ewramEnd - 0x890 - _rubySapphireSaveBlock1Size;
        saveBlock2 += 4
      ) {
        final int localOffset = saveBlock2 - _ewramStart;
        if (!isPlausiblePlayerName(
          ewram.sublist(localOffset, localOffset + 8),
        )) {
          continue;
        }
        final int saveBlock1 = saveBlock2 + 0x890;
        if (_validPair(saveBlock1, saveBlock2)) {
          return _EmeraldSaveBlocks(
            saveBlock1: saveBlock1,
            saveBlock2: saveBlock2,
          );
        }
      }
      return null;
    }
    final int? englishSaveBlock1 = _readPointer(
      _englishSaveBlock1PointerAddress,
    );
    final int? englishSaveBlock2 = _readPointer(
      _englishSaveBlock2PointerAddress,
    );
    if (_validPair(englishSaveBlock1, englishSaveBlock2)) {
      return _EmeraldSaveBlocks(
        saveBlock1: englishSaveBlock1!,
        saveBlock2: englishSaveBlock2!,
      );
    }

    // En Emerald los globals gSaveBlock1Ptr y gSaveBlock2Ptr son punteros
    // contiguos. Buscar el par en IWRAM evita mantener una dirección por cada
    // idioma, pero las validaciones de ambos bloques impiden falsos positivos.
    final List<int> iwram = _read(_iwramStart, _iwramSize);
    if (iwram.length != _iwramSize) return null;

    for (int offset = 0; offset <= iwram.length - 8; offset += 4) {
      final int saveBlock1 = _littleEndian(iwram.sublist(offset, offset + 4));
      final int saveBlock2 = _littleEndian(
        iwram.sublist(offset + 4, offset + 8),
      );
      if (_validPair(saveBlock1, saveBlock2)) {
        return _EmeraldSaveBlocks(
          saveBlock1: saveBlock1,
          saveBlock2: saveBlock2,
        );
      }
    }
    return null;
  }

  bool _validPair(int? saveBlock1, int? saveBlock2) {
    final bool rubySapphire =
        profile.version == PokemonGameVersion.ruby ||
        profile.version == PokemonGameVersion.sapphire;
    final int saveBlock1Size = _isFireRedLeafGreen
        ? _fireRedLeafGreenSaveBlock1Size
        : rubySapphire
        ? _rubySapphireSaveBlock1Size
        : _saveBlock1Size;
    final int saveBlock2Size = _isFireRedLeafGreen
        ? _fireRedLeafGreenSaveBlock2Size
        : rubySapphire
        ? _rubySapphireSaveBlock2Size
        : _saveBlock2Size;
    if (!_validBlock(saveBlock1, saveBlock1Size) ||
        !_validBlock(saveBlock2, saveBlock2Size)) {
      return false;
    }

    final List<int> name = _read(saveBlock2!, 8);
    if (!isPlausiblePlayerName(name)) return false;

    // Ruby/Sapphire mantiene tres copias sincronizadas de los Pokémon vistos:
    // una en SaveBlock2 y dos en SaveBlock1. Un nombre de jugador también
    // aparece en buffers auxiliares, pero esos buffers no satisfacen esta
    // relación. Esta comprobación identifica el guardado real en ROMs cuyas
    // direcciones cambian por idioma o revisión.
    if (rubySapphire &&
        !_hasConsistentRubySapphirePokedex(saveBlock1!, saveBlock2)) {
      return false;
    }
    if (_isFireRedLeafGreen &&
        !_hasConsistentFireRedLeafGreenPokedex(saveBlock1!, saveBlock2)) {
      return false;
    }

    // Estos campos forman la cabecera de SaveBlock2 en todos los juegos
    // principales de Gen III. Validarlos evita aceptar buffers temporales
    // (por ejemplo, el nombre AAAAAAA de la pantalla de introducción) como
    // si fueran el guardado real.
    final int gender = _u8(saveBlock2 + 0x08);
    final int trainerId = _u32(saveBlock2 + 0x0A);
    final int buttonMode = _u8(saveBlock2 + 0x13);
    final int options = _u16(saveBlock2 + 0x14);
    if (gender > 1 ||
        trainerId == 0 ||
        trainerId == 0xFFFFFFFF ||
        buttonMode > 2 ||
        (options & 0xF000) != 0) {
      return false;
    }

    final int hours = _u16(saveBlock2 + 0x0E);
    final int minutes = _u8(saveBlock2 + 0x10);
    final int seconds = _u8(saveBlock2 + 0x11);
    final int frames = _u8(saveBlock2 + 0x12);
    final int maximumHours = _isFireRedLeafGreen ? 999 : 9999;
    if (hours > maximumHours || minutes > 59 || seconds > 59 || frames > 59) {
      return false;
    }

    final int x = _s16(saveBlock1!);
    final int y = _s16(saveBlock1 + 0x02);
    final int mapGroup = _u8(saveBlock1 + 0x04);
    final int mapNumber = _u8(saveBlock1 + 0x05);
    if (x < -1 ||
        x > 255 ||
        y < -1 ||
        y > 255 ||
        mapGroup > 63 ||
        mapNumber > 127) {
      return false;
    }

    final int partyCount = _u8(saveBlock1 + _activePartyCountOffset);
    if (partyCount > 6) return false;
    if (partyCount > 0) {
      final List<int> firstMember = _read(
        saveBlock1 + _activePartyOffset,
        _partyMemberSize,
      );
      if (_decodePartyMember(firstMember) == null) return false;
    }

    final int money = _readMoney(saveBlock1, saveBlock2);
    return money >= 0 && money <= 999999;
  }

  bool get _isFireRedLeafGreen =>
      profile.version == PokemonGameVersion.fireRed ||
      profile.version == PokemonGameVersion.leafGreen;

  int get _activePartyCountOffset =>
      _isFireRedLeafGreen ? 0x34 : _partyCountOffset;

  int get _activePartyOffset => _isFireRedLeafGreen ? 0x38 : _partyOffset;

  int _readMoney(int saveBlock1, int saveBlock2) {
    if (_isFireRedLeafGreen) {
      return _u32(saveBlock1 + 0x290) ^ _u32(saveBlock2 + 0xF20);
    }
    if (profile.version == PokemonGameVersion.emerald) {
      return _u32(saveBlock1 + 0x490) ^ _u32(saveBlock2 + 0xAC);
    }
    return _u32(saveBlock1 + 0x490);
  }

  int get _activeFlagsOffset => _isFireRedLeafGreen
      ? 0x0EE0
      : profile.version == PokemonGameVersion.emerald
      ? _flagsOffset
      : 0x1220;

  int get _activeFirstBadgeFlag => _isFireRedLeafGreen
      ? 0x820
      : profile.version == PokemonGameVersion.emerald
      ? _firstBadgeFlag
      : 0x807;

  int get _activeLastTrainerId => _isFireRedLeafGreen
      ? 767
      : profile.version == PokemonGameVersion.emerald
      ? _lastTrainerId
      : 693;

  int get _activeNationalDexVarOffset => _isFireRedLeafGreen
      ? 0x109C
      : profile.version == PokemonGameVersion.emerald
      ? _nationalDexVarOffset
      : 0x13CC;

  int get _activeNationalDexFlag => _isFireRedLeafGreen
      ? 0x840
      : profile.version == PokemonGameVersion.emerald
      ? _nationalDexFlag
      : 0x836;

  bool _hasConsistentRubySapphirePokedex(int saveBlock1, int saveBlock2) {
    final List<int> primarySeen = _read(
      saveBlock2 + _pokedexSeenOffset,
      _pokedexBytes,
    );
    final List<int> secondarySeen = _read(
      saveBlock1 + _rubySapphireDexSeen2Offset,
      _pokedexBytes,
    );
    final List<int> tertiarySeen = _read(
      saveBlock1 + _rubySapphireDexSeen3Offset,
      _pokedexBytes,
    );
    return equalBytes(primarySeen, secondarySeen) &&
        equalBytes(primarySeen, tertiarySeen);
  }

  bool _hasConsistentFireRedLeafGreenPokedex(int saveBlock1, int saveBlock2) {
    final List<int> primarySeen = _read(
      saveBlock2 + _pokedexSeenOffset,
      _pokedexBytes,
    );
    final List<int> secondarySeen = _read(
      saveBlock1 + _fireRedLeafGreenDexSeen1Offset,
      _pokedexBytes,
    );
    final List<int> tertiarySeen = _read(
      saveBlock1 + _fireRedLeafGreenDexSeen2Offset,
      _pokedexBytes,
    );
    return equalBytes(primarySeen, secondarySeen) &&
        equalBytes(primarySeen, tertiarySeen);
  }

  static bool equalBytes(List<int> left, List<int> right) {
    if (left.isEmpty || left.length != right.length) return false;
    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static bool isPlausiblePlayerName(List<int> bytes) {
    if (bytes.length != 8) return false;
    final int terminator = bytes.indexOf(0xFF);
    if (terminator < 1 || terminator > 7) return false;

    final List<int> characters = bytes.take(terminator).toList();
    for (final int value in characters) {
      final bool supported =
          value == 0x00 ||
          (value >= 0xA1 && value <= 0xB6) ||
          (value >= 0xBB && value <= 0xEE);
      if (!supported) return false;
    }

    return PokemonDecoder.decodeGen3Text(bytes).isNotEmpty;
  }

  int? _readPointer(int address) {
    final List<int> bytes = _read(address, 4);
    if (bytes.length != 4) return null;
    return _littleEndian(bytes);
  }

  bool _validBlock(int? address, int size) {
    if (address == null || address < _ewramStart) return false;
    return address <= _ewramEnd - size;
  }

  List<int> _read(int address, int length) {
    final LibretroGameController? activeController = controller;
    if (activeController != null) {
      return activeController.readMemoryAddress(
        address: address,
        length: length,
      );
    }
    return bridge?.readMemoryAddress(address: address, length: length) ??
        const <int>[];
  }

  int _u8(int address) {
    final List<int> bytes = _read(address, 1);
    return bytes.length == 1 ? bytes.first : 0;
  }

  int _u16(int address) {
    final List<int> bytes = _read(address, 2);
    return bytes.length == 2 ? _littleEndian(bytes) : 0;
  }

  int _u32(int address) {
    final List<int> bytes = _read(address, 4);
    return bytes.length == 4 ? _littleEndian(bytes) : 0;
  }

  int _s16(int address) {
    final int value = _u16(address);
    return value >= 0x8000 ? value - 0x10000 : value;
  }

  int _littleEndian(List<int> bytes) {
    int value = 0;
    for (int index = 0; index < bytes.length; index++) {
      value |= (bytes[index] & 0xFF) << (index * 8);
    }
    return value;
  }
}

final class _EmeraldSaveBlocks {
  final int saveBlock1;
  final int saveBlock2;

  const _EmeraldSaveBlocks({
    required this.saveBlock1,
    required this.saveBlock2,
  });
}

final class _EmeraldBattleState {
  final int state;
  final int? trainerId;
  final int outcome;

  const _EmeraldBattleState({
    required this.state,
    required this.trainerId,
    required this.outcome,
  });
}
