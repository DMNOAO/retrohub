enum EmeraldTrainerKind {
  regular,
  rival,
  gymLeader,
  eliteFour,
  champion,
  frontierBrain,
}

class EmeraldTrainerInfo {
  final String name;
  final String? spritePath;
  final EmeraldTrainerKind kind;

  const EmeraldTrainerInfo(this.name, this.kind, [this.spritePath]);
}

/// Resuelve los oponentes con identidad propia de Pokémon Esmeralda.
///
/// Los IDs proceden de `include/constants/opponents.h` de pret/pokeemerald.
/// Los entrenadores corrientes conservan su ID para que nunca se pierda la
/// identidad del combate aunque todavía no exista un sprite individual.
final class EmeraldTrainerResolver {
  const EmeraldTrainerResolver._();

  static EmeraldTrainerInfo forTrainerId(int id) {
    final EmeraldTrainerInfo? special = _special[id];
    if (special != null) return special;

    if (id >= 770 && id <= 801) {
      final int firstBattleId = 265 + ((id - 770) ~/ 4);
      return _special[firstBattleId]!;
    }

    if (_brendanIds.contains(id)) {
      return const EmeraldTrainerInfo(
        'Rival Brendan',
        EmeraldTrainerKind.rival,
        'assets/sprites/characters/rivals/brendan_emerald.png',
      );
    }
    if (_mayIds.contains(id)) {
      return const EmeraldTrainerInfo(
        'Rival May',
        EmeraldTrainerKind.rival,
        'assets/sprites/characters/rivals/may_emerald.png',
      );
    }
    if (_wallyIds.contains(id)) {
      return const EmeraldTrainerInfo(
        'Rival Wally',
        EmeraldTrainerKind.rival,
        'assets/sprites/characters/rivals/wally_hoenn.png',
      );
    }

    return EmeraldTrainerInfo('Entrenador #$id', EmeraldTrainerKind.regular);
  }

  static const Set<int> _brendanIds = <int>{
    520, 521, 522, 523, 524, 525, 526, 527, 528,
    592, 593, 599, 661, 662, 663, 853,
  };
  static const Set<int> _mayIds = <int>{
    529, 530, 531, 532, 533, 534, 535, 536, 537,
    600, 664, 665, 666, 768, 769, 854,
  };
  static const Set<int> _wallyIds = <int>{519, 656, 657, 658, 659, 660};

  static const Map<int, EmeraldTrainerInfo> _special =
      <int, EmeraldTrainerInfo>{
    261: EmeraldTrainerInfo(
      'Sidney',
      EmeraldTrainerKind.eliteFour,
      'assets/sprites/characters/elite_four/gba/Hoenn/sidney_hoenn.png',
    ),
    262: EmeraldTrainerInfo(
      'Phoebe',
      EmeraldTrainerKind.eliteFour,
      'assets/sprites/characters/elite_four/gba/Hoenn/phoebe_hoenn.png',
    ),
    263: EmeraldTrainerInfo(
      'Glacia',
      EmeraldTrainerKind.eliteFour,
      'assets/sprites/characters/elite_four/gba/Hoenn/glacia_hoenn.png',
    ),
    264: EmeraldTrainerInfo(
      'Drake',
      EmeraldTrainerKind.eliteFour,
      'assets/sprites/characters/elite_four/gba/Hoenn/drake_hoenn.png',
    ),
    265: EmeraldTrainerInfo(
      'Roxanne',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/roxanne_hoenn.png',
    ),
    266: EmeraldTrainerInfo(
      'Brawly',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/brawly_hoenn.png',
    ),
    267: EmeraldTrainerInfo(
      'Wattson',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/wattson_hoenn.png',
    ),
    268: EmeraldTrainerInfo(
      'Flannery',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/flannery_hoenn.png',
    ),
    269: EmeraldTrainerInfo(
      'Norman',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/norman_hoenn.png',
    ),
    270: EmeraldTrainerInfo(
      'Winona',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/winona_hoenn.png',
    ),
    271: EmeraldTrainerInfo(
      'Tate y Liza',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/tate_liza_hoenn.png',
    ),
    272: EmeraldTrainerInfo(
      'Juan',
      EmeraldTrainerKind.gymLeader,
      'assets/sprites/characters/gym_leaders/gba/Hoenn/juan_hoenn.png',
    ),
    335: EmeraldTrainerInfo(
      'Wallace',
      EmeraldTrainerKind.champion,
      'assets/sprites/characters/champions/wallace_hoenn.png',
    ),
    804: EmeraldTrainerInfo(
      'Steven',
      EmeraldTrainerKind.regular,
      'assets/sprites/characters/champions/steven_hoenn.png',
    ),
    805: EmeraldTrainerInfo(
      'Anabel',
      EmeraldTrainerKind.frontierBrain,
      'assets/sprites/characters/special_trainers/battle_frontier/emerald/salon_maiden_anabel.png',
    ),
    806: EmeraldTrainerInfo(
      'Tucker',
      EmeraldTrainerKind.frontierBrain,
      'assets/sprites/characters/special_trainers/battle_frontier/emerald/dome_ace_tucker.png',
    ),
    807: EmeraldTrainerInfo(
      'Spenser',
      EmeraldTrainerKind.frontierBrain,
      'assets/sprites/characters/special_trainers/battle_frontier/emerald/palace_maven_spenser.png',
    ),
    808: EmeraldTrainerInfo(
      'Greta',
      EmeraldTrainerKind.frontierBrain,
      'assets/sprites/characters/special_trainers/battle_frontier/emerald/arena_tycoon_greta.png',
    ),
    809: EmeraldTrainerInfo(
      'Noland',
      EmeraldTrainerKind.frontierBrain,
      'assets/sprites/characters/special_trainers/battle_frontier/emerald/factory_head_noland.png',
    ),
    810: EmeraldTrainerInfo(
      'Lucy',
      EmeraldTrainerKind.frontierBrain,
      'assets/sprites/characters/special_trainers/battle_frontier/emerald/pike_queen_lucy.png',
    ),
    811: EmeraldTrainerInfo(
      'Brandon',
      EmeraldTrainerKind.frontierBrain,
      'assets/sprites/characters/special_trainers/battle_frontier/emerald/pyramid_king_brandon.png',
    ),
  };
}
