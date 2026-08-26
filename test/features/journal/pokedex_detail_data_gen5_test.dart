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
}
