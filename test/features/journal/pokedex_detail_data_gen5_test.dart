import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/journal/data/pokedex_detail_data.dart';
import 'package:retrohub/features/journal/data/pokedex_evolution_data.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_ability_resolver.dart';

void main() {
  final GameAssetProfile white = GameAssetProfile.fromTitle(
    title: 'Pokemon Blanca',
    console: 'nds',
  );
  final GameAssetProfile black = GameAssetProfile.fromTitle(
    title: 'Pokemon Negro',
    console: 'nds',
  );

  test('carga la ficha completa de Oshawott en Blanco y Negro', () {
    for (final GameAssetProfile profile in <GameAssetProfile>[white, black]) {
      final detail = PokedexDetailData.forGame(profile, 501);
      expect(detail.entry, isNotEmpty);
      expect(detail.encounters.map((value) => value.location), contains('Pueblo Arcilla'));
      expect(detail.levelMoves.map((value) => value.name), contains('Placaje'));
      expect(detail.machineMoves, isNotEmpty);
      expect(PokedexEvolutionData.forGame(profile, 501), contains('Dewott'));
    }
  });

  test('resuelve Torrente y Caparazón para Oshawott', () {
    expect(PokemonAbilityResolver.supports(white), isTrue);
    expect(PokemonAbilityResolver.current(white, 501, 1)?.name, 'Torrente');
    expect(PokemonAbilityResolver.current(white, 501, 2)?.name, 'Caparazón');
  });

  test('usa las reglas de evolución vigentes en Gen V', () {
    expect(PokedexEvolutionData.forGame(white, 513), contains('Piedra Fuego'));
    expect(PokedexEvolutionData.forGame(white, 27), contains('Nv. 22'));
    expect(PokedexEvolutionData.forGame(white, 52), contains('Nv. 28'));
    expect(PokedexEvolutionData.forGame(white, 79), allOf(contains('Nv. 37'), contains('Roca del Rey')));
    expect(PokedexEvolutionData.forGame(white, 100), contains('Nv. 30'));
    expect(PokedexEvolutionData.forGame(white, 554), contains('Nv. 35'));
    expect(PokedexEvolutionData.forGame(white, 588), contains('Shelmet'));
    expect(PokedexEvolutionData.forGame(white, 616), contains('Karrablast'));
  });

  test('no deja condiciones genéricas en las evoluciones de Gen V', () {
    for (var species = 1; species <= 649; species++) {
      final evolution = PokedexEvolutionData.forGame(white, species);
      expect(evolution, isNot(contains('objeto evolutivo correspondiente')), reason: 'Pokémon #$species');
      expect(evolution, isNot(contains('condición especial')), reason: 'Pokémon #$species');
    }
  });
}
