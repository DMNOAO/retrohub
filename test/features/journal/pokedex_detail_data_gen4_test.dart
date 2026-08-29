import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/journal/data/pokedex_detail_data.dart';
import 'package:retrohub/features/journal/data/pokedex_evolution_data.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_ability_resolver.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_learnset_resolver.dart';
import 'package:retrohub/features/pokemon/decoder/move_name_resolver.dart';

void main() {
  final diamond = GameAssetProfile.fromTitle(
    title: 'Pokémon Diamante',
    console: 'NDS',
  );
  final platinum = GameAssetProfile.fromTitle(
    title: 'Pokémon Platino',
    console: 'NDS',
  );

  test('Chimchar tiene ficha completa en Diamante', () {
    final detail = PokedexDetailData.forGame(diamond, 390);

    expect(detail.entry, isNotEmpty);
    expect(detail.levelMoves, isNotEmpty);
    expect(detail.machineMoves, isNotEmpty);
    expect(detail.encounters.first.location, 'Lago Veraz');
    expect(PokedexEvolutionData.forGame(diamond, 390), contains('Monferno'));
  });

  test('Chimchar muestra Mar Llamas y movimientos de Gen IV', () {
    expect(PokemonAbilityResolver.current(diamond, 390, 1)?.name, 'Mar Llamas');
    expect(PokemonAbilityResolver.current(platinum, 390, 1)?.name, 'Mar Llamas');
    expect(PokemonLearnsetResolver.tutorMoves(platinum, 390), isNotEmpty);
    expect(PokemonLearnsetResolver.eggMoves(diamond, 392), isNotEmpty);
    expect(PokemonLearnsetResolver.baseSpeciesId(diamond, 392), 390);
    expect(MoveNameResolver.resolve(394), 'Envite Ígneo');
  });

  test('describe objetos y condiciones especiales de Gen IV en español', () {
    expect(PokedexEvolutionData.forGame(platinum, 37), contains('Piedra Fuego'));
    expect(PokedexEvolutionData.forGame(platinum, 108), contains('Rodar'));
    expect(PokedexEvolutionData.forGame(platinum, 114), contains('Poder Pasado'));
    expect(PokedexEvolutionData.forGame(platinum, 215), contains('Garra Afilada'));
    expect(PokedexEvolutionData.forGame(platinum, 440), allOf(contains('Piedra Oval'), contains('de día')));
    expect(PokedexEvolutionData.forGame(platinum, 458), contains('Remoraid'));
  });

  test('no deja condiciones genéricas en las evoluciones de Gen IV', () {
    for (var species = 1; species <= 493; species++) {
      final evolution = PokedexEvolutionData.forGame(platinum, species);
      expect(evolution, isNot(contains('condición especial')), reason: 'Pokémon #$species');
      expect(evolution, isNot(contains('movimiento requerido')), reason: 'Pokémon #$species');
    }
  });
}
