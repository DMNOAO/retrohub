import '../../../core/assets/game_asset_profile.dart';

class PokedexEncounter {
  final String location;
  final String method;
  final String time;
  const PokedexEncounter({required this.location, required this.method, required this.time});
}

class PokedexMove {
  final int level;
  final String name;
  const PokedexMove(this.level, this.name);
}

class PokedexMachineMove {
  final String machine;
  final String name;
  const PokedexMachineMove(this.machine, this.name);
}

class PokedexSpeciesDetail {
  final String entry;
  final List<PokedexEncounter> encounters;
  final List<PokedexMove> levelMoves;
  final List<PokedexMachineMove> machineMoves;
  const PokedexSpeciesDetail({this.entry = '', this.encounters = const [], this.levelMoves = const [], this.machineMoves = const []});
}

class PokedexDetailData {
  const PokedexDetailData._();

  static PokedexSpeciesDetail forGame(GameAssetProfile profile, int pokemonId) {
    switch (profile.game) {
      case PokemonAssetGame.crystal:
        return _crystal[pokemonId] ?? const PokedexSpeciesDetail();
      case PokemonAssetGame.gold:
      case PokemonAssetGame.silver:
        return _goldSilver[pokemonId] ?? const PokedexSpeciesDetail();
      default:
        return const PokedexSpeciesDetail();
    }
  }

  static const List<PokedexMachineMove> _totodileMachines = [
    PokedexMachineMove('MT01', 'Puño Dinámico'), PokedexMachineMove('MT02', 'Golpe Cabeza'), PokedexMachineMove('MT03', 'Maldición'), PokedexMachineMove('MT05', 'Rugido'), PokedexMachineMove('MT06', 'Tóxico'), PokedexMachineMove('MT08', 'Golpe Roca'), PokedexMachineMove('MT10', 'Poder Oculto'), PokedexMachineMove('MT13', 'Ronquido'), PokedexMachineMove('MT14', 'Ventisca'), PokedexMachineMove('MT15', 'Hiperrayo'), PokedexMachineMove('MT16', 'Viento Hielo'), PokedexMachineMove('MT17', 'Protección'), PokedexMachineMove('MT18', 'Danza Lluvia'), PokedexMachineMove('MT20', 'Aguante'), PokedexMachineMove('MT21', 'Frustración'), PokedexMachineMove('MT23', 'Cola Férrea'), PokedexMachineMove('MT26', 'Terremoto'), PokedexMachineMove('MT27', 'Retribución'), PokedexMachineMove('MT28', 'Excavar'), PokedexMachineMove('MT31', 'Bofetón Lodo'), PokedexMachineMove('MT32', 'Doble Equipo'), PokedexMachineMove('MT33', 'Puño Hielo'), PokedexMachineMove('MT34', 'Contoneo'), PokedexMachineMove('MT35', 'Sonámbulo'), PokedexMachineMove('MT43', 'Detección'), PokedexMachineMove('MT44', 'Descanso'), PokedexMachineMove('MT45', 'Atracción'), PokedexMachineMove('MT49', 'Corte Furia'), PokedexMachineMove('MO01', 'Corte'), PokedexMachineMove('MO03', 'Surf'), PokedexMachineMove('MO04', 'Fuerza'), PokedexMachineMove('MO06', 'Torbellino'),
  ];

  static const Map<int, PokedexSpeciesDetail> _crystal = {
    158: PokedexSpeciesDetail(
      entry: 'Este pequeño y rudo Pokémon muerde cualquier cosa que se mueva. No es recomendable darle la espalda.',
      encounters: [PokedexEncounter(location: 'Pueblo Primavera', method: 'Pokémon inicial de Prof. Elm', time: 'Cualquier hora')],
      levelMoves: [PokedexMove(1, 'Arañazo'), PokedexMove(1, 'Malicioso'), PokedexMove(7, 'Furia'), PokedexMove(13, 'Pistola Agua'), PokedexMove(20, 'Mordisco'), PokedexMove(27, 'Cara Susto'), PokedexMove(35, 'Cuchillada'), PokedexMove(43, 'Chirrido'), PokedexMove(52, 'Hidrobomba')],
      machineMoves: _totodileMachines,
    ),
    19: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 29', method: 'Hierba', time: 'Mañana · Día · Noche'), PokedexEncounter(location: 'Ruta 30', method: 'Hierba', time: 'Noche')]),
    20: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 26', method: 'Hierba', time: 'Noche')]),
    163: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 29', method: 'Hierba', time: 'Noche')]),
    165: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 30', method: 'Hierba', time: 'Mañana · Día')]),
  };

  static const Map<int, PokedexSpeciesDetail> _goldSilver = {};
}
