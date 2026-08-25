import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/memory/pokemon_gen4_save_reader.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  test('lee el bloque general activo de Diamante y Perla', () {
    final bytes = List<int>.filled(0x80000, 0xFF);
    const generalSize = 0xC100;
    const trainer = 0x64;
    const dex = 0x12DC;

    _u32(bytes, generalSize - 0x14, 2);
    _u32(bytes, generalSize - 0x10, 1);
    _u32(bytes, generalSize - 8, 0x20060623);
    _utf16(bytes, trainer, 'LUCAS');
    _u16(bytes, trainer + 0x10, 12345);
    _u32(bytes, trainer + 0x14, 54321);
    bytes[trainer + 0x1A] = 0x05;
    bytes[trainer + 0x1D] = 0x02;
    _u16(bytes, trainer + 0x22, 12);
    bytes[trainer + 0x24] = 34;
    _u16(bytes, 0x1238, 411);
    _u16(bytes, 0x1240, 7);
    _u16(bytes, 0x1244, 9);
    bytes[dex + 4] = 0x01;
    bytes[dex + 4 + 0x40] = 0x03;

    final profile = PokemonGameProfile.fromRomPath('Pokemon Diamond.nds');
    final snapshot = PokemonGen4SaveReader(
      profile: profile,
      read: (offset, length) => bytes.sublist(offset, offset + length),
    ).capture();

    expect(snapshot, isNotNull);
    expect(snapshot!.playerName, 'LUCAS');
    expect(snapshot.trainerId, 12345);
    expect(snapshot.money, 54321);
    expect(snapshot.badgesMask, 0x05);
    expect(snapshot.currentMapId, 411);
    expect(snapshot.playerX, 7);
    expect(snapshot.playerY, 9);
    expect(snapshot.gamePlayTimeMinutes, 12 * 60 + 34);
    expect(snapshot.nationalDexUnlocked, isTrue);
    expect(snapshot.caughtPokemonIds, <int>[1]);
    expect(snapshot.seenPokemonIds, <int>[1, 2]);
  });
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
    _u16(bytes, offset + index * 2, value.codeUnitAt(index));
  }
  _u16(bytes, offset + value.length * 2, 0xFFFF);
}
