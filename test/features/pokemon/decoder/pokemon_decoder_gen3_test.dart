import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_decoder.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  group('PokemonDecoder Gen III', () {
    test('decodifica letras, números y terminador', () {
      expect(
        PokemonDecoder.decodeGen3Text(
          <int>[0xBE, 0xBB, 0xC7, 0xC3, 0xBB, 0xC8, 0xA1, 0xFF, 0xBB],
        ),
        'DAMIAN0',
      );
    });

    test('ignora bytes no soportados sin inventar caracteres', () {
      expect(
        PokemonDecoder.decodeGen3Text(<int>[0xBB, 0x01, 0xBC, 0xFF]),
        'AB',
      );
    });

    test('traduce los mapas iniciales de Esmeralda', () {
      final PokemonGameProfile profile =
          PokemonGameProfile.fromGameIdentity(
        gameTitle: 'Pokémon Esmeralda',
        romPath: 'pokemon_esmeralda.gba',
      );

      expect(PokemonDecoder.mapName(profile, 0x0009), 'Villa Raíz');
      expect(
        PokemonDecoder.mapName(profile, 0x0104),
        'Laboratorio del Profesor Abedul',
      );
      expect(PokemonDecoder.mapName(profile, 0x0010), 'Ruta 101');
    });

    test('usa mapas y medallas de Kanto en Rojo Fuego', () {
      final PokemonGameProfile profile =
          PokemonGameProfile.fromGameIdentity(
            gameTitle: 'Pokémon Rojo Fuego',
            romPath: 'pokemon_rojo_fuego.gba',
          );

      expect(PokemonDecoder.mapName(profile, 0x0300), 'Pueblo Paleta');
      expect(PokemonDecoder.mapName(profile, 0x0313), 'Ruta 1');
      expect(PokemonDecoder.badgeName(profile, 0), 'Medalla Roca');
      expect(PokemonDecoder.badgeName(profile, 7), 'Medalla Tierra');
    });
  });
}
