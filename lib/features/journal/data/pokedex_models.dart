class PokedexEncounter {
  final String location;
  final String method;
  final String time;
  const PokedexEncounter({required this.location, required this.method, required this.time});
}

class PokedexMove {
  final int level;
  final String name;
  const PokedexMove(this.level, this.name);
}

class PokedexMachineMove {
  final String machine;
  final String name;
  const PokedexMachineMove(this.machine, this.name);
}

class PokedexSpeciesDetail {
  final String entry;
  final List<PokedexEncounter> encounters;
  final List<PokedexMove> levelMoves;
  final List<PokedexMachineMove> machineMoves;
  const PokedexSpeciesDetail({this.entry = '', this.encounters = const [], this.levelMoves = const [], this.machineMoves = const []});

  PokedexSpeciesDetail merge(PokedexSpeciesDetail override) => PokedexSpeciesDetail(
    entry: override.entry.isNotEmpty ? override.entry : entry,
    encounters: override.encounters.isNotEmpty ? override.encounters : encounters,
    levelMoves: override.levelMoves.isNotEmpty ? override.levelMoves : levelMoves,
    machineMoves: override.machineMoves.isNotEmpty ? override.machineMoves : machineMoves,
  );
}
