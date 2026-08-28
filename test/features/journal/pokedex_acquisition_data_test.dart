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
      PokedexAcquisitionData.forGame(crystal, 236).single.location,
      'Monte Mortero',
    );
    expect(
      PokedexAcquisitionData.forGame(crystal, 131).single.detail,
      contains('viernes'),
    );
  });
}
