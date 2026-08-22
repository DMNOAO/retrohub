import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';

void main() {
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
}
