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
}
