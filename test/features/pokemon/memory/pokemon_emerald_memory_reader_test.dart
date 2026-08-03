import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/decoder/pokemon_decoder.dart';
import 'package:retrohub/features/pokemon/memory/pokemon_emerald_memory_reader.dart';

void main() {
  group('Pokémon Emerald species', () {
    test('keeps the first 251 National Pokédex IDs', () {
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(1), 1);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(251), 251);
    });

    test('skips the 25 unused internal species IDs', () {
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(252), 0);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(276), 0);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(277), 252);
      expect(PokemonEmeraldMemoryReader.emeraldNationalDexId(411), 386);
    });

    test('contains all Gen III species names', () {
      expect(PokemonDecoder.pokemonName(252), 'Treecko');
      expect(PokemonDecoder.pokemonName(386), 'Deoxys');
    });
  });
}
