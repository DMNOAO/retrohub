import '../../../models/pokemon_location.dart';

/// Ubicaciones de Teselia indexadas por el MapHeader interno de Blanco/Negro.
///
/// Los interiores conservan el nombre de su ciudad o ruta principal para que
/// la bitácora no cambie a un identificador técnico al entrar en un edificio.
const Map<int, PokemonLocation> blackWhiteLocations = <int, PokemonLocation>{
  // Dormitorio inicial de Hilbert/Hilda, en Pueblo Arcilla.
  391: PokemonLocation('Pueblo Arcilla', PokemonLocationKind.city),
};
