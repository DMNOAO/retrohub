import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_decoder.dart';
import 'package:retrohub/features/pokemon/memory/pokemon_emerald_memory_reader.dart';

void main() {
  group('Detección de bloques de guardado Gen III', () {
    test('exige que las copias de Pokédex vistos coincidan', () {
      final List<int> seen = List<int>.filled(52, 0);
      final List<int> different = List<int>.from(seen)..[17] = 1;

      expect(
        PokemonEmeraldMemoryReader.equalBytes(seen, List<int>.from(seen)),
        isTrue,
      );
      expect(
        PokemonEmeraldMemoryReader.equalBytes(seen, different),
        isFalse,
      );
      expect(
        PokemonEmeraldMemoryReader.equalBytes(seen, const <int>[]),
        isFalse,
      );
    });

    test('acepta nombres legítimos con caracteres repetidos', () {
      expect(
        PokemonEmeraldMemoryReader.isPlausiblePlayerName(
          <int>[0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF],
        ),
        isTrue,
      );
    });

    test('acepta un nombre normal terminado en FF', () {
      expect(
        PokemonEmeraldMemoryReader.isPlausiblePlayerName(
          <int>[0xBE, 0xBB, 0xC7, 0xC3, 0xFF, 0x00, 0x00, 0x00],
        ),
        isTrue,
      );
    });

    test('rechaza nombres sin terminador o con bytes inválidos', () {
      expect(
        PokemonEmeraldMemoryReader.isPlausiblePlayerName(
          List<int>.filled(8, 0xBB),
        ),
        isFalse,
      );
      expect(
        PokemonEmeraldMemoryReader.isPlausiblePlayerName(
          <int>[0x20, 0xFF, 0, 0, 0, 0, 0, 0],
        ),
        isFalse,
      );
    });
  });

  group('Pokémon Emerald species', () {
    test('keeps the first 251 National Pokédex IDs', () {
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(1), 1);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(251), 251);
    });

    test('skips the 25 unused internal species IDs', () {
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(252), 0);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(276), 0);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(277), 252);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(364), 287);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(392), 280);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(411), 358);
    });

    test('contains all Gen III species names', () {
      expect(PokemonDecoder.pokemonName(252), 'Treecko');
      expect(PokemonDecoder.pokemonName(386), 'Deoxys');
    });
  });

  group('Equipo de Pokémon Emerald', () {
    test('usa las 24 posiciones oficiales de la subestructura Growth', () {
      const expected = <int>[
        0, 0, 0, 0, 0, 0,
        1, 1, 2, 3, 2, 3,
        1, 1, 2, 3, 2, 3,
        1, 1, 2, 3, 2, 3,
      ];

      for (int personality = 0; personality < 24; personality++) {
        expect(
          PokemonEmeraldMemoryReader.growthSubstructurePosition(personality),
          expected[personality],
          reason: 'permutación $personality',
        );
      }
    });

    for (final pokemon in <(String, int, int, int)>[
      // nombre, personality % 24, especie interna, número nacional
      ('Treecko', 0, 277, 252),
      ('Ralts', 8, 392, 280),
      ('Slakoth', 9, 364, 287),
    ]) {
      test('decodifica ${pokemon.$1} desde su permutación', () {
        final data = List<int>.filled(48, 0);
        final growthPosition =
            PokemonEmeraldMemoryReader.growthSubstructurePosition(pokemon.$2);
        final offset = growthPosition * 12;
        data[offset] = pokemon.$3 & 0xFF;
        data[offset + 1] = pokemon.$3 >> 8;

        final internalId =
            PokemonEmeraldMemoryReader.internalSpeciesIdFromDecryptedData(
          personality: pokemon.$2,
          decryptedData: data,
        );

        expect(internalId, pokemon.$3);
        expect(
          PokemonEmeraldMemoryReader.emeraldNationalDexId(internalId),
          pokemon.$4,
        );
        expect(PokemonDecoder.pokemonName(pokemon.$4), pokemon.$1);
      });
    }
  });

  group('Pokédex Nacional de Pokémon Emerald', () {
    test('requires all three official unlock indicators', () {
      expect(
        PokemonEmeraldMemoryReader.isNationalDexUnlocked(
          nationalMagic: 0xDA,
          nationalDexVar: 0x0302,
          nationalDexFlagSet: true,
        ),
        isTrue,
      );

      for (final values in <(int, int, bool)>[
        (0, 0x0302, true),
        (0xDA, 0, true),
        (0xDA, 0x0302, false),
      ]) {
        expect(
          PokemonEmeraldMemoryReader.isNationalDexUnlocked(
            nationalMagic: values.$1,
            nationalDexVar: values.$2,
            nationalDexFlagSet: values.$3,
          ),
          isFalse,
        );
      }
    });
  });

  group('Combates de Pokémon Emerald', () {
    test('decodifica las banderas de entrenadores derrotados', () {
      final bytes = List<int>.filled(3, 0);
      // FLAG_TRAINER_FLAG_START (0x500) está alineado a byte: los IDs 1 y
      // 9 corresponden a los bits 1 de los bytes 0 y 1.
      bytes[0] = 1 << 1;
      bytes[1] = 1 << 1;

      expect(
        PokemonEmeraldMemoryReader.decodeDefeatedTrainerIds(
          bytes,
          maximumTrainerId: 16,
        ),
        <int>[1, 9],
      );
    });

    test('distingue un combate de entrenador por BATTLE_TYPE_TRAINER', () {
      expect(PokemonEmeraldMemoryReader.decodeBattleState(1 << 3), 2);
      expect(PokemonEmeraldMemoryReader.decodeBattleState((1 << 3) | 1), 2);
      expect(PokemonEmeraldMemoryReader.decodeBattleState(0), 0);
      expect(PokemonEmeraldMemoryReader.decodeBattleState(1), 0);
    });

    test('usa la convención de resultado propia de Gen III', () {
      expect(PokemonEmeraldMemoryReader.didPlayerWinBattle(1), isTrue);
      expect(PokemonEmeraldMemoryReader.didPlayerWinBattle(0), isFalse);
      expect(PokemonEmeraldMemoryReader.didPlayerWinBattle(2), isFalse);
    });
  });
}
