import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';
import 'package:retrohub/features/pokemon/models/pokemon_gym_leader.dart';

void main() {
  test('respeta el orden distinto de líderes entre DP y Platino', () {
    final diamond = PokemonGameProfile.fromRomPath('Pokemon Diamond.nds');
    final platinum = PokemonGameProfile.fromRomPath('Pokemon Platinum.nds');

    expect(GymLeaderAssetResolver.forBadge(diamond, 2)?.name, 'Brega');
    expect(GymLeaderAssetResolver.forBadge(diamond, 4)?.name, 'Fantina');
    expect(GymLeaderAssetResolver.forBadge(platinum, 2)?.name, 'Fantina');
    expect(GymLeaderAssetResolver.forBadge(platinum, 3)?.name, 'Brega');
  });

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

  test('Ruby y Sapphire usan a Wallace como octavo líder', () {
    for (final title in <String>['Pokemon Ruby', 'Pokemon Zafiro']) {
      final profile = PokemonGameProfile.fromGameIdentity(
        gameTitle: title,
        romPath: '$title.gba',
      );

      final leader = GymLeaderAssetResolver.forBadge(profile, 7);
      expect(leader?.name, 'Wallace');
      expect(
        leader?.spritePath,
        'assets/sprites/characters/gym_leaders/gba/Hoenn/wallace_hoenn.png',
      );
    }
  });

  test('HGSS usa líderes NDS de Johto y Kanto', () {
    final profile = PokemonGameProfile.fromRomPath('Pokemon HeartGold.nds');

    expect(GymLeaderAssetResolver.forBadge(profile, 0)?.name, 'Pegaso');
    expect(
      GymLeaderAssetResolver.forBadge(profile, 0)?.spritePath,
      'assets/sprites/characters/gym_leaders/nds/Johto/falkner_johto_hgss.gif',
    );
    expect(GymLeaderAssetResolver.forBadge(profile, 8)?.name, 'Brock');
    expect(GymLeaderAssetResolver.forBadge(profile, 15)?.name, 'Blue');
  });

  test('Negro y Blanco usan su octavo líder correspondiente', () {
    final black = PokemonGameProfile.fromRomPath('Pokemon Negro.nds');
    final white = PokemonGameProfile.fromRomPath('Pokemon Blanca.nds');

    expect(GymLeaderAssetResolver.forBadge(black, 7)?.name, 'Lirio');
    expect(
      GymLeaderAssetResolver.forBadge(black, 7)?.spritePath,
      endsWith('drayden_unova.gif'),
    );
    expect(GymLeaderAssetResolver.forBadge(white, 7)?.name, 'Iris');
    expect(
      GymLeaderAssetResolver.forBadge(white, 7)?.spritePath,
      endsWith('iris_unova.png'),
    );
  });
}
