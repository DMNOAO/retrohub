import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/memory/pokemon_gen4_save_reader.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  test('lee el bloque general activo de Diamante y Perla', () {
    final bytes = List<int>.filled(0x80000, 0xFF);
    const generalSize = 0xC100;
    const trainer = 0x64;
    const dex = 0x12DC;

    // El bloque activo contiene datos escritos; la partición de respaldo
    // permanece borrada (0xFF), como en un guardado con una sola copia válida.
    bytes.fillRange(0, generalSize, 0);
    _u32(bytes, generalSize - 0x14, 2);
    _u32(bytes, generalSize - 0x10, 1);
    _u32(bytes, generalSize - 8, 0x20060623);
    _utf16(bytes, trainer, 'LUCAS');
    _u16(bytes, trainer + 0x10, 12345);
    _u32(bytes, trainer + 0x14, 54321);
    bytes[trainer + 0x18] = 1;
    bytes[trainer + 0x1A] = 0x05;
    bytes[trainer + 0x1D] = 0x02;
    _u16(bytes, trainer + 0x22, 12);
    bytes[trainer + 0x24] = 34;
    _u16(bytes, 0x1238, 411);
    _u16(bytes, 0x1240, 7);
    _u16(bytes, 0x1244, 9);
    bytes[dex + 4] = 0x01;
    bytes[dex + 4 + 0x40] = 0x03;
    bytes[0x94] = 1;
    _writePartyPokemon(
      bytes,
      offset: 0x98,
      personality: 0,
      trainerId: 0x12345678,
      species: 393,
      level: 5,
      experience: 135,
      friendship: 70,
      moves: const <int>[1, 45],
    );

    final profile = PokemonGameProfile.fromRomPath('Pokemon Diamond.nds');
    final snapshot = PokemonGen4SaveReader(
      profile: profile,
      read: (offset, length) => bytes.sublist(offset, offset + length),
    ).capture();

    expect(snapshot, isNotNull);
    expect(snapshot!.playerName, 'LUCAS');
    expect(snapshot.trainerId, 12345);
    expect(snapshot.isFemale, isTrue);
    expect(snapshot.money, 54321);
    expect(snapshot.badgesMask, 0x05);
    expect(snapshot.currentMapId, 411);
    expect(snapshot.playerX, 7);
    expect(snapshot.playerY, 9);
    expect(snapshot.gamePlayTimeMinutes, 12 * 60 + 34);
    expect(snapshot.nationalDexUnlocked, isTrue);
    expect(snapshot.caughtPokemonIds, <int>[1]);
    expect(snapshot.seenPokemonIds, <int>[1, 2]);
    expect(snapshot.party, hasLength(1));
    expect(snapshot.party.single.pokedexId, 393);
    expect(snapshot.party.single.name, 'Piplup');
    expect(snapshot.party.single.level, 5);
    expect(snapshot.party.single.currentHp, 20);
    expect(snapshot.party.single.maximumHp, 20);
    expect(snapshot.party.single.friendship, 70);
    expect(snapshot.party.single.experience, 135);
    expect(snapshot.party.single.moveIds, <int>[1, 45]);
  });

  test('lee el layout, equipo y las 16 medallas de HGSS', () {
    final bytes = List<int>.filled(0x80000, 0xFF);
    const generalSize = 0xF628;
    const trainer = 0x64;
    const dex = 0x12B8;

    bytes.fillRange(0, generalSize, 0);
    _u32(bytes, generalSize - 0x14, 4);
    _u32(bytes, generalSize - 0x10, 2);
    _u32(bytes, generalSize - 8, 0x20060623);
    _utf16(bytes, trainer, 'LYRA');
    _u16(bytes, trainer + 0x10, 54321);
    _u32(bytes, trainer + 0x14, 98765);
    bytes[trainer + 0x18] = 1;
    bytes[trainer + 0x1A] = 0xFF;
    bytes[trainer + 0x1F] = 0x05;
    bytes[trainer + 0x1D] = 0x02;
    _u16(bytes, 0x1234, 99);
    _u16(bytes, 0x123C, 12);
    _u16(bytes, 0x1240, 18);
    bytes[dex + 4 + (151 >> 3)] |= 1 << (151 & 7);
    bytes[dex + 4 + 0x40 + (151 >> 3)] |= 1 << (151 & 7);
    bytes[0x94] = 1;
    _writePartyPokemon(
      bytes,
      offset: 0x98,
      personality: 0,
      trainerId: 0x12345678,
      species: 152,
      level: 5,
      experience: 135,
      friendship: 70,
      moves: const <int>[33, 45],
    );

    final snapshot = PokemonGen4SaveReader(
      profile: PokemonGameProfile.fromRomPath('Pokemon HeartGold.nds'),
      read: (offset, length) => bytes.sublist(offset, offset + length),
    ).capture();

    expect(snapshot, isNotNull);
    expect(snapshot!.playerName, 'LYRA');
    expect(snapshot.isFemale, isTrue);
    expect(snapshot.currentLocation, 'Cueva Unión');
    expect(snapshot.badgesMask, 0x05FF);
    expect(snapshot.currentMapId, 99);
    expect(snapshot.playerX, 12);
    expect(snapshot.playerY, 18);
    expect(snapshot.nationalDexUnlocked, isTrue);
    expect(snapshot.caughtPokemonIds, <int>[152]);
    expect(snapshot.party.single.pokedexId, 152);
    expect(snapshot.party.single.name, 'Chikorita');
  });
}

void _writePartyPokemon(
  List<int> target, {
  required int offset,
  required int personality,
  required int trainerId,
  required int species,
  required int level,
  required int experience,
  required int friendship,
  required List<int> moves,
}) {
  final data = List<int>.filled(0x80, 0);
  _u16(data, 0, species);
  _u32(data, 4, trainerId);
  _u32(data, 8, experience);
  data[0x0C] = friendship;
  for (int index = 0; index < moves.length && index < 4; index++) {
    _u16(data, 0x20 + index * 2, moves[index]);
  }

  int checksum = 0;
  for (int index = 0; index < data.length; index += 2) {
    checksum = (checksum + data[index] + (data[index + 1] << 8)) & 0xFFFF;
  }

  final stats = List<int>.filled(0x64, 0);
  stats[4] = level;
  _u16(stats, 6, 20);
  _u16(stats, 8, 20);
  _u16(stats, 10, 12);
  _u16(stats, 12, 10);
  _u16(stats, 14, 11);
  _u16(stats, 16, 12);
  _u16(stats, 18, 10);

  _u32(target, offset, personality);
  _u16(target, offset + 6, checksum);
  target.setRange(offset + 8, offset + 0x88, _crypt(data, checksum));
  target.setRange(offset + 0x88, offset + 0xEC, _crypt(stats, personality));
}

List<int> _crypt(List<int> source, int initialSeed) {
  final result = List<int>.from(source);
  int seed = initialSeed & 0xFFFFFFFF;
  for (int offset = 0; offset < result.length; offset += 2) {
    seed = (seed * 0x41C64E6D + 0x6073) & 0xFFFFFFFF;
    final value =
        (result[offset] | (result[offset + 1] << 8)) ^ (seed >> 16);
    result[offset] = value & 0xFF;
    result[offset + 1] = value >> 8;
  }
  return result;
}

void _u16(List<int> bytes, int offset, int value) {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = (value >> 8) & 0xFF;
}

void _u32(List<int> bytes, int offset, int value) {
  _u16(bytes, offset, value);
  _u16(bytes, offset + 2, value >> 16);
}

void _utf16(List<int> bytes, int offset, String value) {
  for (int index = 0; index < value.length; index++) {
    final int code = value.codeUnitAt(index);
    final int glyph = code >= 0x41 && code <= 0x5A
        ? 0x12B + code - 0x41
        : code >= 0x61 && code <= 0x7A
        ? 0x145 + code - 0x61
        : code >= 0x30 && code <= 0x39
        ? 0x121 + code - 0x30
        : 0x1AC;
    _u16(bytes, offset + index * 2, glyph);
  }
  _u16(bytes, offset + value.length * 2, 0xFFFF);
}
