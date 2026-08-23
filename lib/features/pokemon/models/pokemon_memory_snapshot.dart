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
  final int? eggCyclesRemaining;

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
    this.eggCyclesRemaining,
  });

  int? get eggStepsRemaining => eggCyclesRemaining == null
      ? null
      : eggCyclesRemaining! * 256;

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
        'eggCyclesRemaining': eggCyclesRemaining,
        'eggStepsRemaining': eggStepsRemaining,
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
