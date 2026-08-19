import '../../../core/assets/game_asset_profile.dart';
import 'blue_pokedex_generated.dart';
import 'crystal_pokedex_generated.dart';
import 'gold_pokedex_generated.dart';
import 'red_pokedex_generated.dart';
import 'silver_pokedex_generated.dart';
import 'yellow_pokedex_generated.dart';
import 'pokedex_models.dart';

export 'pokedex_models.dart';

class PokedexDetailData {
  const PokedexDetailData._();

  static PokedexSpeciesDetail forGame(GameAssetProfile profile, int pokemonId) {
    switch (profile.game) {
      case PokemonAssetGame.redBlue:
        final title = profile.sourceTitle ?? '';
        final isBlue = title.contains('azul') || title.contains('blue');
        return (isBlue ? blueGeneratedSpecies : redGeneratedSpecies)[pokemonId] ?? const PokedexSpeciesDetail();
      case PokemonAssetGame.yellow:
        return yellowGeneratedSpecies[pokemonId] ?? const PokedexSpeciesDetail();
      case PokemonAssetGame.crystal:
        final generated = crystalGeneratedSpecies[pokemonId] ?? const PokedexSpeciesDetail();
        final local = _crystalOverrides[pokemonId] ?? const PokedexSpeciesDetail();
        return generated.merge(local);
      case PokemonAssetGame.gold:
        return goldGeneratedSpecies[pokemonId] ?? const PokedexSpeciesDetail();
      case PokemonAssetGame.silver:
        return silverGeneratedSpecies[pokemonId] ?? const PokedexSpeciesDetail();
      default:
        return const PokedexSpeciesDetail();
    }
  }

  static const Map<int, PokedexSpeciesDetail> _crystalOverrides = {
    16: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Rutas 29, 30, 31 y 32', method: 'Hierba', time: 'Mañana · Día'), PokedexEncounter(location: 'Rutas 34, 35, 36 y 37', method: 'Hierba', time: 'Mañana · Día'), PokedexEncounter(location: 'Bosque Encinar · Parque Nacional', method: 'Hierba', time: 'Mañana · Día'), PokedexEncounter(location: 'Rutas 1, 2, 5 y 25', method: 'Hierba', time: 'Mañana · Día')]),
    19: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 29', method: 'Hierba', time: 'Mañana · Día · Noche'), PokedexEncounter(location: 'Ruta 30', method: 'Hierba', time: 'Noche')]),
    20: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 26', method: 'Hierba', time: 'Noche')]),
    92: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Rutas 31, 32 y 36', method: 'Hierba', time: 'Noche'), PokedexEncounter(location: 'Torre Bellsprout', method: 'Interior', time: 'Noche'), PokedexEncounter(location: 'Torre Hojalata', method: 'Interior', time: 'Noche')]),
    158: PokedexSpeciesDetail(entry: 'Este pequeño y rudo Pokémon muerde cualquier cosa que se mueva. No es recomendable darle la espalda.', encounters: [PokedexEncounter(location: 'Pueblo Primavera', method: 'Pokémon inicial de Prof. Elm', time: 'Cualquier hora')]),
    159: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Evolución', method: 'Evoluciona de Totodile', time: 'Nivel 18')]),
    163: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 29', method: 'Hierba', time: 'Noche'), PokedexEncounter(location: 'Rutas 30, 31, 35, 36 y 37', method: 'Hierba', time: 'Noche')]),
    165: PokedexSpeciesDetail(encounters: [PokedexEncounter(location: 'Ruta 30', method: 'Hierba', time: 'Mañana · Día'), PokedexEncounter(location: 'Ruta 36', method: 'Hierba', time: 'Mañana')]),
  };
}
