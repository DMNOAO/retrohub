import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';

void main() {
  test('reconoce los juegos de Sinnoh como bitácoras Pokémon', () {
    final diamond = GameAssetProfile.fromTitle(
      title: 'Pokémon Diamante',
      console: 'NDS',
    );
    final platinum = GameAssetProfile.fromTitle(
      title: 'Pokémon Platinum',
      console: 'NDS',
    );

    expect(diamond.game, PokemonAssetGame.diamondPearl);
    expect(platinum.game, PokemonAssetGame.platinum);
    expect(diamond.region, PokemonAssetRegion.sinnoh);
    expect(platinum.region, PokemonAssetRegion.sinnoh);
    expect(diamond.pokemonSpriteSet, 'nds/diamond-pearl');
    expect(platinum.pokemonSpriteSet, 'nds/platinum');
    expect(
      diamond.rivalAsset,
      'assets/sprites/characters/rivals/barry_dp.png',
    );
    expect(
      platinum.rivalAsset,
      'assets/sprites/characters/rivals/barry_pt.gif',
    );
    expect(diamond.supportsPokemonJournal, isTrue);
    expect(platinum.supportsPokemonJournal, isTrue);
  });

  test('usa los recursos GBA para Rojo Fuego con guiones bajos', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokemon_Rojo_Fuego',
      console: 'GBA',
    );

    expect(profile.game, PokemonAssetGame.fireRedLeafGreen);
    expect(profile.region, PokemonAssetRegion.kanto);
    expect(profile.pokemonSpriteSet, 'gba/fire_red_leaf_green');
    expect(profile.femaleProtagonistAsset, contains('leaf_'));
    expect(
      profile.protagonistAsset,
      'assets/sprites/characters/protagonists/red_fire_red_leaf_green.png',
    );
  });

  test('incluye protagonistas femeninas en todas las ediciones compatibles', () {
    final titles = <String>[
      'Pokémon Cristal',
      'Pokémon Rubí',
      'Pokémon Esmeralda',
      'Pokémon Verde Hoja',
      'Pokémon Perla',
      'Pokémon Platino',
      'Pokémon HeartGold',
      'Pokémon Blanco',
      'Pokémon Negro 2',
    ];

    for (final title in titles) {
      final profile = GameAssetProfile.fromTitle(title: title, console: 'NDS');
      expect(profile.femaleProtagonistAsset, isNotNull, reason: title);
    }
  });

  test('reconoce HGSS y usa sus sprites NDS de Johto', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon HeartGold',
      console: 'NDS',
    );

    expect(profile.game, PokemonAssetGame.heartGoldSoulSilver);
    expect(profile.region, PokemonAssetRegion.johto);
    expect(profile.pokemonSpriteSet, 'nds/heartgold-soulsilver');
    expect(profile.trainerSpriteSet, 'nds/Johto');
    expect(
      profile.rivalAsset,
      'assets/sprites/characters/rivals/silver_hgss.gif',
    );
    expect(profile.supportsPokemonJournal, isTrue);
  });

  test('usa los recursos GBA para Verde Hoja con guiones', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokemon-Verde-Hoja',
      console: 'GBA',
    );

    expect(profile.game, PokemonAssetGame.fireRedLeafGreen);
    expect(profile.pokemonSpriteSet, 'gba/fire_red_leaf_green');
  });

  test('detecta Blanco y Negro con los recursos de Teselia', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Negra',
      console: 'NDS',
    );

    expect(profile.game, PokemonAssetGame.blackWhite);
    expect(profile.region, PokemonAssetRegion.unova);
    expect(profile.pokemonSpriteSet, 'nds/gen5');
    expect(profile.protagonistAsset, contains('hilbert_bw'));
    expect(profile.femaleProtagonistAsset, contains('hilda_bw'));
    expect(profile.rivalAsset, contains('cheren_bw'));
  });

  test('las secuelas se resuelven antes que Blanco y Negro', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Blanco 2',
      console: 'NDS',
    );

    expect(profile.game, PokemonAssetGame.black2White2);
    expect(profile.protagonistAsset, contains('nate_bw2'));
    expect(profile.femaleProtagonistAsset, contains('rosa_bw2'));
    expect(profile.rivalAsset, contains('hugh_bw2'));
    expect(profile.championAsset, contains('iris_unova_bw2'));
  });

  test('habilita la bitácora únicamente para perfiles Pokémon compatibles', () {
    final pokemon = GameAssetProfile.fromTitle(
      title: 'Pokemon_Esmeralda',
      console: 'GBA',
    );
    final mario = GameAssetProfile.fromTitle(
      title: 'Super Mario World',
      console: 'SNES',
    );

    expect(pokemon.supportsPokemonJournal, isTrue);
    expect(mario.supportsPokemonJournal, isFalse);
  });
}
