import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/core/assets/sprite_resolver.dart';

void main() {
  final profile = GameAssetProfile.fromTitle(
    title: 'Pokémon Platino',
    console: 'NDS',
  );

  test('resuelve el primer fotograma normal de Gen IV', () {
    expect(
      SpriteResolver.pokemonForGame(profile: profile, pokemonId: 25),
      'assets/sprites/pokemon/nds/platinum/0025.png',
    );
  });

  test('resuelve shiny femenino y segundo fotograma de Gen IV', () {
    expect(
      SpriteResolver.pokemonForGame(
        profile: profile,
        pokemonId: 25,
        isShiny: true,
        isFemale: true,
        secondFrame: true,
      ),
      'assets/sprites/pokemon/nds/platinum/shiny/female/frame2/0025.png',
    );
  });

  test('resuelve el nombre de huevo usado por Nintendo DS', () {
    expect(
      SpriteResolver.eggForGame(profile: profile),
      'assets/sprites/pokemon/nds/heartgold-soulsilver/0egg.png',
    );
  });

  test('resuelve los sprites propios de HeartGold y SoulSilver', () {
    final hgss = GameAssetProfile.fromTitle(
      title: 'Pokémon SoulSilver',
      console: 'NDS',
    );
    expect(
      SpriteResolver.pokemonForGame(profile: hgss, pokemonId: 250),
      'assets/sprites/pokemon/nds/heartgold-soulsilver/0250.png',
    );
  });
}
