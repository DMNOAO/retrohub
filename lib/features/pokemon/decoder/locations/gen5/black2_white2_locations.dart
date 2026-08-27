import '../../../models/pokemon_location.dart';

/// MapHeader conocidos de Pokémon Negro 2 y Blanco 2.
///
/// Los interiores se agrupan bajo la ciudad o ruta que los contiene para que
/// la bitácora muestre una ubicación útil en vez del identificador interno.
const Map<int, PokemonLocation> black2White2Locations =
    <int, PokemonLocation>{
      // Ciudad Engobe: exterior, dormitorio inicial y sectores usados durante
      // la elección del inicial y el primer combate contra Matis.
      427: PokemonLocation('Ciudad Engobe', PokemonLocationKind.city),
      428: PokemonLocation('Ciudad Engobe', PokemonLocationKind.city),
      435: PokemonLocation('Ciudad Engobe', PokemonLocationKind.city),
      // Al abandonar Engobe, PlayerSaveData conserva 438 como nombre visible
      // mientras ZoneID puede ser 437. Ambos deben mostrarse como Ruta 19.
      437: PokemonLocation('Ruta 19', PokemonLocationKind.route),
      438: PokemonLocation('Ruta 19', PokemonLocationKind.route),
      // Primer sector con entrenadores tras abandonar Ciudad Engobe.
      446: PokemonLocation('Ruta 20', PokemonLocationKind.route),
    };
