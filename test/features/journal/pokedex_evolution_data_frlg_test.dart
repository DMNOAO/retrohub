import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/journal/data/pokedex_evolution_data.dart';

void main() {
  final profile = GameAssetProfile.fromTitle(
    title: 'Pokemon_Rojo_Fuego',
    console: 'GBA',
  );

  test('muestra la evolución por nivel de Charmander en FRLG', () {
    expect(
      PokedexEvolutionData.forGame(profile, 4),
      'Evoluciona a Charmeleon al Nv. 16.',
    );
  });

  test('muestra las evoluciones por piedra de Eevee en FRLG', () {
    final result = PokedexEvolutionData.forGame(profile, 133);

    expect(result, contains('Vaporeon'));
    expect(result, contains('Piedra Agua'));
    expect(result, contains('transferirlo'));
  });
}
