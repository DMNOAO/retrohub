import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_learnset_resolver.dart';

void main() {
  final fireRed = GameAssetProfile.fromTitle(
    title: 'Pokémon Rojo Fuego',
    console: 'GBA',
  );
  final crystal = GameAssetProfile.fromTitle(
    title: 'Pokémon Cristal',
    console: 'GBC',
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

  test('informa padres compatibles para cada movimiento huevo', () {
    final leechSeedParents = PokemonLearnsetResolver.eggMoveParents(
      fireRed,
      252,
      73,
    );

    expect(leechSeedParents, contains(1));
    expect(leechSeedParents, contains(357));
  });

  test('ignora preevoluciones introducidas en generaciones posteriores', () {
    expect(PokemonLearnsetResolver.baseSpeciesId(fireRed, 315), 315);
  });

  test('Elekid usa el grupo huevo de Electabuzz y no el de Magby', () {
    expect(
      PokemonLearnsetResolver.eggMoveParents(crystal, 239, 112),
      <int>[122],
    );
    expect(
      PokemonLearnsetResolver.eggMoveParents(crystal, 239, 238),
      <int>[66],
    );
  });

  test('reduce los padres a la primera fuente válida de cada familia', () {
    expect(
      PokemonLearnsetResolver.eggMoveParents(crystal, 239, 96),
      <int>[96, 106, 122],
    );
    expect(
      PokemonLearnsetResolver.eggMoveParents(crystal, 239, 27),
      <int>[106, 237],
    );
  });
}
