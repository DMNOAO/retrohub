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
      case PokemonGameVersion.unsupported:
        return null;
    }
  }

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
    GymLeaderInfo('Pegaso', 'assets/sprites/characters/gym_leaders/gbc/Pegaso_OPC.png'),
    GymLeaderInfo('Antón', 'assets/sprites/characters/gym_leaders/gbc/Anton_OPC.png'),
    GymLeaderInfo('Blanca', 'assets/sprites/characters/gym_leaders/gbc/Blanca_OPC.png'),
    GymLeaderInfo('Morti', 'assets/sprites/characters/gym_leaders/gbc/Morti_OPC.png'),
    GymLeaderInfo('Aníbal', 'assets/sprites/characters/gym_leaders/gbc/Anibal_OPC.png'),
    GymLeaderInfo('Yasmina', 'assets/sprites/characters/gym_leaders/gbc/Yasmina_OPC.png'),
    GymLeaderInfo('Fredo', 'assets/sprites/characters/gym_leaders/gbc/Fredo_OPC.png'),
    GymLeaderInfo('Débora', 'assets/sprites/characters/gym_leaders/gbc/Debora_OPC.png'),
  ];

  static const List<GymLeaderInfo> _kantoGbc = <GymLeaderInfo>[
    GymLeaderInfo('Brock', 'assets/sprites/characters/gym_leaders/gbc/Brock_OPC.png'),
    GymLeaderInfo('Misty', 'assets/sprites/characters/gym_leaders/gbc/Misty_OPC.png'),
    GymLeaderInfo('Lt. Surge', 'assets/sprites/characters/gym_leaders/gbc/Lt_Surge_OPC.png'),
    GymLeaderInfo('Erika', 'assets/sprites/characters/gym_leaders/gbc/Erika_OPC.png'),
    GymLeaderInfo('Janine', 'assets/sprites/characters/gym_leaders/gbc/Janine_OPC.png'),
    GymLeaderInfo('Sabrina', 'assets/sprites/characters/gym_leaders/gbc/Sabrina_OPC.png'),
    GymLeaderInfo('Blaine', 'assets/sprites/characters/gym_leaders/gbc/Blaine_OPC.png'),
    GymLeaderInfo('Blue', 'assets/sprites/characters/gym_leaders/gbc/Blue_OPC.png'),
  ];
}
