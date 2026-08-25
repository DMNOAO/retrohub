import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/memory/pokemon_memory_reader.dart';

void main() {
  group('normalización de medallas de Johto en Gen II', () {
    test('convierte el bit crudo de Tormenta al índice visual de Tormenta', () {
      expect(PokemonMemoryReader.normalizeGen2JohtoBadges(0x20), 0x10);
    });

    test('convierte el bit crudo de Mineral al índice visual de Mineral', () {
      expect(PokemonMemoryReader.normalizeGen2JohtoBadges(0x10), 0x20);
    });

    test('conserva las demás medallas y la cantidad total', () {
      const raw = 0x2F;
      final normalized = PokemonMemoryReader.normalizeGen2JohtoBadges(raw);

      expect(normalized, 0x1F);
      expect(normalized.bitLength, lessThanOrEqualTo(8));
    });

    test('mantiene ambas medallas cuando las dos fueron obtenidas', () {
      expect(PokemonMemoryReader.normalizeGen2JohtoBadges(0x30), 0x30);
    });
  });
}
