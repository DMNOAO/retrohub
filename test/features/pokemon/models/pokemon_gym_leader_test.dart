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
      'assets/sprites/characters/gym_leaders/gba/Hoenn/roxanne_hoenn.png',
    );
    expect(
      leaders.last?.spritePath,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/juan_hoenn.png',
    );
  });

  test('usa los nombres técnicos normalizados para líderes de GBC', () {
    final profile = PokemonGameProfile.fromGameIdentity(
      gameTitle: 'Pokemon_Cristal',
      romPath: 'pokemon_crystal.gbc',
    );

    expect(
      GymLeaderAssetResolver.forBadge(profile, 0)?.spritePath,
      'assets/sprites/characters/gym_leaders/gbc/falkner_johto.png',
    );
    expect(
      GymLeaderAssetResolver.forBadge(profile, 7)?.spritePath,
      'assets/sprites/characters/gym_leaders/gbc/clair_johto.png',
    );
    expect(
      GymLeaderAssetResolver.forBadge(profile, 15)?.spritePath,
      'assets/sprites/characters/gym_leaders/gbc/blue_kanto.png',
    );
  });
}
