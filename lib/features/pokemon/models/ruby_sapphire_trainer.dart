import 'emerald_trainer.dart';

/// Identidades estables de entrenadores de Pokémon Ruby/Sapphire.
///
/// Los IDs proceden de `pret/pokeruby/include/constants/opponents.h`. Los
/// entrenadores sin identidad propia se conservan como evento genérico; así
/// nunca se les asigna por error el nombre de un oponente de Emerald.
final class RubySapphireTrainerResolver {
  const RubySapphireTrainerResolver._();

  static EmeraldTrainerInfo forTrainerId(int id) {
    final EmeraldTrainerInfo? special = _special[id];
    if (special != null) return special;

    if (id == 519 || (id >= 656 && id <= 660)) {
      return const EmeraldTrainerInfo(
        'Rival Wally',
        EmeraldTrainerKind.rival,
        'assets/sprites/characters/rivals/wally_hoenn.png',
      );
    }
    if ((id >= 520 && id <= 528) || (id >= 661 && id <= 663)) {
      return const EmeraldTrainerInfo(
        'Rival Brendan',
        EmeraldTrainerKind.rival,
        'assets/sprites/characters/rivals/brendan_ruby_sapphire.png',
      );
    }
    if ((id >= 529 && id <= 537) || (id >= 664 && id <= 666)) {
      return const EmeraldTrainerInfo(
        'Rival May',
        EmeraldTrainerKind.rival,
        'assets/sprites/characters/rivals/may_ruby_sapphire.png',
      );
    }

    return EmeraldTrainerInfo('Entrenador #$id', EmeraldTrainerKind.regular);
  }

  static const Map<int, EmeraldTrainerInfo> _special =
      <int, EmeraldTrainerInfo>{
        1: EmeraldTrainerInfo(
          'Archie',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/aqua/archie.png',
        ),
        30: EmeraldTrainerInfo(
          'Matt',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/aqua/matt.png',
        ),
        31: EmeraldTrainerInfo(
          'Matt',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/aqua/matt.png',
        ),
        32: EmeraldTrainerInfo(
          'Shelly',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/aqua/shelly.png',
        ),
        33: EmeraldTrainerInfo(
          'Shelly',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/aqua/shelly.png',
        ),
        34: EmeraldTrainerInfo(
          'Archie',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/aqua/archie.png',
        ),
        35: EmeraldTrainerInfo(
          'Archie',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/aqua/archie.png',
        ),
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
        265: EmeraldTrainerInfo('Roxanne', EmeraldTrainerKind.gymLeader),
        266: EmeraldTrainerInfo('Brawly', EmeraldTrainerKind.gymLeader),
        267: EmeraldTrainerInfo('Wattson', EmeraldTrainerKind.gymLeader),
        268: EmeraldTrainerInfo('Flannery', EmeraldTrainerKind.gymLeader),
        269: EmeraldTrainerInfo('Norman', EmeraldTrainerKind.gymLeader),
        270: EmeraldTrainerInfo('Winona', EmeraldTrainerKind.gymLeader),
        271: EmeraldTrainerInfo('Tate y Liza', EmeraldTrainerKind.gymLeader),
        272: EmeraldTrainerInfo('Wallace', EmeraldTrainerKind.gymLeader),
        335: EmeraldTrainerInfo(
          'Steven',
          EmeraldTrainerKind.champion,
          'assets/sprites/characters/champions/steven_hoenn.png',
        ),
        566: EmeraldTrainerInfo(
          'Maxie',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/magma/maxie.png',
        ),
        596: EmeraldTrainerInfo(
          'Tabitha',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/magma/tabitha.png',
        ),
        597: EmeraldTrainerInfo(
          'Tabitha',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/magma/tabitha.png',
        ),
        599: EmeraldTrainerInfo(
          'Courtney',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/magma/courtney.png',
        ),
        600: EmeraldTrainerInfo(
          'Courtney',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/magma/courtney.png',
        ),
        601: EmeraldTrainerInfo(
          'Maxie',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/magma/maxie.png',
        ),
        602: EmeraldTrainerInfo(
          'Maxie',
          EmeraldTrainerKind.specialTrainer,
          'assets/sprites/characters/villains/magma/maxie.png',
        ),
      };
}
