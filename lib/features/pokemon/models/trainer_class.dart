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
/// IMPORTANTE: esta tabla por sí sola NO detecta combates. Falta la
/// dirección de memoria RAM real de `wOtherTrainerClass` (confirmada por
/// nombre en ram/wram.asm, pero sin dirección hexadecimal verificada
/// todavía). Hasta tenerla, nada de esto se conecta al motor de eventos.
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
    0x0D: TrainerClassInfo('Bruno'),
    0x0E: TrainerClassInfo('Karen'),
    0x0F: TrainerClassInfo('Koga'),
    0x10: TrainerClassInfo('Lance (Campeón)'),
    0x11: TrainerClassInfo('Brock'),
    0x12: TrainerClassInfo('Misty'),
    0x13: TrainerClassInfo('Lt. Surge'),
    0x14: TrainerClassInfo('Científico'),
    0x15: TrainerClassInfo('Erika'),
    0x16: TrainerClassInfo('Joven'),
    0x17: TrainerClassInfo('Colegial'),
    0x18: TrainerClassInfo('Ave-cuidador'),
    0x19: TrainerClassInfo('Señorita'),
    0x1A: TrainerClassInfo('Janine'),
    0x1B: TrainerClassInfo('Míster Genial'),
    0x1C: TrainerClassInfo('Miss Genial'),
    0x1D: TrainerClassInfo('Bella'),
    0x1E: TrainerClassInfo('Fanático Pokémon'), // Pokemaniac
    0x1F: TrainerClassInfo('Rocket (M)'),
    0x20: TrainerClassInfo('Caballero'),
    0x21: TrainerClassInfo('Esquiadora'),
    0x22: TrainerClassInfo('Profesora'),
    0x23: TrainerClassInfo('Sabrina'),
    0x24: TrainerClassInfo('Cazabichos'),
    0x25: TrainerClassInfo('Pescador'),
    0x26: TrainerClassInfo('Nadador'),
    0x27: TrainerClassInfo('Nadadora'),
    0x28: TrainerClassInfo('Marinero'),
    0x29: TrainerClassInfo('Empollón'),
    0x2A: TrainerClassInfo('Rival (encuentro 2)'),
    0x2B: TrainerClassInfo('Guitarrista'),
    0x2C: TrainerClassInfo('Excursionista'),
    0x2D: TrainerClassInfo('Motorista'),
    0x2E: TrainerClassInfo('Blaine'),
    0x2F: TrainerClassInfo('Ladrón'),
    0x30: TrainerClassInfo('Lanzallamas'),
    0x31: TrainerClassInfo('Malabarista'),
    0x32: TrainerClassInfo('Cinturón Negro'),
    0x33: TrainerClassInfo('Ejecutivo (M)'),
    0x34: TrainerClassInfo('Médium (psíquico)'), // Psychic_T
    0x35: TrainerClassInfo('Excursionista (campo)'), // Picnicker
    0x36: TrainerClassInfo('Campista'),
    0x37: TrainerClassInfo('Ejecutiva (F)'),
    0x38: TrainerClassInfo('Sabio'),
    0x39: TrainerClassInfo('Médium'),
    0x3A: TrainerClassInfo('Snowboarder'),
    0x3B: TrainerClassInfo('Aficionado Pokémon (M)'),
    0x3C: TrainerClassInfo('Chica Kimono'),
    0x3D: TrainerClassInfo('Gemelas'),
    0x3E: TrainerClassInfo('Aficionada Pokémon (F)'),
    0x3F: TrainerClassInfo('Red'),
    0x40: TrainerClassInfo('Blue'),
    0x41: TrainerClassInfo('Oficial'),
    0x42: TrainerClassInfo('Rocket (F)'),
    0x43: TrainerClassInfo('Eusine'),
  };
}
