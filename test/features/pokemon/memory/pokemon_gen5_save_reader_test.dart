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
    expect(snapshot.defeatedTrainerIds, <int>[42]);
  });
}
