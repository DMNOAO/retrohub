import '../../../models/pokemon_location.dart';

/// MapHeader conocidos de Pokémon Negro 2 y Blanco 2.
///
/// Los interiores se agrupan bajo la ciudad o ruta que los contiene para que
/// la bitácora muestre una ubicación útil en vez del identificador interno.
const Map<int, PokemonLocation> black2White2Locations =
    <int, PokemonLocation>{
      428: PokemonLocation('Ciudad Engobe', PokemonLocationKind.city),
    };
