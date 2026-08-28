import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/journal/data/pokedex_acquisition_data.dart';

void main() {
  GameAssetProfile profile(String title, String console) =>
      GameAssetProfile.fromTitle(title: title, console: console);

  test('distingue legendarios y eventos entre Rubí, Zafiro y Esmeralda', () {
    final ruby = profile('Pokemon_Rubi', 'GBA');
    final sapphire = profile('Pokemon_Zafiro', 'GBA');
    final emerald = profile('Pokemon_Esmeralda', 'GBA');

    expect(PokedexAcquisitionData.forGame(ruby, 383).single.method, 'Encuentro único');
    expect(PokedexAcquisitionData.forGame(sapphire, 383).single.method, 'Otra versión');
    expect(PokedexAcquisitionData.forGame(emerald, 151).single.location, 'Isla Suprema');
  });

  test('adapta los intercambios NPC de Rojo Fuego y Verde Hoja', () {
    final fireRed = profile('Pokemon_FireRed', 'GBA');
    final leafGreen = profile('Pokemon_LeafGreen', 'GBA');

    expect(PokedexAcquisitionData.forGame(fireRed, 108).single.detail, contains('Golduck'));
    expect(PokedexAcquisitionData.forGame(leafGreen, 108).single.detail, contains('Slowbro'));
    expect(PokedexAcquisitionData.forGame(fireRed, 133).single.method, 'Regalo');
  });

  test('separa fósiles y legendarios exclusivos de Diamante y Perla', () {
    final diamond = profile('Pokemon_Diamante', 'NDS');
    final pearl = profile('Pokemon_Perla', 'NDS');

    expect(PokedexAcquisitionData.forGame(diamond, 408).single.method, 'Restauración de fósil');
    expect(PokedexAcquisitionData.forGame(pearl, 408).single.method, 'Otra versión');
    expect(PokedexAcquisitionData.forGame(diamond, 483).single.method, 'Encuentro único');
    expect(PokedexAcquisitionData.forGame(pearl, 483).single.method, 'Otra versión');
  });

  test('incluye los eventos principales de Sinnoh', () {
    final platinum = profile('Pokemon_Platino', 'NDS');

    expect(PokedexAcquisitionData.forGame(platinum, 489).single.detail, contains('Ranger'));
    expect(PokedexAcquisitionData.forGame(platinum, 491).single.location, 'Isla Lunanueva');
    expect(PokedexAcquisitionData.forGame(platinum, 492).single.location, 'Paraíso Floral');
    expect(PokedexAcquisitionData.forGame(platinum, 493).single.detail, contains('Flauta Azur'));
  });

  test('distingue los legendarios de HeartGold y SoulSilver', () {
    final heartGold = profile('Pokemon_HeartGold', 'NDS');
    final soulSilver = profile('Pokemon_SoulSilver', 'NDS');

    expect(PokedexAcquisitionData.forGame(heartGold, 382).single.method, 'Encuentro único');
    expect(PokedexAcquisitionData.forGame(soulSilver, 382).single.method, 'Otra versión');
    expect(PokedexAcquisitionData.forGame(soulSilver, 383).single.method, 'Encuentro único');
    expect(PokedexAcquisitionData.forGame(heartGold, 251).single.method, 'Evento');
  });

  test('incluye árboles y Concurso de Captura de Bichos en HGSS', () {
    final heartGold = profile('Pokemon_HeartGold', 'NDS');

    for (final id in [102, 190, 204, 214]) {
      expect(
        PokedexAcquisitionData.forGame(heartGold, id).map((item) => item.method),
        contains('Golpe Cabeza'),
      );
    }
    expect(
      PokedexAcquisitionData.forGame(heartGold, 123).single.location,
      'Parque Nacional',
    );
  });

  test('distingue dragones y eventos de Pokémon Negro y Blanco', () {
    final black = profile('Pokemon_Negro', 'NDS');
    final white = profile('Pokemon_Blanco', 'NDS');

    expect(PokedexAcquisitionData.forGame(black, 643).single.method, 'Encuentro único');
    expect(PokedexAcquisitionData.forGame(white, 643).single.method, 'Otra versión');
    expect(PokedexAcquisitionData.forGame(white, 644).single.method, 'Encuentro único');
    expect(PokedexAcquisitionData.forGame(black, 494).single.location, 'Isla Libertad');
  });

  test('carga regalos y llaves exclusivas de Negro 2 y Blanco 2', () {
    final black2 = profile('Pokemon_Negro_2', 'NDS');
    final white2 = profile('Pokemon_Blanco_2', 'NDS');

    expect(PokedexAcquisitionData.forGame(black2, 443).single.detail, contains('variocolor'));
    expect(PokedexAcquisitionData.forGame(white2, 147).single.detail, contains('variocolor'));
    expect(PokedexAcquisitionData.forGame(black2, 379).single.method, 'Encuentro único');
    expect(PokedexAcquisitionData.forGame(white2, 379).single.method, 'Otra versión');
  });
}
