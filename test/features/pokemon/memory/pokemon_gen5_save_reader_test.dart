import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/memory/pokemon_gen5_save_reader.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  test('decodifica el nombre Unicode del entrenador de Blanco y Negro', () {
    final save = List<int>.filled(PokemonGen5SaveReader.requiredSaveSize, 0);
    const name = 'HILDA';
    for (var index = 0; index < name.length; index++) {
      final value = name.codeUnitAt(index);
      save[0x19404 + index * 2] = value & 0xFF;
      save[0x19405 + index * 2] = value >> 8;
    }
    save[0x19404 + name.length * 2] = 0xFF;
    save[0x19405 + name.length * 2] = 0xFF;
    const trainerFlag = 0x550 + 81;
    save[0x20100 + 0x27C + (trainerFlag >> 3)] |=
        1 << (trainerFlag & 7);

    const profile = PokemonGameProfile(
      version: PokemonGameVersion.white,
      generation: PokemonGeneration.gen5,
      displayName: 'Pokémon White',
      memoryMapVerified: false,
      addresses: null,
    );
    final snapshot = PokemonGen5SaveReader(
      profile: profile,
      read: (offset, length) => save.sublist(offset, offset + length),
    ).capture();

    expect(snapshot, isNotNull);
    expect(snapshot!.playerName, name);
    expect(snapshot.party, isEmpty);
    expect(snapshot.defeatedTrainerIds, <int>[81]);
  });

  test('usa los bloques propios de Blanco 2 y Negro 2', () {
    final save = List<int>.filled(PokemonGen5SaveReader.requiredSaveSize, 0);
    const name = 'NATE';
    for (var index = 0; index < name.length; index++) {
      final value = name.codeUnitAt(index);
      save[0x19404 + index * 2] = value & 0xFF;
      save[0x19405 + index * 2] = value >> 8;
    }
    save[0x19404 + name.length * 2] = 0xFF;
    save[0x19405 + name.length * 2] = 0xFF;
    save[0x21100] = 0x78;
    save[0x21101] = 0x56;
    save[0x21102] = 0x34;
    save[0x21103] = 0x12;
    save[0x21104] = 0x05;
    // PlayerSaveData: PlaceNameZoneID, ZoneID y VecFx32(x, y, z).
    save[0x19500 + 0x76] = 0xAC;
    save[0x19500 + 0x77] = 0x01; // 428, Ciudad Engobe
    save[0x19500 + 0x80] = 0x34;
    save[0x19500 + 0x81] = 0x12; // submapa técnico distinto
    _writeU32(save, 0x19500 + 0x84, 12 << 12);
    _writeU32(save, 0x19500 + 0x8C, 34 << 12);
    const trainerFlag = 0x550 + 42;
    const eventFlagOffset = 0x1FF00 + 0x35E;
    save[eventFlagOffset + (trainerFlag >> 3)] |=
        1 << (trainerFlag & 7);

    const profile = PokemonGameProfile(
      version: PokemonGameVersion.black2,
      generation: PokemonGeneration.gen5,
      displayName: 'Pokémon Black 2',
      memoryMapVerified: false,
      addresses: null,
    );
    final snapshot = PokemonGen5SaveReader(
      profile: profile,
      read: (offset, length) => save.sublist(offset, offset + length),
    ).capture();

    expect(snapshot, isNotNull);
    expect(snapshot!.playerName, name);
    expect(snapshot.money, 0x12345678);
    expect(snapshot.badgesMask, 0x05);
    expect(snapshot.currentMapId, 428);
    expect(snapshot.playerX, 12);
    expect(snapshot.playerY, 34);
    // Los EventWork de B2W2 no se interpretan como TrainerFlag de BW.
    expect(snapshot.defeatedTrainerIds, isEmpty);
  });

  test('decodifica coordenadas negativas de VecFx32', () {
    final save = List<int>.filled(PokemonGen5SaveReader.requiredSaveSize, 0);
    const name = 'ROSA';
    for (var index = 0; index < name.length; index++) {
      final value = name.codeUnitAt(index);
      save[0x19404 + index * 2] = value & 0xFF;
      save[0x19405 + index * 2] = value >> 8;
    }
    save[0x19404 + name.length * 2] = 0xFF;
    save[0x19405 + name.length * 2] = 0xFF;
    _writeU32(save, 0x19500 + 0x84, (-3 << 12) & 0xFFFFFFFF);
    _writeU32(save, 0x19500 + 0x8C, (-7 << 12) & 0xFFFFFFFF);

    const profile = PokemonGameProfile(
      version: PokemonGameVersion.white2,
      generation: PokemonGeneration.gen5,
      displayName: 'Pokémon White 2',
      memoryMapVerified: false,
      addresses: null,
    );
    final snapshot = PokemonGen5SaveReader(
      profile: profile,
      read: (offset, length) => save.sublist(offset, offset + length),
    ).capture();

    expect(snapshot, isNotNull);
    expect(snapshot!.playerX, -3);
    expect(snapshot.playerY, -7);
  });
}

void _writeU32(List<int> bytes, int offset, int value) {
  for (var index = 0; index < 4; index++) {
    bytes[offset + index] = (value >> (index * 8)) & 0xFF;
  }
}
