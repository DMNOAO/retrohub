import '../../../core/assets/game_asset_profile.dart';
import '../../pokemon/decoder/pokemon_decoder.dart';

class PokedexEvolutionData {
  const PokedexEvolutionData._();

  static String forGame(GameAssetProfile profile, int pokemonId) {
    final generation = switch (profile.game) {
      PokemonAssetGame.redBlue || PokemonAssetGame.yellow => 1,
      PokemonAssetGame.gold || PokemonAssetGame.silver || PokemonAssetGame.crystal => 2,
      PokemonAssetGame.rubySapphire ||
      PokemonAssetGame.emerald ||
      PokemonAssetGame.fireRedLeafGreen => 3,
      _ => 0,
    };
    if (generation == 0) return '';
    final rules = profile.game == PokemonAssetGame.fireRedLeafGreen
        ? _fireRedLeafGreen
        : generation == 1
        ? _gen1
        : generation == 2
        ? _gen2
        : _gen3;
    final rule = rules[pokemonId];
    if (rule == null) return 'No evoluciona en esta generación.';
    return rule;
  }

  static String _level(int id, int level) => 'Evoluciona a ${PokemonDecoder.pokemonName(id)} al Nv. $level.';
  static String _stone(int id, String stone) => 'Evoluciona a ${PokemonDecoder.pokemonName(id)} usando $stone.';
  static String _trade(int id) => 'Evoluciona a ${PokemonDecoder.pokemonName(id)} mediante intercambio.';
  static String _multiple(List<String> options) => options.join('\n');

  static final Map<int, String> _gen1 = {
    1:_level(2,16),2:_level(3,32),4:_level(5,16),5:_level(6,36),7:_level(8,16),8:_level(9,36),10:_level(11,7),11:_level(12,10),13:_level(14,7),14:_level(15,10),16:_level(17,18),17:_level(18,36),19:_level(20,20),21:_level(22,20),23:_level(24,22),25:_stone(26,'Piedra Trueno'),27:_level(28,22),29:_level(30,16),30:_stone(31,'Piedra Lunar'),32:_level(33,16),33:_stone(34,'Piedra Lunar'),35:_stone(36,'Piedra Lunar'),37:_stone(38,'Piedra Fuego'),39:_stone(40,'Piedra Lunar'),41:_level(42,22),43:_level(44,21),44:_stone(45,'Piedra Hoja'),46:_level(47,24),48:_level(49,31),50:_level(51,26),52:_level(53,28),54:_level(55,33),56:_level(57,28),58:_stone(59,'Piedra Fuego'),60:_level(61,25),61:_stone(62,'Piedra Agua'),63:_level(64,16),64:_trade(65),66:_level(67,28),67:_trade(68),69:_level(70,21),70:_stone(71,'Piedra Hoja'),72:_level(73,30),74:_level(75,25),75:_trade(76),77:_level(78,40),79:_level(80,37),81:_level(82,30),84:_level(85,31),86:_level(87,34),88:_level(89,38),90:_stone(91,'Piedra Agua'),92:_level(93,25),93:_trade(94),96:_level(97,26),98:_level(99,28),100:_level(101,30),102:_stone(103,'Piedra Hoja'),104:_level(105,28),109:_level(110,35),111:_level(112,42),116:_level(117,32),118:_level(119,33),120:_stone(121,'Piedra Agua'),129:_level(130,20),133:_multiple(['Vaporeon con Piedra Agua.','Jolteon con Piedra Trueno.','Flareon con Piedra Fuego.']),138:_level(139,40),140:_level(141,40),147:_level(148,30),148:_level(149,55),
  };

  static final Map<int, String> _gen2 = {
    ..._gen1,
    42:'Evoluciona a Crobat con amistad alta.',44:_multiple(['Vileplume con Piedra Hoja.','Bellossom con Piedra Solar.']),61:_multiple(['Poliwrath con Piedra Agua.','Politoed mediante intercambio con Roca del Rey.']),79:_multiple(['Slowbro al Nv. 37.','Slowking mediante intercambio con Roca del Rey.']),95:'Evoluciona a Steelix al intercambiarlo con Revestimiento Metálico.',113:'Evoluciona a Blissey con amistad alta.',117:'Evoluciona a Kingdra al intercambiarlo con Escama Dragón.',123:'Evoluciona a Scizor al intercambiarlo con Revestimiento Metálico.',125:'No evoluciona en esta generación.',126:'No evoluciona en esta generación.',133:_multiple(['Vaporeon con Piedra Agua.','Jolteon con Piedra Trueno.','Flareon con Piedra Fuego.','Espeon con amistad alta de día.','Umbreon con amistad alta de noche.']),137:'Evoluciona a Porygon2 al intercambiarlo con Mejora.',
    152:_level(153,16),153:_level(154,32),155:_level(156,14),156:_level(157,36),158:_level(159,18),159:_level(160,30),161:_level(162,15),163:_level(164,20),165:_level(166,18),167:_level(168,22),170:_level(171,27),172:'Evoluciona a Pikachu con amistad alta.',173:'Evoluciona a Clefairy con amistad alta.',174:'Evoluciona a Jigglypuff con amistad alta.',175:'Evoluciona a Togetic con amistad alta.',177:_level(178,25),179:_level(180,15),180:_level(181,30),183:_level(184,18),187:_level(188,18),188:_level(189,27),191:_stone(192,'Piedra Solar'),194:_level(195,20),204:_level(205,31),209:_level(210,23),216:_level(217,30),218:_level(219,38),220:_level(221,33),223:_level(224,25),228:_level(229,24),231:_level(232,25),236:_multiple(['Hitmonlee al Nv. 20 si su Ataque es mayor que su Defensa.','Hitmonchan al Nv. 20 si su Defensa es mayor que su Ataque.','Hitmontop al Nv. 20 si su Ataque y Defensa son iguales.']),238:_level(124,30),239:_level(125,30),240:_level(126,30),246:_level(247,30),247:_level(248,55),
  };

  static final Map<int, String> _gen3 = {
    ..._gen2,
    44:_multiple(['Vileplume con Piedra Hoja.','Bellossom con Piedra Solar.']),64:'Evoluciona a Alakazam mediante intercambio.',67:'Evoluciona a Machamp mediante intercambio.',75:'Evoluciona a Golem mediante intercambio.',93:'Evoluciona a Gengar mediante intercambio.',
    252:_level(253,16),253:_level(254,36),255:_level(256,16),256:_level(257,36),258:_level(259,16),259:_level(260,36),261:_level(262,18),263:_level(264,20),265:_multiple(['Silcoon al Nv. 7 según su valor de personalidad.','Cascoon al Nv. 7 según su valor de personalidad.']),266:_level(267,10),267:'No evoluciona.',268:_level(269,10),270:_level(271,14),271:_stone(272,'Piedra Agua'),273:_level(274,14),274:_stone(275,'Piedra Hoja'),276:_level(277,22),278:_level(279,25),280:_level(281,20),281:_level(282,30),283:_level(284,22),285:_level(286,23),287:_level(288,18),288:_level(289,36),290:_multiple(['Ninjask al Nv. 20.','Shedinja al evolucionar con un espacio libre en el equipo.']),293:_level(294,20),294:_level(295,40),296:_level(297,24),298:'Evoluciona a Marill con amistad alta.',299:'No evoluciona en esta generación.',300:_stone(301,'Piedra Lunar'),304:_level(305,32),305:_level(306,42),307:_level(308,37),309:_level(310,26),315:'No evoluciona en esta generación.',316:_level(317,26),318:_level(319,30),320:_level(321,40),322:_level(323,33),325:_level(326,32),328:_level(329,35),329:_level(330,45),331:_level(332,32),333:_level(334,35),339:_level(340,30),341:_level(342,30),343:_level(344,36),345:_level(346,40),347:_level(348,40),349:'Evoluciona a Milotic al subir de nivel con Belleza alta.',353:_level(354,37),355:_level(356,37),360:_level(202,15),361:_level(362,42),363:_level(364,32),364:_level(365,44),366:_multiple(['Huntail mediante intercambio con Diente Marino.','Gorebyss mediante intercambio con Escama Marina.']),371:_level(372,30),372:_level(373,50),374:_level(375,20),375:_level(376,45),
  };

  static final Map<int, String> _fireRedLeafGreen = {
    ..._gen3,
    // FR/LG no tiene reloj interno. Eevee no puede evolucionar a Espeon o
    // Umbreon dentro de estas ediciones; esas evoluciones requieren
    // transferirlo a Ruby, Sapphire o Emerald.
    133: _multiple([
      'Vaporeon con Piedra Agua.',
      'Jolteon con Piedra Trueno.',
      'Flareon con Piedra Fuego.',
      'Espeon o Umbreon: transfiérelo a Rubí, Zafiro o Esmeralda.',
    ]),
  };
}
