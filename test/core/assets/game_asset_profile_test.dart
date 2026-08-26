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
    expect(
      profile.protagonistAsset,
      'assets/sprites/characters/protagonists/red_fire_red_leaf_green.png',
    );
  });

  test('usa los recursos GBA para Verde Hoja con guiones', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokemon-Verde-Hoja',
      console: 'GBA',
    );

    expect(profile.game, PokemonAssetGame.fireRedLeafGreen);
    expect(profile.pokemonSpriteSet, 'gba/fire_red_leaf_green');
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
