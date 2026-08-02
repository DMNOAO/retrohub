/// Tipo de ubicación, usado para diferenciar los eventos de la bitácora
/// (llegar a una ciudad no es lo mismo que entrar a una ruta o a un
/// gimnasio).
enum PokemonLocationKind { city, route, gym, league, other }

class PokemonLocation {
  final String name;
  final PokemonLocationKind kind;
  const PokemonLocation(this.name, [this.kind = PokemonLocationKind.other]);
}
