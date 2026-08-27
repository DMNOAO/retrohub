import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/character_asset_resolver.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';

void main() {
  test('Diamante y Platino comparten las clases de Sinnoh', () {
    final diamond = GameAssetProfile.fromTitle(
      title: 'Pokémon Diamante',
      console: 'NDS',
    );
    final platinum = GameAssetProfile.fromTitle(
      title: 'Pokémon Platino',
      console: 'NDS',
    );

    const expected =
        'assets/sprites/characters/trainers/nds/Sinnoh/'
        'entrenador_guay_sinnoh_gen4.png';
    expect(
      CharacterAssetResolver.trainer(
        profile: diamond,
        trainerClass: 'Entrenador guay',
      ),
      expected,
    );
    expect(
      CharacterAssetResolver.trainer(
        profile: platinum,
        trainerClass: 'Entrenador guay',
      ),
      expected,
    );
  });

  test('normaliza género y tildes en las clases de Nintendo DS', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Platino',
      console: 'NDS',
    );

    expect(
      CharacterAssetResolver.trainer(
        profile: profile,
        trainerClass: 'Pokémon Ranger (mujer)',
      ),
      'assets/sprites/characters/trainers/nds/Sinnoh/'
      'pokemon_ranger_mujer_sinnoh_gen4.png',
    );
    expect(
      CharacterAssetResolver.trainer(
        profile: profile,
        trainerClass: 'Chico ninja',
      ),
      'assets/sprites/characters/trainers/nds/Sinnoh/'
      'chico_ninja_sinnoh_gen4.png',
    );
    expect(
      CharacterAssetResolver.trainer(
        profile: profile,
        trainerClass: 'Obrero',
      ),
      'assets/sprites/characters/trainers/nds/Sinnoh/'
      'obrero_sinnoh_gen4.png',
    );
  });

  test('distingue las dos variantes de Operario de Teselia', () {
    const profile = GameAssetProfile(
      game: PokemonAssetGame.unsupported,
      region: PokemonAssetRegion.unknown,
      pokemonSpriteSet: 'nds/gen5',
      pokemonExtension: 'png',
      trainerSpriteSet: 'nds/Unova',
    );

    expect(
      CharacterAssetResolver.trainer(
        profile: profile,
        trainerClass: 'Operario',
      ),
      'assets/sprites/characters/trainers/nds/Unova/'
      'operario_unova_gen5.gif',
    );
    expect(
      CharacterAssetResolver.trainer(
        profile: profile,
        trainerClass: 'Operario (hielo)',
      ),
      'assets/sprites/characters/trainers/nds/Unova/'
      'operario_hielo_unova_gen5.gif',
    );
  });

  test('resuelve un sprite neutral para combates NDS sin clase', () {
    final platinum = GameAssetProfile.fromTitle(
      title: 'Pokémon Platino',
      console: 'NDS',
    );
    final white = GameAssetProfile.fromTitle(
      title: 'Pokémon Blanca',
      console: 'NDS',
    );

    expect(
      CharacterAssetResolver.genericTrainer(platinum),
      'assets/sprites/characters/trainers/nds/Sinnoh/'
      'entrenador_guay_sinnoh_gen4.png',
    );
    expect(
      CharacterAssetResolver.genericTrainer(white),
      'assets/sprites/characters/trainers/nds/Unova/'
      'entrenador_guay_unova_gen5.gif',
    );
  });

  test('resuelve los Jefes Metro de Blanco 2 y Negro 2', () {
    expect(
      CharacterAssetResolver.specialTrainer('Caril'),
      'assets/sprites/characters/special_trainers/caril_unova_bw2.gif',
    );
    expect(
      CharacterAssetResolver.specialTrainer('Fero'),
      'assets/sprites/characters/special_trainers/fero_unova_bw2.gif',
    );
  });
}
