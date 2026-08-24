import '../decoder/pokemon_decoder.dart';
import 'pokemon_game_profile.dart';

class PokemonPartyMember {
  final int internalSpeciesId;
  final int pokedexId;
  final String name;
  final int level;
  final bool isShiny;
  final bool isEgg;
  final String? nickname;
  final int? currentHp;
  final int? maximumHp;
  final int? status;
  final int? friendship;
  final int? experience;
  final List<int> moveIds;
  final int? attack;
  final int? defense;
  final int? speed;
  final int? specialAttack;
  final int? specialDefense;
  final int? special;
  final int? abilitySlot;
  final int? personality;
  final int? heldItemId;
  final int? eggCyclesRemaining;
  final int? eggCyclesTotal;

  const PokemonPartyMember({
    required this.internalSpeciesId,
    required this.pokedexId,
    required this.name,
    required this.level,
    this.isShiny = false,
    this.isEgg = false,
    this.nickname,
    this.currentHp,
    this.maximumHp,
    this.status,
    this.friendship,
    this.experience,
    this.moveIds = const <int>[],
    this.attack,
    this.defense,
    this.speed,
    this.specialAttack,
    this.specialDefense,
    this.special,
    this.abilitySlot,
    this.personality,
    this.heldItemId,
    this.eggCyclesRemaining,
    this.eggCyclesTotal,
  });

  int? get eggStepsCurrent {
    if (eggCyclesRemaining == null || eggCyclesTotal == null) return null;
    final int completedCycles = (eggCyclesTotal! - eggCyclesRemaining!)
        .clamp(0, eggCyclesTotal!)
        .toInt();
    return completedCycles * 256;
  }

  int? get eggStepsTotal =>
      eggCyclesTotal == null ? null : eggCyclesTotal! * 256;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': pokedexId,
    'internalId': internalSpeciesId,
    'name': name,
    'level': level,
    'isShiny': isShiny,
    'isEgg': isEgg,
    'nickname': nickname,
    'currentHp': currentHp,
    'maximumHp': maximumHp,
    'status': status,
    'friendship': friendship,
    'experience': experience,
    'moveIds': moveIds,
    'attack': attack,
    'defense': defense,
    'speed': speed,
    'specialAttack': specialAttack,
    'specialDefense': specialDefense,
    'special': special,
    'abilitySlot': abilitySlot,
    'personality': personality,
    'heldItemId': heldItemId,
    'eggCyclesRemaining': eggCyclesRemaining,
    'eggCyclesTotal': eggCyclesTotal,
    'eggStepsCurrent': eggStepsCurrent,
    'eggStepsTotal': eggStepsTotal,
  };
}

class PokemonMemorySnapshot {
  final DateTime capturedAt;
  final PokemonGameProfile profile;
  final int memoryShift;
  final String playerName;
  final int trainerId;
  final int currentMapId;
  final int playerX;
  final int playerY;
  final int money;
  final int badgesMask;
  final int pokedexSeen;
  final int pokedexCaught;
  final bool nationalDexUnlocked;
  final List<int> seenPokemonIds;
  final List<int> caughtPokemonIds;
  final List<PokemonPartyMember> party;
  final int? gamePlayTimeMinutes;
  final int? battleState;
  final int? otherTrainerClassId;
  final int? otherTrainerId;
  final int? battleResultRaw;
  final List<int> defeatedTrainerIds;

  const PokemonMemorySnapshot({
    required this.capturedAt,
    required this.profile,
    required this.memoryShift,
    required this.playerName,
    required this.trainerId,
    required this.currentMapId,
    required this.playerX,
    required this.playerY,
    required this.money,
    required this.badgesMask,
    required this.pokedexSeen,
    required this.pokedexCaught,
    this.nationalDexUnlocked = false,
    required this.seenPokemonIds,
    required this.caughtPokemonIds,
    required this.party,
    this.gamePlayTimeMinutes,
    this.battleState,
    this.otherTrainerClassId,
    this.otherTrainerId,
    this.battleResultRaw,
    this.defeatedTrainerIds = const <int>[],
  });

  List<int> get partySpeciesIds =>
      party.map((e) => e.pokedexId).toList(growable: false);

  int get badgeCount => PokemonDecoder.countBits(<int>[
    badgesMask & 0xff,
    (badgesMask >> 8) & 0xff,
  ]);

  String get currentLocation => PokemonDecoder.mapName(profile, currentMapId);

  String badgeName(int index) => PokemonDecoder.badgeName(profile, index);
}
