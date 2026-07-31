import '../models/pokemon_game_profile.dart';

class PokemonDecoder {
  static String decodeText(List<int> bytes) {
    final out = StringBuffer();
    for (final value in bytes) {
      if (value == 0x50 || value == 0x00) break;
      final character = _characters[value];
      if (character != null) out.write(character);
    }
    return out.toString().trim();
  }

  static int decodeBcd(List<int> bytes) {
    int result = 0;
    for (final byte in bytes) {
      final high = (byte >> 4) & 0x0f;
      final low = byte & 0x0f;
      if (high > 9 || low > 9) return -1;
      result = result * 100 + high * 10 + low;
    }
    return result;
  }

  static int countBits(List<int> bytes) {
    int count = 0;
    for (int value in bytes) {
      while (value != 0) { count += value & 1; value >>= 1; }
    }
    return count;
  }

  static int dexId(PokemonGameProfile profile, int species) =>
      profile.isGen2 ? species : (_gen1InternalToDex[species] ?? 0);

  static String pokemonName(int dexId) =>
      dexId > 0 && dexId < _names.length ? _names[dexId] : 'Pokémon #$dexId';

  static bool isGen2Shiny(int attackDefense, int speedSpecial) {
    final attack = (attackDefense >> 4) & 0x0f;
    final defense = attackDefense & 0x0f;
    final speed = (speedSpecial >> 4) & 0x0f;
    final special = speedSpecial & 0x0f;
    const shinyAttack = <int>{2, 3, 6, 7, 10, 11, 14, 15};
    return shinyAttack.contains(attack) && defense == 10 && speed == 10 && special == 10;
  }

  static String mapName(PokemonGameProfile profile, int mapId) {
    if (profile.isGen2) {
      return _gen2Maps[mapId] ??
          'Mapa ${((mapId >> 8) & 0xff).toString().padLeft(2, '0')}:${(mapId & 0xff).toString().padLeft(2, '0')}';
    }
    return _gen1Maps[mapId] ??
        'Mapa 0x${mapId.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  static String badgeName(PokemonGameProfile profile, int index) {
    final names = profile.isGen2 ? _gen2Badges : _gen1Badges;
    return index >= 0 && index < names.length ? names[index] : 'Medalla';
  }

  static const _gen1Badges = <String>[
    'Medalla Roca','Medalla Cascada','Medalla Trueno','Medalla Arcoíris',
    'Medalla Alma','Medalla Pantano','Medalla Volcán','Medalla Tierra',
  ];
  static const _gen2Badges = <String>[
    'Medalla Céfiro','Medalla Colmena','Medalla Planicie','Medalla Niebla',
    'Medalla Tormenta','Medalla Mineral','Medalla Glaciar','Medalla Dragón',
    'Medalla Trueno','Medalla Pantano','Medalla Arcoíris','Medalla Alma',
    'Medalla Cascada','Medalla Roca','Medalla Volcán','Medalla Tierra',
  ];

  static const Map<int,String> _characters = <int,String>{
    0x80:'A',0x81:'B',0x82:'C',0x83:'D',0x84:'E',0x85:'F',0x86:'G',0x87:'H',0x88:'I',0x89:'J',0x8A:'K',0x8B:'L',0x8C:'M',0x8D:'N',0x8E:'O',0x8F:'P',0x90:'Q',0x91:'R',0x92:'S',0x93:'T',0x94:'U',0x95:'V',0x96:'W',0x97:'X',0x98:'Y',0x99:'Z',
    0xA0:'a',0xA1:'b',0xA2:'c',0xA3:'d',0xA4:'e',0xA5:'f',0xA6:'g',0xA7:'h',0xA8:'i',0xA9:'j',0xAA:'k',0xAB:'l',0xAC:'m',0xAD:'n',0xAE:'o',0xAF:'p',0xB0:'q',0xB1:'r',0xB2:'s',0xB3:'t',0xB4:'u',0xB5:'v',0xB6:'w',0xB7:'x',0xB8:'y',0xB9:'z',
    0xE0:"'",0xE3:'-',0xE6:'?',0xE7:'!',0xE8:'.',0xEF:'♂',0xF5:'♀',0xF6:'0',0xF7:'1',0xF8:'2',0xF9:'3',0xFA:'4',0xFB:'5',0xFC:'6',0xFD:'7',0xFE:'8',0xFF:'9',0x7F:' ',
  };

  static const Map<int,int> _gen1InternalToDex = <int,int>{
    1:112,2:115,3:32,4:35,5:21,6:100,7:34,8:80,9:2,10:103,11:108,12:102,13:88,14:94,15:29,16:31,17:104,18:111,19:131,20:59,21:151,22:130,23:90,24:72,25:92,26:123,27:120,28:9,29:127,30:114,33:58,34:95,35:22,36:16,37:79,38:64,39:75,40:113,41:67,42:122,43:106,44:107,45:24,46:47,47:54,48:96,49:76,51:126,53:125,54:82,55:109,57:56,58:86,59:50,60:128,64:83,65:48,66:149,70:84,71:60,72:124,73:146,74:144,75:145,76:132,77:52,78:98,82:37,83:38,84:25,85:26,88:147,89:148,90:140,91:141,92:116,93:117,96:27,97:28,98:138,99:139,100:39,101:40,102:133,103:136,104:135,105:134,106:66,107:41,108:23,109:46,110:61,111:62,112:13,113:14,114:15,116:85,117:57,118:51,119:49,120:87,123:10,124:11,125:12,126:68,128:55,129:97,130:42,131:150,132:143,133:129,136:89,138:99,139:91,141:101,142:36,143:110,144:53,145:105,147:93,148:63,149:65,150:17,151:18,152:121,153:1,154:3,155:73,157:118,158:119,163:77,164:78,165:19,166:20,167:33,168:30,169:74,170:137,171:142,173:81,176:4,177:7,178:5,179:8,180:6,185:43,186:44,187:45,188:69,189:70,190:71,
  };

  static const List<String> _names = <String>[
    '', 'Bulbasaur','Ivysaur','Venusaur','Charmander','Charmeleon','Charizard','Squirtle','Wartortle','Blastoise','Caterpie','Metapod','Butterfree','Weedle','Kakuna','Beedrill','Pidgey','Pidgeotto','Pidgeot','Rattata','Raticate','Spearow','Fearow','Ekans','Arbok','Pikachu','Raichu','Sandshrew','Sandslash','Nidoran♀','Nidorina','Nidoqueen','Nidoran♂','Nidorino','Nidoking','Clefairy','Clefable','Vulpix','Ninetales','Jigglypuff','Wigglytuff','Zubat','Golbat','Oddish','Gloom','Vileplume','Paras','Parasect','Venonat','Venomoth','Diglett','Dugtrio','Meowth','Persian','Psyduck','Golduck','Mankey','Primeape','Growlithe','Arcanine','Poliwag','Poliwhirl','Poliwrath','Abra','Kadabra','Alakazam','Machop','Machoke','Machamp','Bellsprout','Weepinbell','Victreebel','Tentacool','Tentacruel','Geodude','Graveler','Golem','Ponyta','Rapidash','Slowpoke','Slowbro','Magnemite','Magneton','Farfetch’d','Doduo','Dodrio','Seel','Dewgong','Grimer','Muk','Shellder','Cloyster','Gastly','Haunter','Gengar','Onix','Drowzee','Hypno','Krabby','Kingler','Voltorb','Electrode','Exeggcute','Exeggutor','Cubone','Marowak','Hitmonlee','Hitmonchan','Lickitung','Koffing','Weezing','Rhyhorn','Rhydon','Chansey','Tangela','Kangaskhan','Horsea','Seadra','Goldeen','Seaking','Staryu','Starmie','Mr. Mime','Scyther','Jynx','Electabuzz','Magmar','Pinsir','Tauros','Magikarp','Gyarados','Lapras','Ditto','Eevee','Vaporeon','Jolteon','Flareon','Porygon','Omanyte','Omastar','Kabuto','Kabutops','Aerodactyl','Snorlax','Articuno','Zapdos','Moltres','Dratini','Dragonair','Dragonite','Mewtwo','Mew',
    'Chikorita','Bayleef','Meganium','Cyndaquil','Quilava','Typhlosion','Totodile','Croconaw','Feraligatr','Sentret','Furret','Hoothoot','Noctowl','Ledyba','Ledian','Spinarak','Ariados','Crobat','Chinchou','Lanturn','Pichu','Cleffa','Igglybuff','Togepi','Togetic','Natu','Xatu','Mareep','Flaaffy','Ampharos','Bellossom','Marill','Azumarill','Sudowoodo','Politoed','Hoppip','Skiploom','Jumpluff','Aipom','Sunkern','Sunflora','Yanma','Wooper','Quagsire','Espeon','Umbreon','Murkrow','Slowking','Misdreavus','Unown','Wobbuffet','Girafarig','Pineco','Forretress','Dunsparce','Gligar','Steelix','Snubbull','Granbull','Qwilfish','Scizor','Shuckle','Heracross','Sneasel','Teddiursa','Ursaring','Slugma','Magcargo','Swinub','Piloswine','Corsola','Remoraid','Octillery','Delibird','Mantine','Skarmory','Houndour','Houndoom','Kingdra','Phanpy','Donphan','Porygon2','Stantler','Smeargle','Tyrogue','Hitmontop','Smoochum','Elekid','Magby','Miltank','Blissey','Raikou','Entei','Suicune','Larvitar','Pupitar','Tyranitar','Lugia','Ho-Oh','Celebi'
  ];

  static const Map<int,String> _gen1Maps = <int,String>{
    0x00:'Pueblo Paleta',0x01:'Ciudad Verde',0x02:'Ciudad Plateada',0x03:'Ciudad Celeste',0x04:'Pueblo Lavanda',0x05:'Ciudad Carmín',0x06:'Ciudad Azulona',0x07:'Ciudad Fucsia',0x08:'Isla Canela',0x09:'Meseta Añil',0x0A:'Ciudad Azafrán',0x28:'Laboratorio del Profesor Oak',0x0C:'Ruta 1',0x0D:'Ruta 2',0x0E:'Ruta 3',0x0F:'Ruta 4',
  };

  // Claves grupo<<8 | mapa. Se incluyen los núcleos de la aventura; los mapas
  // no listados siguen mostrando sus IDs para poder ampliarlos sin perder datos.
  static const Map<int,String> _gen2Maps = <int,String>{
    0x1807:'Pueblo Primavera', 0x1801:'Ciudad Cerezo', 0x0A05:'Ciudad Malva',
    0x0305:'Pueblo Azalea', 0x1205:'Ciudad Trigal', 0x0905:'Ciudad Iris',
    0x0D05:'Ciudad Olivo', 0x0B05:'Ciudad Orquídea', 0x0F05:'Pueblo Caoba',
    0x0E05:'Ciudad Endrino', 0x0105:'Meseta Añil', 0x1A05:'Ciudad Verde',
    0x1705:'Pueblo Paleta', 0x1605:'Ciudad Plateada', 0x1905:'Ciudad Celeste',
    0x1505:'Ciudad Carmín', 0x1405:'Ciudad Azulona', 0x1305:'Ciudad Fucsia',
    0x1105:'Pueblo Lavanda', 0x1005:'Ciudad Azafrán',
  };
}

// Compatibilidad con código Gen I anterior.
class PokemonGen1Decoder {
  static String decodeText(List<int> bytes) => PokemonDecoder.decodeText(bytes);
  static String decodePlayerName(List<int> bytes) => PokemonDecoder.decodeText(bytes);
  static bool isPlausibleText(List<int> bytes) => PokemonDecoder.decodeText(bytes).isNotEmpty;
  static int decodeBcd(List<int> bytes) => PokemonDecoder.decodeBcd(bytes);
  static int countBits(List<int> bytes) => PokemonDecoder.countBits(bytes);
  static int pokedexIdFromInternal(int id) => PokemonDecoder._gen1InternalToDex[id] ?? 0;
  static String pokemonName(int dexId) => PokemonDecoder.pokemonName(dexId);
  static String mapName(int mapId) => PokemonDecoder._gen1Maps[mapId] ??
      'Mapa 0x${mapId.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  static String badgeName(int index) => index >= 0 && index < PokemonDecoder._gen1Badges.length
      ? PokemonDecoder._gen1Badges[index]
      : 'Medalla';
}

