import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  group('PokemonGameProfile Gen III', () {
    final cases = <({
      String identity,
      PokemonGameVersion version,
      String displayName,
    })>[
      (
        identity: 'Pokemon Ruby.gba',
        version: PokemonGameVersion.ruby,
        displayName: 'Pokémon Ruby',
      ),
      (
        identity: 'Pokémon Zafiro.gba',
        version: PokemonGameVersion.sapphire,
        displayName: 'Pokémon Sapphire',
      ),
      (
        identity: 'Pokemon Esmeralda.gba',
        version: PokemonGameVersion.emerald,
        displayName: 'Pokémon Emerald',
      ),
      (
        identity: 'Pokemon FireRed.gba',
        version: PokemonGameVersion.fireRed,
        displayName: 'Pokémon FireRed',
      ),
      (
        identity: 'Pokémon Verde Hoja.gba',
        version: PokemonGameVersion.leafGreen,
        displayName: 'Pokémon LeafGreen',
      ),
    ];

    for (final testCase in cases) {
      test('reconoce ${testCase.identity} sin habilitar memoria', () {
        final profile = PokemonGameProfile.fromGameIdentity(
          gameTitle: testCase.identity,
          romPath: 'roms/${testCase.identity}',
        );

        expect(profile.version, testCase.version);
        expect(profile.generation, PokemonGeneration.gen3);
        expect(profile.displayName, testCase.displayName);
        expect(profile.isGen3, isTrue);
        expect(profile.memoryMapVerified, isFalse);
        expect(profile.addresses, isNull);
      });
    }

    test('FireRed no se confunde con Red/Blue', () {
      final profile = PokemonGameProfile.fromRomPath(
        'roms/Pokemon FireRed.gba',
      );

      expect(profile.version, PokemonGameVersion.fireRed);
      expect(profile.isGen1, isFalse);
    });
  });
}
