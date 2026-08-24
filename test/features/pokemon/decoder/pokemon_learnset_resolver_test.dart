import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_learnset_resolver.dart';

void main() {
  final fireRed = GameAssetProfile.fromTitle(
    title: 'Pokémon Rojo Fuego',
    console: 'GBA',
  );

  test('incluye Planta Feroz entre los tutores de Venusaur', () {
    expect(PokemonLearnsetResolver.tutorMoves(fireRed, 3), contains(338));
  });

  test('las evoluciones consultan los movimientos huevo de la primera fase', () {
    final treeckoMoves = PokemonLearnsetResolver.eggMoves(fireRed, 252);

    expect(treeckoMoves, isNotEmpty);
    expect(PokemonLearnsetResolver.baseSpeciesId(fireRed, 254), 252);
    expect(PokemonLearnsetResolver.eggMoves(fireRed, 254), treeckoMoves);
  });

  test('ignora preevoluciones introducidas en generaciones posteriores', () {
    expect(PokemonLearnsetResolver.baseSpeciesId(fireRed, 315), 315);
  });
}
