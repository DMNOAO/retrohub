import 'dart:convert';
import 'dart:io';

/// Generates Ruby, Sapphire and Emerald Pokedex detail datasets from pret data.
/// Run with: dart run tool/generate_gen3_pokedex.dart
Future<void> main() async {
  final tmp = await Directory.systemTemp.createTemp('retrohub_gen3_');
  final rs = Directory('${tmp.path}/pokeruby');
  final emerald = Directory('${tmp.path}/pokeemerald');
  try {
    await _clone('https://github.com/pret/pokeruby.git', rs.path);
    await _clone('https://github.com/pret/pokeemerald.git', emerald.path);

    // IMPORTANT: Gen III's internal SPECIES_* numbers are not National Dex
    // numbers after Celebi. IDs 252-276 are unused old Unown slots, so
    // Treecko starts at internal ID 277 even though its National Dex ID is 252.
    // Everything generated for RetroHub is keyed by National Dex ID.
    final species = _nationalSpeciesIds(
      File('${emerald.path}/include/constants/species.h'),
    );
    final moveNames = _moveNames(
      File('${emerald.path}/include/constants/moves.h'),
    );
    final entries = _entries(
      File('${emerald.path}/src/data/pokemon/pokedex_text.h'),
      species,
    );
    final rsLearn = _learnsets(
      File('${rs.path}/src/data/pokemon/level_up_learnsets.h'),
      species,
      moveNames,
    );
    final emeraldLearn = _learnsets(
      File('${emerald.path}/src/data/pokemon/level_up_learnsets.h'),
      species,
      moveNames,
    );
    final rsMachines = _machines(
      File('${rs.path}/src/data/pokemon/tmhm_learnsets.h'),
      species,
      moveNames,
    );
    final emeraldMachines = _machines(
      File('${emerald.path}/src/data/pokemon/tmhm_learnsets.h'),
      species,
      moveNames,
    );

    final rsJson = jsonDecode(
      File('${rs.path}/src/data/wild_encounters.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final emeraldJson = jsonDecode(
      File('${emerald.path}/src/data/wild_encounters.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final rubyEnc = _encounters(rsJson, species, version: 'Ruby');
    final sapphireEnc = _encounters(rsJson, species, version: 'Sapphire');
    final emeraldEnc = _encounters(emeraldJson, species, version: 'Emerald');

    _write(
      'lib/features/journal/data/ruby_pokedex_generated.dart',
      'rubyGeneratedSpecies',
      entries,
      rsLearn,
      rsMachines,
      rubyEnc,
    );
    _write(
      'lib/features/journal/data/sapphire_pokedex_generated.dart',
      'sapphireGeneratedSpecies',
      entries,
      rsLearn,
      rsMachines,
      sapphireEnc,
    );
    _write(
      'lib/features/journal/data/emerald_pokedex_generated.dart',
      'emeraldGeneratedSpecies',
      entries,
      emeraldLearn,
      emeraldMachines,
      emeraldEnc,
    );

    stdout.writeln('National species mapping: ${species.length}/386.');
    stdout.writeln('Gen III entries loaded: ${entries.length}/386.');
    stdout.writeln(
      'Ruby/Sapphire learnsets: ${rsLearn.length}/386; TM/HM: ${rsMachines.length}/386.',
    );
    stdout.writeln(
      'Emerald learnsets: ${emeraldLearn.length}/386; TM/HM: ${emeraldMachines.length}/386.',
    );
    stdout.writeln('Ruby wild encounter species: ${rubyEnc.length}/386.');
    stdout.writeln(
      'Sapphire wild encounter species: ${sapphireEnc.length}/386.',
    );
    stdout.writeln(
      'Emerald wild encounter species: ${emeraldEnc.length}/386.',
    );
  } finally {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  }
}

Future<void> _clone(String url, String path) async {
  final result = await Process.run(
    'git',
    ['clone', '--depth', '1', '--quiet', url, path],
  );
  if (result.exitCode != 0) {
    throw StateError('git clone failed: ${result.stderr}');
  }
}

String _norm(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

String _pretty(String value) => value
    .toLowerCase()
    .split('_')
    .map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
    .join(' ');

String _esc(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('\n', ' ');

/// Returns SPECIES name -> National Dex ID.
///
/// pokeemerald uses the original Gen III internal species table:
///   1..251   = Kanto + Johto (same as National Dex)
///   252..276 = OLD_UNOWN_B .. OLD_UNOWN_Z (not National species)
///   277..411 = Treecko .. Chimecho
///
/// Therefore every real Hoenn species is internalId - 25. For example:
/// Treecko 277 -> #252, Mudkip 283 -> #258, Chimecho 411 -> #386.
Map<String, int> _nationalSpeciesIds(File file) {
  final out = <String, int>{};
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(
      r'#define\s+SPECIES_([A-Z0-9_]+)\s+(\d+)',
    ).firstMatch(line);
    if (match == null) {
      continue;
    }

    final name = match.group(1)!;
    final internalId = int.parse(match.group(2)!);

    if (internalId >= 1 && internalId <= 251) {
      out[_norm(name)] = internalId;
      continue;
    }

    // Ignore the 25 obsolete Unown slots entirely.
    if (internalId >= 252 && internalId <= 276) {
      continue;
    }

    if (internalId >= 277 && internalId <= 411) {
      final nationalId = internalId - 25;
      if (nationalId >= 252 && nationalId <= 386) {
        out[_norm(name)] = nationalId;
      }
    }
  }
  return out;
}

Map<String, String> _moveNames(File file) {
  final out = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(
      r'#define\s+MOVE_([A-Z0-9_]+)\s+\d+',
    ).firstMatch(line);
    if (match != null) {
      out[match.group(1)!] = _pretty(match.group(1)!);
    }
  }
  return out;
}

Map<int, String> _entries(File file, Map<String, int> species) {
  final out = <int, String>{};
  final text = file.readAsStringSync();
  final labels = RegExp(
    r'const u8 g([A-Za-z0-9]+)PokedexText\[\]\s*=\s*_\(',
  ).allMatches(text).toList();

  for (var i = 0; i < labels.length; i++) {
    final id = species[_norm(labels[i].group(1)!)];
    if (id == null) {
      continue;
    }
    final end = i + 1 < labels.length ? labels[i + 1].start : text.length;
    final block = text.substring(labels[i].end, end);
    final pieces = RegExp(
      r'"([^"]*)"',
    ).allMatches(block).map((match) => match.group(1)!).toList();
    if (pieces.isNotEmpty) {
      out[id] = pieces
          .join(' ')
          .replaceAll(r'\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }
  return out;
}

Map<int, List<_Move>> _learnsets(
  File file,
  Map<String, int> species,
  Map<String, String> names,
) {
  final out = <int, List<_Move>>{};
  final text = file.readAsStringSync();
  final labels = RegExp(
    r'(?:const u16 g|static const u16 s)([A-Za-z0-9]+)LevelUpLearnset\[\]',
  ).allMatches(text).toList();

  for (var i = 0; i < labels.length; i++) {
    final id = species[_norm(labels[i].group(1)!)];
    if (id == null) {
      continue;
    }
    final end = i + 1 < labels.length ? labels[i + 1].start : text.length;
    final block = text.substring(labels[i].end, end);
    final moves = <_Move>[];
    for (final match in RegExp(
      r'LEVEL_UP_MOVE\(\s*(\d+)\s*,\s*MOVE_([A-Z0-9_]+)\s*\)',
    ).allMatches(block)) {
      moves.add(
        _Move(
          int.parse(match.group(1)!),
          names[match.group(2)!] ?? _pretty(match.group(2)!),
        ),
      );
    }
    out[id] = moves;
  }
  return out;
}

Map<int, List<String>> _machines(
  File file,
  Map<String, int> species,
  Map<String, String> names,
) {
  final out = <int, List<String>>{};
  final text = file.readAsStringSync();
  final labels = RegExp(
    r'\[SPECIES_([A-Z0-9_]+)\]\s*=\s*(?:TMHM_LEARNSET\(|\{\s*\.learnset\s*=\s*\{)',
  ).allMatches(text).toList();

  for (var i = 0; i < labels.length; i++) {
    final id = species[_norm(labels[i].group(1)!)];
    if (id == null) {
      continue;
    }
    final end = i + 1 < labels.length ? labels[i + 1].start : text.length;
    final block = text.substring(labels[i].end, end);
    final moves = <String>[];

    for (final match in RegExp(
      r'TMHM\(\s*(?:TM\d+_|HM\d+_)?([A-Z0-9_]+)\s*\)',
    ).allMatches(block)) {
      moves.add(names[match.group(1)!] ?? _pretty(match.group(1)!));
    }
    if (moves.isEmpty) {
      for (final match in RegExp(
        r'\.([A-Z0-9_]+)\s*=\s*TRUE',
      ).allMatches(block)) {
        moves.add(names[match.group(1)!] ?? _pretty(match.group(1)!));
      }
    }
    out[id] = moves;
  }
  return out;
}

Map<int, List<_Encounter>> _encounters(
  Map<String, dynamic> root,
  Map<String, int> species, {
  required String version,
}) {
  final out = <int, List<_Encounter>>{};
  for (final group in (root['wild_encounter_groups'] as List?) ?? const []) {
    if (group is! Map<String, dynamic>) {
      continue;
    }
    for (final encounter in (group['encounters'] as List?) ?? const []) {
      if (encounter is! Map<String, dynamic>) {
        continue;
      }
      final label = (encounter['base_label'] ?? '').toString().toLowerCase();
      if ((label.contains('_ruby') && version == 'Sapphire') ||
          (label.contains('_sapphire') && version == 'Ruby')) {
        continue;
      }
      final location = _pretty(
        (encounter['map'] ?? 'Unknown').toString().replaceFirst('MAP_', ''),
      );
      for (final field in const [
        'land_mons',
        'water_mons',
        'rock_smash_mons',
        'fishing_mons',
      ]) {
        final data = encounter[field];
        if (data is! Map<String, dynamic>) {
          continue;
        }
        final method = field == 'land_mons'
            ? 'Hierba'
            : field == 'water_mons'
                ? 'Surf'
                : field == 'rock_smash_mons'
                    ? 'Golpe Roca'
                    : 'Pesca';
        for (final mon in (data['mons'] as List?) ?? const []) {
          if (mon is! Map<String, dynamic>) {
            continue;
          }
          final id = species[
            _norm((mon['species'] ?? '').toString().replaceFirst('SPECIES_', ''))
          ];
          if (id == null) {
            continue;
          }
          final list = out.putIfAbsent(id, () => []);
          if (!list.any(
            (item) => item.location == location && item.method == method,
          )) {
            list.add(_Encounter(location, method));
          }
        }
      }
    }
  }
  return out;
}

void _write(
  String path,
  String variable,
  Map<int, String> entries,
  Map<int, List<_Move>> learn,
  Map<int, List<String>> machines,
  Map<int, List<_Encounter>> encounters,
) {
  final buffer = StringBuffer(
    "import 'pokedex_models.dart';\n\n"
    '// GENERATED FILE. Run: dart run tool/generate_gen3_pokedex.dart\n'
    'const Map<int, PokedexSpeciesDetail> $variable = {\n',
  );

  for (var id = 1; id <= 386; id++) {
    buffer.writeln('  $id: PokedexSpeciesDetail(');
    final entry = entries[id];
    if (entry != null) {
      buffer.writeln("    entry: '${_esc(entry)}',");
    }
    buffer.writeln('    levelMoves: [');
    for (final move in learn[id] ?? const []) {
      buffer.writeln(
        "      PokedexMove(${move.level}, '${_esc(move.name)}'),",
      );
    }
    buffer.writeln('    ],');
    buffer.writeln('    machineMoves: [');
    for (final move in machines[id] ?? const []) {
      buffer.writeln(
        "      PokedexMachineMove('MT/MO', '${_esc(move)}'),",
      );
    }
    buffer.writeln('    ],');
    buffer.writeln('    encounters: [');
    for (final encounter in encounters[id] ?? const []) {
      buffer.writeln(
        "      PokedexEncounter(location: '${_esc(encounter.location)}', "
        "method: '${encounter.method}', time: 'Cualquier hora'),",
      );
    }
    buffer.writeln('    ],');
    buffer.writeln('  ),');
  }
  buffer.writeln('};');
  File(path).writeAsStringSync(buffer.toString());
  stdout.writeln('Dataset written: $path');
}

class _Move {
  final int level;
  final String name;
  const _Move(this.level, this.name);
}

class _Encounter {
  final String location;
  final String method;
  const _Encounter(this.location, this.method);
}
