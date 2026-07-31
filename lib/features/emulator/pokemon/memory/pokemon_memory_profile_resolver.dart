import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import 'pokemon_addresses.dart';

typedef PokemonMemoryRead=List<int> Function(int offset,int length);
class ResolvedPokemonMemoryProfile{final PokemonMemoryAddresses addresses;final int shift;const ResolvedPokemonMemoryProfile({required this.addresses,required this.shift});}

class PokemonMemoryProfileResolver{
  static ResolvedPokemonMemoryProfile? resolve({required PokemonGameProfile profile,required PokemonMemoryRead read}){
    final preferred=profile.addresses;if(preferred==null)return null;
    if(_isValid(profile,preferred,read))return ResolvedPokemonMemoryProfile(addresses:preferred,shift:0);
    // Traducciones/revisiones suelen desplazar el bloque completo. Crystal se
    // busca en un rango algo mayor porque incorpora más datos persistentes.
    final range=profile.isGen2?0x180:0x80;
    for(int d=1;d<=range;d++)for(final delta in <int>[d,-d]){
      final candidate=preferred.shifted(delta);
      if(_isValid(profile,candidate,read))return ResolvedPokemonMemoryProfile(addresses:candidate,shift:delta);
    }
    return null;
  }

  static bool _isValid(PokemonGameProfile p,PokemonMemoryAddresses a,PokemonMemoryRead read){
    if(a.playerName<0||a.partyMons>=0x8000)return false;
    final c=read(a.partyCount,1);if(c.length!=1)return false;
    final count=c.first;if(count<1||count>6)return false;
    final species=read(a.partySpecies,7);if(species.length!=7||species[count]!=0xff)return false;
    for(int i=0;i<count;i++){final dex=PokemonDecoder.dexId(p,species[i]);if(dex<1||dex>(p.isGen2?251:151))return false;}
    final name=read(a.playerName,a.playerNameLength);if(name.length!=a.playerNameLength||!name.contains(0x50)||PokemonDecoder.decodeText(name).isEmpty)return false;
    if(PokemonDecoder.decodeBcd(read(a.playerMoney,3))<0)return false;
    for(int i=0;i<count;i++){
      final mon=read(a.partyMons+i*a.partyStructLength,a.partyStructLength);
      if(mon.length!=a.partyStructLength||mon.first!=species[i])return false;
      final level=mon[a.partyLevelOffset];if(level<1||level>100)return false;
    }
    return true;
  }
}
