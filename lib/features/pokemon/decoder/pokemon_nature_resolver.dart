class PokemonNatureInfo {
  final String name;
  final String effect;
  const PokemonNatureInfo(this.name, this.effect);
}

abstract final class PokemonNatureResolver {
  static PokemonNatureInfo resolve(int personality) =>
      _byGameIndex[personality % 25] ??
      const PokemonNatureInfo('Desconocida', 'Neutral');

  static const Map<int, PokemonNatureInfo> _byGameIndex =
      <int, PokemonNatureInfo>{
    0: PokemonNatureInfo('Fuerte', 'Neutral'),
    5: PokemonNatureInfo('Osada', '+Defensa / −Ataque'),
    15: PokemonNatureInfo('Modesta', '+Ataque Especial / −Ataque'),
    20: PokemonNatureInfo('Serena', '+Defensa Especial / −Ataque'),
    10: PokemonNatureInfo('Miedosa', '+Velocidad / −Ataque'),
    1: PokemonNatureInfo('Huraña', '+Ataque / −Defensa'),
    6: PokemonNatureInfo('Dócil', 'Neutral'),
    16: PokemonNatureInfo('Afable', '+Ataque Especial / −Defensa'),
    21: PokemonNatureInfo('Amable', '+Defensa Especial / −Defensa'),
    11: PokemonNatureInfo('Activa', '+Velocidad / −Defensa'),
    3: PokemonNatureInfo('Firme', '+Ataque / −Ataque Especial'),
    8: PokemonNatureInfo('Agitada', '+Defensa / −Ataque Especial'),
    18: PokemonNatureInfo('Tímida', 'Neutral'),
    23: PokemonNatureInfo('Cauta', '+Defensa Especial / −Ataque Especial'),
    19: PokemonNatureInfo('Alocada', '+Ataque Especial / −Defensa Especial'),
    13: PokemonNatureInfo('Alegre', '+Velocidad / −Ataque Especial'),
    4: PokemonNatureInfo('Pícara', '+Ataque / −Defensa Especial'),
    9: PokemonNatureInfo('Floja', '+Defensa / −Defensa Especial'),
    24: PokemonNatureInfo('Rara', 'Neutral'),
    14: PokemonNatureInfo('Ingenua', '+Velocidad / −Defensa Especial'),
    2: PokemonNatureInfo('Audaz', '+Ataque / −Velocidad'),
    7: PokemonNatureInfo('Plácida', '+Defensa / −Velocidad'),
    17: PokemonNatureInfo('Mansa', '+Ataque Especial / −Velocidad'),
    22: PokemonNatureInfo('Grosera', '+Defensa Especial / −Velocidad'),
    12: PokemonNatureInfo('Seria', 'Neutral'),
  };
}

