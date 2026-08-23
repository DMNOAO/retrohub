import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/journal/data/pokedex_evolution_data.dart';

void main() {
  final fireRedProfile = GameAssetProfile.fromTitle(
    title: 'Pokemon_Rojo_Fuego',
    console: 'GBA',
  );
  final crystalProfile = GameAssetProfile.fromTitle(
    title: 'Pokemon_Cristal',
    console: 'GBC',
  );

  test('muestra la evolución por nivel de Charmander en FRLG', () {
    expect(
      PokedexEvolutionData.forGame(fireRedProfile, 4),
      'Evoluciona a Charmeleon al Nv. 16.',
    );
  });

  test('muestra las evoluciones por piedra de Eevee en FRLG', () {
    final result = PokedexEvolutionData.forGame(fireRedProfile, 133);

    expect(result, contains('Vaporeon'));
    expect(result, contains('Piedra Agua'));
    expect(result, contains('transfiérelo'));
    expect(result.split('\n'), hasLength(4));
  });

  test('separa todas las evoluciones de Eevee en Crystal', () {
    final options = PokedexEvolutionData.forGame(crystalProfile, 133).split('\n');

    expect(options, hasLength(5));
    expect(options, contains('Espeon con amistad alta de día.'));
    expect(options, contains('Umbreon con amistad alta de noche.'));
  });
}
