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
    // The UI is deliberately version-aware. Gold/Silver/Crystal can share
    // species data where it is identical and override individual records when
    // encounters, text or learnsets differ. Other generations plug into the
    // same API without changing the detail page.
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

  // Seed records use RetroHub-owned static data and make the feature testable
  // now. The maps are intentionally local/offline and can be expanded to all
  // 251 species without changing UI or save decoding.
  static const Map<int, PokedexSpeciesDetail> _crystal = {
    19: PokedexSpeciesDetail(
      encounters: [
        PokedexEncounter(location: 'Ruta 29', method: 'Hierba', time: 'Mañana · Día · Noche'),
        PokedexEncounter(location: 'Ruta 30', method: 'Hierba', time: 'Noche'),
      ],
    ),
    20: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 26', method: 'Hierba', time: 'Noche')]),
    163: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 29', method: 'Hierba', time: 'Noche')]),
    165: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 30', method: 'Hierba', time: 'Mañana · Día')]),
  };

  static const Map<int, PokedexSpeciesDetail> _goldSilver = {};
}
