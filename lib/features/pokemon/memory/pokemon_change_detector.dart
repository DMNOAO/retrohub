import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_memory_snapshot.dart';

enum PokemonChangeType {
  locationChanged,
  badgeObtained,
  partyChanged,
  moneyChanged,
}

class PokemonDetectedChange {
  final PokemonChangeType type;
  final String title;
  final String description;

  const PokemonDetectedChange({
    required this.type,
    required this.title,
    required this.description,
  });
}

class PokemonChangeDetector {
  const PokemonChangeDetector();

  List<PokemonDetectedChange> compare({
    required PokemonMemorySnapshot previous,
    required PokemonMemorySnapshot current,
  }) {
    final List<PokemonDetectedChange> changes = <PokemonDetectedChange>[];

    if (previous.currentMapId != current.currentMapId) {
      changes.add(
        PokemonDetectedChange(
          type: PokemonChangeType.locationChanged,
          title: 'Nueva ubicación',
          description: PokemonGen1Decoder.mapName(current.currentMapId),
        ),
      );
    }

    final int newBadges = current.badgesMask & ~previous.badgesMask;

    if (newBadges != 0) {
      changes.add(
        PokemonDetectedChange(
          type: PokemonChangeType.badgeObtained,
          title: 'Nueva medalla',
          description: 'Medallas obtenidas: ${current.badgeCount}',
        ),
      );
    }

    if (!_sameList(previous.partySpeciesIds, current.partySpeciesIds)) {
      changes.add(
        PokemonDetectedChange(
          type: PokemonChangeType.partyChanged,
          title: 'Equipo actualizado',
          description:
              'El equipo ahora tiene ${current.partySpeciesIds.length} Pokémon.',
        ),
      );
    }

    if (previous.money != current.money) {
      changes.add(
        PokemonDetectedChange(
          type: PokemonChangeType.moneyChanged,
          title: 'Dinero actualizado',
          description: '₽${current.money}',
        ),
      );
    }

    return changes;
  }

  bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }

    return true;
  }
}
