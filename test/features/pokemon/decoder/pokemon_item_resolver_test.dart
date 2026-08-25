import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_item_resolver.dart';

void main() {
  test('resuelve objetos con los identificadores internos de Cristal', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Cristal',
      console: 'GBC',
    );

    expect(PokemonItemResolver.resolve(profile, 0x6c), 'Imán');
    expect(PokemonItemResolver.resolve(profile, 0x8a), 'Carbón');
    expect(PokemonItemResolver.resolve(profile, 0x83), 'Polvo Estelar');
  });

  test('mantiene separados los identificadores de tercera generación', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Esmeralda',
      console: 'GBA',
    );

    expect(PokemonItemResolver.resolve(profile, 108), 'Polvo Estelar');
    expect(PokemonItemResolver.resolve(profile, 138), 'Baya Zanama');
  });
}
