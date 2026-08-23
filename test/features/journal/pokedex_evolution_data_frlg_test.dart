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
  final emeraldProfile = GameAssetProfile.fromTitle(
    title: 'Pokemon_Esmeralda',
    console: 'GBA',
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

  test('corrige evoluciones omitidas y posteriores a Gen III', () {
    expect(
      PokedexEvolutionData.forGame(crystalProfile, 183),
      'Evoluciona a Azumarill al Nv. 18.',
    );
    expect(
      PokedexEvolutionData.forGame(crystalProfile, 126),
      'No evoluciona en esta generación.',
    );
    expect(
      PokedexEvolutionData.forGame(crystalProfile, 125),
      'No evoluciona en esta generación.',
    );
    expect(
      PokedexEvolutionData.forGame(crystalProfile, 218),
      'Evoluciona a Magcargo al Nv. 38.',
    );
    expect(
      PokedexEvolutionData.forGame(emeraldProfile, 299),
      'No evoluciona en esta generación.',
    );
  });

  test('separa las ramas evolutivas especiales de Hoenn', () {
    final wurmple = PokedexEvolutionData.forGame(emeraldProfile, 265).split('\n');
    final nincada = PokedexEvolutionData.forGame(emeraldProfile, 290).split('\n');

    expect(wurmple, hasLength(2));
    expect(wurmple.first, contains('Silcoon'));
    expect(wurmple.last, contains('Cascoon'));
    expect(nincada, hasLength(2));
    expect(nincada.last, contains('Shedinja'));
    expect(
      PokedexEvolutionData.forGame(crystalProfile, 44).split('\n'),
      hasLength(2),
    );
  });
}
