import '../models/pokemon_game_profile.dart';

class GymLeaderInfo {
  final String name;
  final String spritePath;
  const GymLeaderInfo(this.name, this.spritePath);
}

class GymLeaderAssetResolver {
  const GymLeaderAssetResolver._();

  static GymLeaderInfo? forBadge(PokemonGameProfile profile, int badgeIndex) {
    if (badgeIndex < 0) return null;

    switch (profile.version) {
      case PokemonGameVersion.redBlue:
      case PokemonGameVersion.yellow:
        return badgeIndex < _kantoGb.length ? _kantoGb[badgeIndex] : null;
      case PokemonGameVersion.gold:
      case PokemonGameVersion.silver:
      case PokemonGameVersion.crystal:
        if (badgeIndex < _johtoGbc.length) return _johtoGbc[badgeIndex];
        final kantoIndex = badgeIndex - 8;
        return kantoIndex >= 0 && kantoIndex < _kantoGbc.length
            ? _kantoGbc[kantoIndex]
            : null;
      case PokemonGameVersion.ruby:
      case PokemonGameVersion.sapphire:
      case PokemonGameVersion.emerald:
        return badgeIndex < _hoennGba.length ? _hoennGba[badgeIndex] : null;
      case PokemonGameVersion.fireRed:
      case PokemonGameVersion.leafGreen:
      case PokemonGameVersion.unsupported:
        return null;
    }
  }

  static const List<GymLeaderInfo> _hoennGba = <GymLeaderInfo>[
    GymLeaderInfo('Roxanne', 'assets/sprites/characters/gym_leaders/gba/Hoenn/roxanne_hoenn.png'),
    GymLeaderInfo('Brawly', 'assets/sprites/characters/gym_leaders/gba/Hoenn/brawly_hoenn.png'),
    GymLeaderInfo('Wattson', 'assets/sprites/characters/gym_leaders/gba/Hoenn/wattson_hoenn.png'),
    GymLeaderInfo('Flannery', 'assets/sprites/characters/gym_leaders/gba/Hoenn/flannery_hoenn.png'),
    GymLeaderInfo('Norman', 'assets/sprites/characters/gym_leaders/gba/Hoenn/norman_hoenn.png'),
    GymLeaderInfo('Winona', 'assets/sprites/characters/gym_leaders/gba/Hoenn/winona_hoenn.png'),
    GymLeaderInfo('Tate y Liza', 'assets/sprites/characters/gym_leaders/gba/Hoenn/tate_liza_hoenn.png'),
    GymLeaderInfo('Juan', 'assets/sprites/characters/gym_leaders/gba/Hoenn/juan_hoenn.png'),
  ];

  static const List<GymLeaderInfo> _kantoGb = <GymLeaderInfo>[
    GymLeaderInfo('Brock', 'assets/sprites/characters/gym_leaders/gb/brock_kanto.png'),
    GymLeaderInfo('Misty', 'assets/sprites/characters/gym_leaders/gb/misty_kanto.png'),
    GymLeaderInfo('Lt. Surge', 'assets/sprites/characters/gym_leaders/gb/lt._surge_kanto.png'),
    GymLeaderInfo('Erika', 'assets/sprites/characters/gym_leaders/gb/erika_kanto.png'),
    GymLeaderInfo('Koga', 'assets/sprites/characters/gym_leaders/gb/koga_kanto.png'),
    GymLeaderInfo('Sabrina', 'assets/sprites/characters/gym_leaders/gb/sabrina_kanto.png'),
    GymLeaderInfo('Blaine', 'assets/sprites/characters/gym_leaders/gb/blaine_kanto.png'),
    GymLeaderInfo('Giovanni', 'assets/sprites/characters/gym_leaders/gb/giovanni_kanto.png'),
  ];

  static const List<GymLeaderInfo> _johtoGbc = <GymLeaderInfo>[
    GymLeaderInfo('Pegaso', 'assets/sprites/characters/gym_leaders/gbc/falkner_johto.png'),
    GymLeaderInfo('Antón', 'assets/sprites/characters/gym_leaders/gbc/bugsy_johto.png'),
    GymLeaderInfo('Blanca', 'assets/sprites/characters/gym_leaders/gbc/whitney_johto.png'),
    GymLeaderInfo('Morti', 'assets/sprites/characters/gym_leaders/gbc/morty_johto.png'),
    GymLeaderInfo('Aníbal', 'assets/sprites/characters/gym_leaders/gbc/chuck_johto.png'),
    GymLeaderInfo('Yasmina', 'assets/sprites/characters/gym_leaders/gbc/jasmine_johto.png'),
    GymLeaderInfo('Fredo', 'assets/sprites/characters/gym_leaders/gbc/pryce_johto.png'),
    GymLeaderInfo('Débora', 'assets/sprites/characters/gym_leaders/gbc/clair_johto.png'),
  ];

  static const List<GymLeaderInfo> _kantoGbc = <GymLeaderInfo>[
    GymLeaderInfo('Brock', 'assets/sprites/characters/gym_leaders/gbc/brock_kanto_gsc.png'),
    GymLeaderInfo('Misty', 'assets/sprites/characters/gym_leaders/gbc/misty_kanto_gsc.png'),
    GymLeaderInfo('Lt. Surge', 'assets/sprites/characters/gym_leaders/gbc/lt_surge_kanto_gsc.png'),
    GymLeaderInfo('Erika', 'assets/sprites/characters/gym_leaders/gbc/erika_kanto_gsc.png'),
    GymLeaderInfo('Janine', 'assets/sprites/characters/gym_leaders/gbc/janine_kanto.png'),
    GymLeaderInfo('Sabrina', 'assets/sprites/characters/gym_leaders/gbc/sabrina_kanto_gsc.png'),
    GymLeaderInfo('Blaine', 'assets/sprites/characters/gym_leaders/gbc/blaine_kanto_gsc.png'),
    GymLeaderInfo('Blue', 'assets/sprites/characters/gym_leaders/gbc/blue_kanto.png'),
  ];
}
