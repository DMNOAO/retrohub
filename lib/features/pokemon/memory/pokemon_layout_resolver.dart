import '../decoder/pokemon_decoder.dart';
import 'pokemon_addresses.dart';

typedef MemoryBlockReader = List<int> Function(int offset, int length);

class PokemonRedBlueLayout {
  final int shift;
  const PokemonRedBlueLayout(this.shift);
  int at(int base) => base + shift;
}

abstract final class PokemonLayoutResolver {
  static PokemonRedBlueLayout resolve(MemoryBlockReader read) {
    // Busca una estructura de equipo coherente. Cubre ROMs inglesa/europeas y traducciones.
    for (final shift in <int>[5, 0, 1, 2, 3, 4, 6, 7, 8, -1, -2, -3, -4, -5]) {
      if (_validParty(read, shift)) return PokemonRedBlueLayout(shift);
    }
    return const PokemonRedBlueLayout(5); // perfil detectado en la ROM Rojo usada en RetroHub.
  }

  static bool _validParty(MemoryBlockReader read, int shift) {
    final countBytes = read(PokemonRedBlueAddresses.partyCount + shift, 1);
    if (countBytes.isEmpty) return false;
    final count = countBytes.first;
    if (count < 1 || count > 6) return false;

    final species = read(PokemonRedBlueAddresses.partySpecies + shift, 7);
    if (species.length < 7 || species[count] != 0xFF) return false;
    for (int i = 0; i < count; i++) {
      if (PokemonGen1Decoder.pokedexIdFromInternal(species[i]) == 0) return false;
      final mon = read(PokemonRedBlueAddresses.partyMons + shift + i * PokemonRedBlueAddresses.partyStructLength, 34);
      if (mon.length < 34 || mon[0] != species[i]) return false;
      final level = mon[PokemonRedBlueAddresses.partyLevelOffset];
      if (level < 1 || level > 100) return false;
    }
    return true;
  }
}
