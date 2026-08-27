import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_decoder.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  final PokemonGameProfile black = PokemonGameProfile.fromGameIdentity(
    gameTitle: 'Pokemon Negro',
    romPath: 'pokemon_negro.nds',
  );
  final PokemonGameProfile white = PokemonGameProfile.fromGameIdentity(
    gameTitle: 'Pokemon Blanca',
    romPath: 'pokemon_blanca.nds',
  );

  test('Blanco y Negro traducen el dormitorio inicial a Pueblo Arcilla', () {
    for (final PokemonGameProfile profile in <PokemonGameProfile>[black, white]) {
      expect(PokemonDecoder.mapName(profile, 391), 'Pueblo Arcilla');
      expect(
        PokemonDecoder.locationFor(profile, 391)?.kind,
        PokemonLocationKind.city,
      );
    }
  });

  test('Blanco y Negro traducen el Solar de los Sueños', () {
    for (final PokemonGameProfile profile in <PokemonGameProfile>[black, white]) {
      expect(PokemonDecoder.mapName(profile, 152), 'Solar de los Sueños');
    }
  });

  test('Blanco y Negro traducen el exterior inicial a Ruta 2', () {
    for (final PokemonGameProfile profile in <PokemonGameProfile>[black, white]) {
      expect(PokemonDecoder.mapName(profile, 319), 'Ruta 2');
      expect(
        PokemonDecoder.locationFor(profile, 319)?.kind,
        PokemonLocationKind.route,
      );
    }
  });

  test('un MapHeader de Gen V desconocido conserva el respaldo Zona', () {
    expect(PokemonDecoder.mapName(white, 9999), 'Zona 9999');
  });
}
