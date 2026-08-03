import '../decoder/pokemon_decoder.dart';
import 'pokemon_game_profile.dart';

class PokemonPartyMember {
  final int internalSpeciesId;
  final int pokedexId;
  final String name;
  final int level;
  final bool isShiny;
  final String? nickname;
  final int? currentHp;
  final int? maximumHp;
  final int? status;
  const PokemonPartyMember({required this.internalSpeciesId,required this.pokedexId,required this.name,required this.level,this.isShiny=false,this.nickname,this.currentHp,this.maximumHp,this.status});
  Map<String,dynamic> toJson()=>{'id':pokedexId,'internalId':internalSpeciesId,'name':name,'level':level,'isShiny':isShiny,'nickname':nickname,'currentHp':currentHp,'maximumHp':maximumHp,'status':status};
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
  final List<int> seenPokemonIds;
  final List<int> caughtPokemonIds;
  final List<PokemonPartyMember> party;
  final int? gamePlayTimeMinutes;
  // Combate (Fase 4.2/4.3). null = no soportado en esta versión/perfil.
  // battleState: 0 = fuera de combate, 1 = combate salvaje, 2 = combate
  // de entrenador (mismo significado en Gen1 y Gen2, direcciones
  // distintas ya resueltas en PokemonMemoryAddresses).
  final int? battleState;
  final int? otherTrainerClassId;
  final int? otherTrainerId;
  final int? battleResultRaw;
  const PokemonMemorySnapshot({required this.capturedAt,required this.profile,required this.memoryShift,required this.playerName,required this.trainerId,required this.currentMapId,required this.playerX,required this.playerY,required this.money,required this.badgesMask,required this.pokedexSeen,required this.pokedexCaught,required this.seenPokemonIds,required this.caughtPokemonIds,required this.party,this.gamePlayTimeMinutes,this.battleState,this.otherTrainerClassId,this.otherTrainerId,this.battleResultRaw});
  List<int> get partySpeciesIds=>party.map((e)=>e.pokedexId).toList(growable:false);
  int get badgeCount=>PokemonDecoder.countBits(<int>[badgesMask&0xff,(badgesMask>>8)&0xff]);
  String get currentLocation=>PokemonDecoder.mapName(profile,currentMapId);
  String badgeName(int index)=>PokemonDecoder.badgeName(profile,index);
}
