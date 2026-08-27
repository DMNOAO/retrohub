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
  final PokemonGameProfile black2 = PokemonGameProfile.fromGameIdentity(
    gameTitle: 'Pokemon Negro 2',
    romPath: 'pokemon_negro_2.nds',
  );
  final PokemonGameProfile white2 = PokemonGameProfile.fromGameIdentity(
    gameTitle: 'Pokemon Blanca 2',
    romPath: 'pokemon_blanca_2.nds',
  );

  test('Negro 2 y Blanco 2 traducen el dormitorio inicial a Ciudad Engobe', () {
    for (final PokemonGameProfile profile in <PokemonGameProfile>[
      black2,
      white2,
    ]) {
      expect(PokemonDecoder.mapName(profile, 428), 'Ciudad Engobe');
      expect(PokemonDecoder.mapName(profile, 427), 'Ciudad Engobe');
      expect(PokemonDecoder.mapName(profile, 435), 'Ciudad Engobe');
      expect(
        PokemonDecoder.locationFor(profile, 428)?.kind,
        PokemonLocationKind.city,
      );
    }
  });

  test('Negro 2 y Blanco 2 agrupan la salida de Engobe como Ruta 19', () {
    for (final PokemonGameProfile profile in <PokemonGameProfile>[
      black2,
      white2,
    ]) {
      expect(PokemonDecoder.mapName(profile, 437), 'Ruta 19');
      expect(PokemonDecoder.mapName(profile, 438), 'Ruta 19');
      expect(
        PokemonDecoder.locationFor(profile, 438)?.kind,
        PokemonLocationKind.route,
      );
    }
  });

  test('Negro 2 y Blanco 2 traducen el primer sector de Ruta 20', () {
    expect(PokemonDecoder.mapName(black2, 446), 'Ruta 20');
    expect(PokemonDecoder.mapName(white2, 446), 'Ruta 20');
  });

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
