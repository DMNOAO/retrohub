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
}
