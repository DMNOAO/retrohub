/// Nombre (en inglés, tal como aparece en trainer_constants.asm de
/// pokecrystal) y ruta de sprite para una clase de entrenador.
class TrainerClassInfo {
  final String name;
  final String? spritePath;
  const TrainerClassInfo(this.name, [this.spritePath]);
}

/// Resuelve el nombre/sprite de una clase de entrenador Johto/Kanto a
/// partir de su ID numérico real, tal como se define en
/// constants/trainer_constants.asm (pokecrystal) — pegado por el usuario.
///
/// La clase se lee desde memoria y se utiliza al cerrar un combate ganado.
class TrainerClassResolver {
  const TrainerClassResolver._();

  static TrainerClassInfo? forClassId(int id) => _classes[id];

  // IDs y nombres verificados línea por línea contra
  // constants/trainer_constants.asm real (pegado por el usuario).
  static const Map<int, TrainerClassInfo> _classes = <int, TrainerClassInfo>{
    0x01: TrainerClassInfo('Falkner'),
    0x02: TrainerClassInfo('Whitney'),
    0x03: TrainerClassInfo('Bugsy'),
    0x04: TrainerClassInfo('Morty'),
    0x05: TrainerClassInfo('Pryce'),
    0x06: TrainerClassInfo('Jasmine'),
    0x07: TrainerClassInfo('Chuck'),
    0x08: TrainerClassInfo('Clair'),
    0x09: TrainerClassInfo('Rival (encuentro 1)'),
    0x0A: TrainerClassInfo('Profesor Pokémon'),
    0x0B: TrainerClassInfo('Will'),
    0x0C: TrainerClassInfo('Cal'),
    0x0D: TrainerClassInfo(
      'Bruno',
      'assets/sprites/characters/elite_four/gbc/bruno_johto.png',
    ),
    0x0E: TrainerClassInfo(
      'Karen',
      'assets/sprites/characters/elite_four/gbc/karen_johto.png',
    ),
    0x0F: TrainerClassInfo(
      'Koga',
      'assets/sprites/characters/elite_four/gbc/koga_johto.png',
    ),
    0x10: TrainerClassInfo(
      'Lance (Campeón)',
      'assets/sprites/characters/champions/lance_johto.png',
    ),
    0x11: TrainerClassInfo('Brock'),
    0x12: TrainerClassInfo('Misty'),
    0x13: TrainerClassInfo('Lt. Surge'),
    0x14: TrainerClassInfo(
      'Científico',
      'assets/sprites/characters/villains/rocket/scientist_johto.png',
    ),
    0x15: TrainerClassInfo('Erika'),
    0x16: TrainerClassInfo(
      'Joven',
      'assets/sprites/characters/trainers/gbc/youngster.png',
    ),
    0x17: TrainerClassInfo(
      'Colegial',
      'assets/sprites/characters/trainers/gbc/schoolboy.png',
    ),
    0x18: TrainerClassInfo(
      'Ave-cuidador',
      'assets/sprites/characters/trainers/gbc/bird_keeper.png',
    ),
    0x19: TrainerClassInfo(
      'Señorita',
      'assets/sprites/characters/trainers/gbc/lass.png',
    ),
    0x1A: TrainerClassInfo('Janine'),
    0x1B: TrainerClassInfo(
      'Míster Genial',
      'assets/sprites/characters/trainers/gbc/cooltrainer_male.png',
    ),
    0x1C: TrainerClassInfo(
      'Miss Genial',
      'assets/sprites/characters/trainers/gbc/cooltrainer_female.png',
    ),
    0x1D: TrainerClassInfo(
      'Bella',
      'assets/sprites/characters/trainers/gbc/beauty.png',
    ),
    0x1E: TrainerClassInfo(
      'Fanático Pokémon',
      'assets/sprites/characters/trainers/gbc/pokemaniac.png',
    ),
    0x1F: TrainerClassInfo(
      'Rocket (M)',
      'assets/sprites/characters/villains/rocket/grunt_male_johto.png',
    ),
    0x20: TrainerClassInfo(
      'Caballero',
      'assets/sprites/characters/trainers/gbc/gentleman.png',
    ),
    0x21: TrainerClassInfo(
      'Esquiadora',
      'assets/sprites/characters/trainers/gbc/skier.png',
    ),
    0x22: TrainerClassInfo(
      'Profesora',
      'assets/sprites/characters/trainers/gbc/teacher.png',
    ),
    0x23: TrainerClassInfo('Sabrina'),
    0x24: TrainerClassInfo(
      'Cazabichos',
      'assets/sprites/characters/trainers/gbc/bug_catcher.png',
    ),
    0x25: TrainerClassInfo(
      'Pescador',
      'assets/sprites/characters/trainers/gbc/fisherman.png',
    ),
    0x26: TrainerClassInfo(
      'Nadador',
      'assets/sprites/characters/trainers/gbc/swimmer_male.png',
    ),
    0x27: TrainerClassInfo(
      'Nadadora',
      'assets/sprites/characters/trainers/gbc/swimmer_female.png',
    ),
    0x28: TrainerClassInfo(
      'Marinero',
      'assets/sprites/characters/trainers/gbc/sailor.png',
    ),
    0x29: TrainerClassInfo(
      'Empollón',
      'assets/sprites/characters/trainers/gbc/super_nerd.png',
    ),
    0x2A: TrainerClassInfo('Rival (encuentro 2)'),
    0x2B: TrainerClassInfo(
      'Guitarrista',
      'assets/sprites/characters/trainers/gbc/guitarist.png',
    ),
    0x2C: TrainerClassInfo(
      'Excursionista',
      'assets/sprites/characters/trainers/gbc/hiker.png',
    ),
    0x2D: TrainerClassInfo(
      'Motorista',
      'assets/sprites/characters/trainers/gbc/biker.png',
    ),
    0x2E: TrainerClassInfo('Blaine'),
    0x2F: TrainerClassInfo(
      'Ladrón',
      'assets/sprites/characters/trainers/gbc/burglar.png',
    ),
    0x30: TrainerClassInfo(
      'Lanzallamas',
      'assets/sprites/characters/trainers/gbc/firebreather.png',
    ),
    0x31: TrainerClassInfo(
      'Malabarista',
      'assets/sprites/characters/trainers/gbc/juggler.png',
    ),
    0x32: TrainerClassInfo(
      'Cinturón Negro',
      'assets/sprites/characters/trainers/gbc/black_belt.png',
    ),
    0x33: TrainerClassInfo(
      'Ejecutivo (M)',
      'assets/sprites/characters/villains/rocket/archer_johto.png',
    ),
    0x34: TrainerClassInfo(
      'Médium (psíquico)',
      'assets/sprites/characters/trainers/gbc/psychic.png',
    ),
    0x35: TrainerClassInfo(
      'Excursionista (campo)',
      'assets/sprites/characters/trainers/gbc/picnicker.png',
    ),
    0x36: TrainerClassInfo(
      'Campista',
      'assets/sprites/characters/trainers/gbc/camper.png',
    ),
    0x37: TrainerClassInfo(
      'Ejecutiva (F)',
      'assets/sprites/characters/villains/rocket/ariana_johto.png',
    ),
    0x38: TrainerClassInfo(
      'Sabio',
      'assets/sprites/characters/trainers/gbc/sage.png',
    ),
    0x39: TrainerClassInfo(
      'Médium',
      'assets/sprites/characters/trainers/gbc/medium.png',
    ),
    0x3A: TrainerClassInfo(
      'Snowboarder',
      'assets/sprites/characters/trainers/gbc/snowboarder.png',
    ),
    0x3B: TrainerClassInfo(
      'Aficionado Pokémon (M)',
      'assets/sprites/characters/trainers/gbc/pokefan_male.png',
    ),
    0x3C: TrainerClassInfo(
      'Chica Kimono',
      'assets/sprites/characters/trainers/gbc/kimono_girl.png',
    ),
    0x3D: TrainerClassInfo(
      'Gemelas',
      'assets/sprites/characters/trainers/gbc/twins.png',
    ),
    0x3E: TrainerClassInfo(
      'Aficionada Pokémon (F)',
      'assets/sprites/characters/trainers/gbc/pokefan_female.png',
    ),
    0x3F: TrainerClassInfo('Red'),
    0x40: TrainerClassInfo(
      'Blue',
      'assets/sprites/characters/gym_leaders/gbc/blue_kanto.png',
    ),
    0x41: TrainerClassInfo(
      'Oficial',
      'assets/sprites/characters/trainers/gbc/officer.png',
    ),
    0x42: TrainerClassInfo(
      'Rocket (F)',
      'assets/sprites/characters/villains/rocket/grunt_female_johto.png',
    ),
    0x43: TrainerClassInfo(
      'Eusine',
      'assets/sprites/characters/special_trainers/eusine.png',
    ),
  };
}
