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

  test('muestra la cadena completa desde cualquier etapa', () {
    final feraligatr = PokedexEvolutionData.chainForGame(crystalProfile, 160);
    final raticate = PokedexEvolutionData.chainForGame(crystalProfile, 20);

    expect(feraligatr, hasLength(1));
    expect(feraligatr.single, contains('Totodile'));
    expect(feraligatr.single, contains('Croconaw'));
    expect(feraligatr.single, contains('[Feraligatr]'));
    expect(raticate.single, contains('Rattata'));
    expect(raticate.single, contains('[Raticate]'));
  });

  test('conserva todas las ramas y destaca la especie consultada', () {
    final eevee = PokedexEvolutionData.chainForGame(crystalProfile, 133);

    expect(eevee, hasLength(5));
    expect(eevee.every((route) => route.contains('[Eevee]')), isTrue);
    expect(eevee.any((route) => route.contains('Espeon')), isTrue);
    expect(eevee.any((route) => route.contains('Umbreon')), isTrue);
  });

  test('expone la preevolución como método de obtención', () {
    expect(
      PokedexEvolutionData.evolvesFromForGame(crystalProfile, 160),
      contains('Evoluciona de Croconaw · Nivel 30'),
    );
    expect(
      PokedexEvolutionData.evolvesFromForGame(crystalProfile, 20),
      contains('Evoluciona de Rattata · Nivel 20'),
    );
  });
}
