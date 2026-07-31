import '../decoder/pokemon_decoder.dart';
import 'pokemon_game_profile.dart';

class PokemonPartyMember {
  final int internalSpeciesId;
  final int pokedexId;
  final String name;
  final int level;
  final bool isShiny;
  const PokemonPartyMember({required this.internalSpeciesId,required this.pokedexId,required this.name,required this.level,this.isShiny=false});
  Map<String,dynamic> toJson()=>{'id':pokedexId,'internalId':internalSpeciesId,'name':name,'level':level,'isShiny':isShiny};
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
  final List<PokemonPartyMember> party;
  const PokemonMemorySnapshot({required this.capturedAt,required this.profile,required this.memoryShift,required this.playerName,required this.trainerId,required this.currentMapId,required this.playerX,required this.playerY,required this.money,required this.badgesMask,required this.pokedexSeen,required this.pokedexCaught,required this.party});
  List<int> get partySpeciesIds=>party.map((e)=>e.pokedexId).toList(growable:false);
  int get badgeCount=>PokemonDecoder.countBits(<int>[badgesMask&0xff,(badgesMask>>8)&0xff]);
  String get currentLocation=>PokemonDecoder.mapName(profile,currentMapId);
  String badgeName(int index)=>PokemonDecoder.badgeName(profile,index);
}
