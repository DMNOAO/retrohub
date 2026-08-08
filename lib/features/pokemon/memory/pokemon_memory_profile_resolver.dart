import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import 'pokemon_addresses.dart';

typedef PokemonMemoryRead = List<int> Function(int offset, int length);

class ResolvedPokemonMemoryProfile {
  final PokemonMemoryAddresses addresses;
  final int shift;

  const ResolvedPokemonMemoryProfile({
    required this.addresses,
    required this.shift,
  });
}

class PokemonMemoryProfileResolver {
  static String lastDiagnostic = 'Sin diagnóstico.';

  static ResolvedPokemonMemoryProfile? resolve({
    required PokemonGameProfile profile,
    required PokemonMemoryRead read,
  }) {
    final PokemonMemoryAddresses? preferred = profile.addresses;
    if (preferred == null) {
      lastDiagnostic = 'El juego no tiene direcciones configuradas.';
      return null;
    }

    if (_isValid(profile, preferred, read)) {
      lastDiagnostic = 'Perfil principal válido.';
      return ResolvedPokemonMemoryProfile(
        addresses: preferred,
        shift: 0,
      );
    }

    // Gen II usa perfiles específicos para Gold/Silver y Crystal. No se debe
    // desplazar todo el mapa por un mismo delta porque sus bloques no forman
    // una única estructura contigua entre revisiones.
    if (profile.isGen2) {
      lastDiagnostic = 'El perfil Gen II no superó la validación estructural.';
      return null;
    }

    // Conservamos la búsqueda de desplazamiento únicamente para Gen I, donde
    // ya está comprobado que funciona con Red/Blue/Yellow.
    for (int distance = 1; distance <= 0x80; distance++) {
      for (final int delta in <int>[distance, -distance]) {
        final PokemonMemoryAddresses candidate = preferred.shifted(delta);
        if (_isValid(profile, candidate, read)) {
          lastDiagnostic = 'Perfil Gen I válido con desplazamiento $delta.';
          return ResolvedPokemonMemoryProfile(
            addresses: candidate,
            shift: delta,
          );
        }
      }
    }

    lastDiagnostic = 'No se encontró un perfil de memoria válido.';
    return null;
  }

  static bool _isValid(
    PokemonGameProfile profile,
    PokemonMemoryAddresses addresses,
    PokemonMemoryRead read,
  ) {
    if (addresses.playerName < 0 || addresses.partyMons >= 0x8000) {
      return false;
    }

    final List<int> countBytes = read(addresses.partyCount, 1);
    if (countBytes.length != 1) return false;

    final int count = countBytes.first;
    if (count < 1 || count > PokemonMemoryAddresses.maximumPartySize) {
      return false;
    }

    final List<int> species = read(addresses.partySpecies, 7);
    if (species.length != 7 || species[count] != 0xFF) return false;

    for (int i = 0; i < count; i++) {
      final int speciesId = species[i];

      // En Gen II, EGG (0xFD) es una entrada válida en partySpecies, pero
      // no es una especie de la Pokédex. Además, el bloque partyMons del
      // huevo no cumple las mismas invariantes que un Pokémon normal.
      // La lista partySpecies + su terminador 0xFF ya valida este slot.
      if (profile.isGen2 && speciesId == 0xFD) {
        continue;
      }

      final int dex = PokemonDecoder.dexId(profile, speciesId);
      if (dex < 1 || dex > (profile.isGen2 ? 251 : 151)) return false;

      final List<int> mon = read(
        addresses.partyMons + i * addresses.partyStructLength,
        addresses.partyStructLength,
      );
      if (mon.length != addresses.partyStructLength) return false;
      if (mon.first != speciesId) return false;

      final int level = mon[addresses.partyLevelOffset];
      if (level < 1 || level > 100) return false;
    }

    final List<int> name = read(
      addresses.playerName,
      addresses.playerNameLength,
    );
    if (name.length != addresses.playerNameLength) return false;
    if (!name.contains(0x50)) return false;
    if (PokemonDecoder.decodeText(name).isEmpty) return false;

    // El dinero NO forma parte de la validación estructural. Gen I lo guarda
    // en BCD, mientras Gen II lo guarda como entero binario big-endian.
    // Además, un campo secundario nunca debe impedir leer equipo y jugador.
    return true;
  }
}
