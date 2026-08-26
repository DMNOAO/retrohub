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
        return badgeIndex < _hoennRubySapphire.length
            ? _hoennRubySapphire[badgeIndex]
            : null;
      case PokemonGameVersion.emerald:
        return badgeIndex < _hoennGba.length ? _hoennGba[badgeIndex] : null;
      case PokemonGameVersion.fireRed:
      case PokemonGameVersion.leafGreen:
        return null;
      case PokemonGameVersion.diamond:
      case PokemonGameVersion.pearl:
        return badgeIndex < _sinnohDiamondPearl.length
            ? _sinnohDiamondPearl[badgeIndex]
            : null;
      case PokemonGameVersion.platinum:
        return badgeIndex < _sinnohPlatinum.length
            ? _sinnohPlatinum[badgeIndex]
            : null;
      case PokemonGameVersion.heartGold:
      case PokemonGameVersion.soulSilver:
        return badgeIndex < _johtoKantoHgss.length
            ? _johtoKantoHgss[badgeIndex]
            : null;
      case PokemonGameVersion.black:
      case PokemonGameVersion.white:
        return badgeIndex < _unovaBlackWhite.length
            ? _unovaBlackWhite[badgeIndex]
            : null;
      case PokemonGameVersion.black2:
      case PokemonGameVersion.white2:
        return badgeIndex < _unovaBlack2White2.length
            ? _unovaBlack2White2[badgeIndex]
            : null;
      case PokemonGameVersion.unsupported:
        return null;
    }
  }

  static const List<GymLeaderInfo> _unovaBlackWhite = <GymLeaderInfo>[
    GymLeaderInfo('Millo, Maíz o Zeos', 'assets/sprites/characters/gym_leaders/nds/Unova/cilan_unova.gif'),
    GymLeaderInfo('Aloe', 'assets/sprites/characters/gym_leaders/nds/Unova/lenora_unova.gif'),
    GymLeaderInfo('Camus', 'assets/sprites/characters/gym_leaders/nds/Unova/burgh_unova.gif'),
    GymLeaderInfo('Camila', 'assets/sprites/characters/gym_leaders/nds/Unova/elesa_unova.png'),
    GymLeaderInfo('Yakón', 'assets/sprites/characters/gym_leaders/nds/Unova/clay_unova.gif'),
    GymLeaderInfo('Gerania', 'assets/sprites/characters/gym_leaders/nds/Unova/skyla_unova.gif'),
    GymLeaderInfo('Junco', 'assets/sprites/characters/gym_leaders/nds/Unova/brycen_unova.gif'),
    GymLeaderInfo('Lirio o Iris', 'assets/sprites/characters/gym_leaders/nds/Unova/drayden_unova.gif'),
  ];

  static const List<GymLeaderInfo> _unovaBlack2White2 = <GymLeaderInfo>[
    GymLeaderInfo('Cheren', 'assets/sprites/characters/gym_leaders/nds/Unova/cheren_unova.gif'),
    GymLeaderInfo('Hiedra', 'assets/sprites/characters/gym_leaders/nds/Unova/roxie_unova.gif'),
    GymLeaderInfo('Camus', 'assets/sprites/characters/gym_leaders/nds/Unova/burgh_unova.gif'),
    GymLeaderInfo('Camila', 'assets/sprites/characters/gym_leaders/nds/Unova/elesa_unova_bw2.gif'),
    GymLeaderInfo('Yakón', 'assets/sprites/characters/gym_leaders/nds/Unova/clay_unova.gif'),
    GymLeaderInfo('Gerania', 'assets/sprites/characters/gym_leaders/nds/Unova/skyla_unova.gif'),
    GymLeaderInfo('Lirio', 'assets/sprites/characters/gym_leaders/nds/Unova/drayden_unova.gif'),
    GymLeaderInfo('Ciprián', 'assets/sprites/characters/gym_leaders/nds/Unova/marlon_unova.gif'),
  ];

  static const List<GymLeaderInfo> _hoennGba = <GymLeaderInfo>[
    GymLeaderInfo(
      'Roxanne',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/roxanne_hoenn.png',
    ),
    GymLeaderInfo(
      'Brawly',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/brawly_hoenn.png',
    ),
    GymLeaderInfo(
      'Wattson',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/wattson_hoenn.png',
    ),
    GymLeaderInfo(
      'Flannery',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/flannery_hoenn.png',
    ),
    GymLeaderInfo(
      'Norman',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/norman_hoenn.png',
    ),
    GymLeaderInfo(
      'Winona',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/winona_hoenn.png',
    ),
    GymLeaderInfo(
      'Tate y Liza',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/tate_liza_hoenn.png',
    ),
    GymLeaderInfo(
      'Juan',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/juan_hoenn.png',
    ),
  ];

  // Platino cambia el orden de Fantina, Brega y Mananti.
  static const List<GymLeaderInfo> _sinnohDiamondPearl = <GymLeaderInfo>[
    GymLeaderInfo(
      'Roco',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/roark_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Gardenia',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/gardenia_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Brega',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/maylene_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Mananti',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/crasher_wake_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Fantina',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/fantina_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Acerón',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/byron_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Inverna',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/candice_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Lectro',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/volkner_sinnoh.gif',
    ),
  ];

  static const List<GymLeaderInfo> _sinnohPlatinum = <GymLeaderInfo>[
    GymLeaderInfo(
      'Roco',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/roark_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Gardenia',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/gardenia_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Fantina',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/fantina_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Brega',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/maylene_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Mananti',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/crasher_wake_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Acerón',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/byron_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Inverna',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/candice_sinnoh.gif',
    ),
    GymLeaderInfo(
      'Lectro',
      'assets/sprites/characters/gym_leaders/nds/Sinnoh/volkner_sinnoh.gif',
    ),
  ];

  static const List<GymLeaderInfo> _johtoKantoHgss = <GymLeaderInfo>[
    GymLeaderInfo('Pegaso', 'assets/sprites/characters/gym_leaders/nds/Johto/falkner_johto_hgss.gif'),
    GymLeaderInfo('Antón', 'assets/sprites/characters/gym_leaders/nds/Johto/bugsy_johto_hgss.gif'),
    GymLeaderInfo('Blanca', 'assets/sprites/characters/gym_leaders/nds/Johto/whitney_johto_hgss.gif'),
    GymLeaderInfo('Morti', 'assets/sprites/characters/gym_leaders/nds/Johto/morty_johto_hgss.gif'),
    GymLeaderInfo('Aníbal', 'assets/sprites/characters/gym_leaders/nds/Johto/chuck_johto_hgss.gif'),
    GymLeaderInfo('Yasmina', 'assets/sprites/characters/gym_leaders/nds/Johto/jasmine_johto_hgss.gif'),
    GymLeaderInfo('Fredo', 'assets/sprites/characters/gym_leaders/nds/Johto/pryce_johto_hgss.gif'),
    GymLeaderInfo('Débora', 'assets/sprites/characters/gym_leaders/nds/Johto/clair_johto_hgss.gif'),
    GymLeaderInfo('Brock', 'assets/sprites/characters/gym_leaders/nds/Johto/brock_kanto_hgss.gif'),
    GymLeaderInfo('Misty', 'assets/sprites/characters/gym_leaders/nds/Johto/misty_kanto_hgss.gif'),
    GymLeaderInfo('Lt. Surge', 'assets/sprites/characters/gym_leaders/nds/Johto/lt_surge_kanto_hgss.gif'),
    GymLeaderInfo('Erika', 'assets/sprites/characters/gym_leaders/nds/Johto/erika_kanto_hgss.gif'),
    GymLeaderInfo('Janine', 'assets/sprites/characters/gym_leaders/nds/Johto/janine_kanto_hgss.gif'),
    GymLeaderInfo('Sabrina', 'assets/sprites/characters/gym_leaders/nds/Johto/sabrina_kanto_hgss.gif'),
    GymLeaderInfo('Blaine', 'assets/sprites/characters/gym_leaders/nds/Johto/blaine_kanto_hgss.gif'),
    GymLeaderInfo('Blue', 'assets/sprites/characters/gym_leaders/nds/Johto/blue_kanto_hgss.gif'),
  ];

  static const List<GymLeaderInfo> _hoennRubySapphire = <GymLeaderInfo>[
    GymLeaderInfo(
      'Roxanne',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/roxanne_hoenn.png',
    ),
    GymLeaderInfo(
      'Brawly',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/brawly_hoenn.png',
    ),
    GymLeaderInfo(
      'Wattson',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/wattson_hoenn.png',
    ),
    GymLeaderInfo(
      'Flannery',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/flannery_hoenn.png',
    ),
    GymLeaderInfo(
      'Norman',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/norman_hoenn.png',
    ),
    GymLeaderInfo(
      'Winona',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/winona_hoenn.png',
    ),
    GymLeaderInfo(
      'Tate y Liza',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/tate_liza_hoenn.png',
    ),
    GymLeaderInfo(
      'Wallace',
      'assets/sprites/characters/gym_leaders/gba/Hoenn/wallace_hoenn.png',
    ),
  ];

  static const List<GymLeaderInfo> _kantoGb = <GymLeaderInfo>[
    GymLeaderInfo(
      'Brock',
      'assets/sprites/characters/gym_leaders/gb/brock_kanto.png',
    ),
    GymLeaderInfo(
      'Misty',
      'assets/sprites/characters/gym_leaders/gb/misty_kanto.png',
    ),
    GymLeaderInfo(
      'Lt. Surge',
      'assets/sprites/characters/gym_leaders/gb/lt._surge_kanto.png',
    ),
    GymLeaderInfo(
      'Erika',
      'assets/sprites/characters/gym_leaders/gb/erika_kanto.png',
    ),
    GymLeaderInfo(
      'Koga',
      'assets/sprites/characters/gym_leaders/gb/koga_kanto.png',
    ),
    GymLeaderInfo(
      'Sabrina',
      'assets/sprites/characters/gym_leaders/gb/sabrina_kanto.png',
    ),
    GymLeaderInfo(
      'Blaine',
      'assets/sprites/characters/gym_leaders/gb/blaine_kanto.png',
    ),
    GymLeaderInfo(
      'Giovanni',
      'assets/sprites/characters/gym_leaders/gb/giovanni_kanto.png',
    ),
  ];

  static const List<GymLeaderInfo> _johtoGbc = <GymLeaderInfo>[
    GymLeaderInfo(
      'Pegaso',
      'assets/sprites/characters/gym_leaders/gbc/falkner_johto.png',
    ),
    GymLeaderInfo(
      'Antón',
      'assets/sprites/characters/gym_leaders/gbc/bugsy_johto.png',
    ),
    GymLeaderInfo(
      'Blanca',
      'assets/sprites/characters/gym_leaders/gbc/whitney_johto.png',
    ),
    GymLeaderInfo(
      'Morti',
      'assets/sprites/characters/gym_leaders/gbc/morty_johto.png',
    ),
    GymLeaderInfo(
      'Aníbal',
      'assets/sprites/characters/gym_leaders/gbc/chuck_johto.png',
    ),
    GymLeaderInfo(
      'Yasmina',
      'assets/sprites/characters/gym_leaders/gbc/jasmine_johto.png',
    ),
    GymLeaderInfo(
      'Fredo',
      'assets/sprites/characters/gym_leaders/gbc/pryce_johto.png',
    ),
    GymLeaderInfo(
      'Débora',
      'assets/sprites/characters/gym_leaders/gbc/clair_johto.png',
    ),
  ];

  static const List<GymLeaderInfo> _kantoGbc = <GymLeaderInfo>[
    GymLeaderInfo(
      'Brock',
      'assets/sprites/characters/gym_leaders/gbc/brock_kanto_gsc.png',
    ),
    GymLeaderInfo(
      'Misty',
      'assets/sprites/characters/gym_leaders/gbc/misty_kanto_gsc.png',
    ),
    GymLeaderInfo(
      'Lt. Surge',
      'assets/sprites/characters/gym_leaders/gbc/lt_surge_kanto_gsc.png',
    ),
    GymLeaderInfo(
      'Erika',
      'assets/sprites/characters/gym_leaders/gbc/erika_kanto_gsc.png',
    ),
    GymLeaderInfo(
      'Janine',
      'assets/sprites/characters/gym_leaders/gbc/janine_kanto.png',
    ),
    GymLeaderInfo(
      'Sabrina',
      'assets/sprites/characters/gym_leaders/gbc/sabrina_kanto_gsc.png',
    ),
    GymLeaderInfo(
      'Blaine',
      'assets/sprites/characters/gym_leaders/gbc/blaine_kanto_gsc.png',
    ),
    GymLeaderInfo(
      'Blue',
      'assets/sprites/characters/gym_leaders/gbc/blue_kanto.png',
    ),
  ];
}
