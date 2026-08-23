import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/pokemon_memory_snapshot.dart';

void main() {
  test('serializa amistad para un Pokémon normal', () {
    const member = PokemonPartyMember(
      internalSpeciesId: 25,
      pokedexId: 25,
      name: 'Pikachu',
      level: 34,
      friendship: 173,
    );

    expect(member.toJson()['friendship'], 173);
    expect(member.toJson()['eggStepsCurrent'], isNull);
  });

  test('convierte ciclos de huevo en progreso aproximado creciente', () {
    const member = PokemonPartyMember(
      internalSpeciesId: 172,
      pokedexId: 172,
      name: 'Pichu',
      level: 5,
      isEgg: true,
      eggCyclesRemaining: 12,
      eggCyclesTotal: 20,
    );

    expect(member.eggStepsCurrent, 2048);
    expect(member.eggStepsTotal, 5120);
    expect(member.toJson()['friendship'], isNull);
  });
}
