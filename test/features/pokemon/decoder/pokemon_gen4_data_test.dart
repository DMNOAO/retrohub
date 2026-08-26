import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/pokemon/decoder/move_type_resolver.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_decoder.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_gen4_text_decoder.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_type_resolver.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  test('decodifica texto internacional de Gen IV', () {
    expect(
      PokemonGen4TextDecoder.decodeWords(
        const <int>[
          0x12B,
          0x145,
          0x170,
          0x190,
          0x176,
          0x196,
          0x192,
          0x1DE,
          0x121,
          0xFFFF,
        ],
      ),
      'AaÑñ×÷ó 0',
    );
  });

  test('resuelve los tipos de Chimchar y sus evoluciones', () {
    final GameAssetProfile profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Platino',
      console: 'nds',
    );
    expect(PokemonTypeResolver.resolve(profile, 390), <PokemonMoveType>[PokemonMoveType.fire]);
    expect(PokemonTypeResolver.resolve(profile, 391), <PokemonMoveType>[PokemonMoveType.fire, PokemonMoveType.fighting]);
    expect(PokemonTypeResolver.resolve(profile, 392), <PokemonMoveType>[PokemonMoveType.fire, PokemonMoveType.fighting]);
    expect(
      profile.femaleProtagonistAsset,
      'assets/sprites/characters/protagonists/dawn_pt.png',
    );
  });

  test('muestra ubicaciones de Sinnoh en Diamante, Perla y Platino', () {
    final PokemonGameProfile diamond = PokemonGameProfile.fromRomPath('Pokemon Diamond.nds');
    final PokemonGameProfile pearl = PokemonGameProfile.fromRomPath('Pokemon Pearl.nds');
    expect(PokemonDecoder.mapName(diamond, 411), 'Pueblo Hojaverde');
    expect(PokemonDecoder.locationFor(diamond, 411)?.kind, PokemonLocationKind.city);
    expect(PokemonDecoder.mapName(pearl, 418), 'Pueblo Arena');

    final PokemonGameProfile profile = PokemonGameProfile.fromRomPath('Pokemon Platinum.nds');
    expect(PokemonDecoder.mapName(profile, 342), 'Ruta 201');
    expect(PokemonDecoder.locationFor(profile, 342)?.kind, PokemonLocationKind.route);
  });
}
