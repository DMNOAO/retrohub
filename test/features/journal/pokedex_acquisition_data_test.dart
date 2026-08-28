import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/journal/data/pokedex_acquisition_data.dart';

void main() {
  GameAssetProfile profile(String title, String console) =>
      GameAssetProfile.fromTitle(title: title, console: console);

  test('carga regalos e intercambios especiales de Kanto', () {
    final red = profile('Pokemon_Rojo', 'GB');

    expect(
      PokedexAcquisitionData.forGame(red, 131).single.location,
      contains('Silph'),
    );
    expect(
      PokedexAcquisitionData.forGame(red, 133).single.method,
      'Regalo',
    );
    expect(
      PokedexAcquisitionData.forGame(red, 122).single.detail,
      contains('Abra'),
    );
    expect(
      PokedexAcquisitionData.forGame(red, 106).single.detail,
      contains('elegir'),
    );
  });

  test('adapta el intercambio de Mr. Mime en Amarillo', () {
    final yellow = profile('Pokemon_Amarillo', 'GBC');

    expect(
      PokedexAcquisitionData.forGame(yellow, 122).single.detail,
      contains('Clefairy'),
    );
  });

  test('informa exclusivos de la otra versión de Johto', () {
    final gold = profile('Pokemon_Oro', 'GBC');
    final silver = profile('Pokemon_Plata', 'GBC');

    expect(
      PokedexAcquisitionData.forGame(gold, 37).single.method,
      'Otra versión',
    );
    expect(
      PokedexAcquisitionData.forGame(silver, 58).single.location,
      'Pokémon Oro',
    );
  });

  test('carga los regalos y encuentros especiales de Johto', () {
    final crystal = profile('Pokemon_Cristal', 'GBC');

    expect(
      PokedexAcquisitionData.forGame(
        crystal,
        236,
      ).map((item) => item.location),
      containsAll(['Guardería Pokémon · Ruta 34', 'Monte Mortero']),
    );
    expect(
      PokedexAcquisitionData.forGame(crystal, 131).single.detail,
      contains('viernes'),
    );
  });

  test('distingue regalos y premios entre Rojo, Azul y Amarillo', () {
    final red = profile('Pokemon_Rojo', 'GB');
    final blue = profile('Pokemon_Azul', 'GB');
    final yellow = profile('Pokemon_Amarillo', 'GBC');

    expect(
      PokedexAcquisitionData.forGame(red, 123).single.detail,
      contains('5500'),
    );
    expect(
      PokedexAcquisitionData.forGame(blue, 127).single.detail,
      contains('2500'),
    );
    expect(
      PokedexAcquisitionData.forGame(yellow, 7).single.detail,
      contains('Medalla Trueno'),
    );
    expect(
      PokedexAcquisitionData.forGame(yellow, 68).single.detail,
      contains('evoluciona inmediatamente'),
    );
  });

  test('carga fósiles, legendarios y Pokémon de evento de Kanto', () {
    final red = profile('Pokemon_Rojo', 'GB');

    expect(
      PokedexAcquisitionData.forGame(red, 138).single.method,
      'Restauración de fósil',
    );
    expect(
      PokedexAcquisitionData.forGame(red, 150).single.location,
      'Cueva Celeste',
    );
    expect(
      PokedexAcquisitionData.forGame(red, 151).single.method,
      'Evento',
    );
  });

  test('no marca como ausente un Pokémon obtenido por intercambio', () {
    final yellow = profile('Pokemon_Amarillo', 'GBC');
    final muk = PokedexAcquisitionData.forGame(yellow, 89);
    final koffing = PokedexAcquisitionData.forGame(yellow, 109);

    expect(muk.map((item) => item.method), contains('Intercambio con NPC'));
    expect(muk.map((item) => item.method), isNot(contains('Otra versión')));
    expect(koffing.single.method, 'Otra versión');
  });

  test('distingue intercambios de Oro/Plata y Cristal', () {
    final gold = profile('Pokemon_Oro', 'GBC');
    final crystal = profile('Pokemon_Cristal', 'GBC');

    expect(
      PokedexAcquisitionData.forGame(gold, 66).single.detail,
      contains('Drowzee'),
    );
    expect(
      PokedexAcquisitionData.forGame(crystal, 66).single.detail,
      contains('Abra'),
    );
    expect(
      PokedexAcquisitionData.forGame(crystal, 178).single.detail,
      contains('Haunter'),
    );
  });

  test('informa especies ausentes de Cristal y Cápsula del Tiempo', () {
    final crystal = profile('Pokemon_Cristal', 'GBC');

    expect(
      PokedexAcquisitionData.forGame(crystal, 179).single.location,
      'Pokémon Oro o Plata',
    );
    expect(
      PokedexAcquisitionData.forGame(crystal, 144).single.method,
      'Cápsula del Tiempo',
    );
    expect(
      PokedexAcquisitionData.forGame(crystal, 142).single.method,
      'Intercambio con NPC',
    );
  });
}
