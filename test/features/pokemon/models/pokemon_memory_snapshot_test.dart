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

  test('serializa experiencia y movimientos del equipo', () {
    const member = PokemonPartyMember(
      internalSpeciesId: 25,
      pokedexId: 25,
      name: 'Pikachu',
      level: 34,
      experience: 42875,
      moveIds: <int>[9, 86, 98, 129],
    );

    expect(member.toJson()['experience'], 42875);
    expect(member.toJson()['moveIds'], <int>[9, 86, 98, 129]);
  });

  test('serializa estadísticas y datos propios de tercera generación', () {
    const member = PokemonPartyMember(
      internalSpeciesId: 25,
      pokedexId: 25,
      name: 'Pikachu',
      level: 34,
      attack: 61,
      defense: 42,
      speed: 88,
      specialAttack: 72,
      specialDefense: 55,
      abilitySlot: 1,
      personality: 123456,
      heldItemId: 13,
    );

    final json = member.toJson();
    expect(json['attack'], 61);
    expect(json['defense'], 42);
    expect(json['speed'], 88);
    expect(json['specialAttack'], 72);
    expect(json['specialDefense'], 55);
    expect(json['abilitySlot'], 1);
    expect(json['personality'], 123456);
    expect(json['heldItemId'], 13);
  });
}
