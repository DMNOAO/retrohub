import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';
import 'package:retrohub/features/pokemon/models/pokemon_gym_leader.dart';

void main() {
  test('resuelve los ocho líderes de Hoenn desde sus medallas', () {
    final profile = PokemonGameProfile.fromGameIdentity(
      gameTitle: 'Pokemon_Esmeralda',
      romPath: 'pokemon_emerald.gba',
    );

    final leaders = List.generate(
      8,
      (index) => GymLeaderAssetResolver.forBadge(profile, index),
    );

    expect(
      leaders.map((leader) => leader?.name).toList(),
      <String?>[
        'Roxanne',
        'Brawly',
        'Wattson',
        'Flannery',
        'Norman',
        'Winona',
        'Tate y Liza',
        'Juan',
      ],
    );
    expect(
      leaders.first?.spritePath,
      'assets/sprites/characters/trainers/gba/Hoenn/leader_roxanne.png',
    );
    expect(
      leaders.last?.spritePath,
      'assets/sprites/characters/trainers/gba/Hoenn/leader_juan.png',
    );
  });
}
