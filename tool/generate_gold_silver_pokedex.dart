import 'dart:convert';
import 'dart:io';

/// Generates Gold and Silver Pokédex datasets.
///
/// Gold/Silver gameplay data comes from pret/pokegold. Spanish Pokédex text
/// and move names are reused from the Spanish Gen II Crystal disassembly so
/// RetroHub remains fully offline and consistent with Spanish ROMs.
///
/// Run from the RetroHub repository root:
///   dart run tool/generate_gold_silver_pokedex.dart
Future<void> main() async {
  final root = await Directory.systemTemp.createTemp('retrohub_gen2_');
  final goldRoot = Directory('${root.path}/pokegold');
  final esRoot = Directory('${root.path}/pokecrystal-es');
  try {
    await _clone('https://github.com/pret/pokegold.git', goldRoot.path);
    await _clone('https://github.com/erosunica/pokecrystal-es.git', esRoot.path);

    final dexNames = _readDexPointerNames(
      File('${goldRoot.path}/data/pokemon/dex_entry_pointers.asm'),
    );
    final normalizedToId = <String, int>{
      for (final e in dexNames.entries) _normalize(e.value): e.key,
    };

    final entries = _readSpanishEntries(esRoot, normalizedToId);
    final moveNames = _readSpanishMoveNames(
      File('${esRoot.path}/constants/move_constants.asm'),
      File('${esRoot.path}/data/moves/names.asm'),
    );
    final learnsets = _parseLearnsets(
      File('${goldRoot.path}/data/pokemon/evos_attacks.asm').readAsStringSync(),
      normalizedToId,
    );
    final machines = _parseMachines(
      Directory('${goldRoot.path}/data/pokemon/base_stats'),
      normalizedToId,
    );

    final goldEncounters = _parseWildEncounters(
      Directory('${goldRoot.path}/data/wild'),
      normalizedToId,
      _Version.gold,
    );
    final silverEncounters = _parseWildEncounters(
      Directory('${goldRoot.path}/data/wild'),
      normalizedToId,
      _Version.silver,
    );

    _writeDataset(
      path: 'lib/features/journal/data/gold_pokedex_generated.dart',
      variable: 'goldGeneratedSpecies',
      version: 'Gold',
      entries: entries,
      learnsets: learnsets,
      machines: machines,
      encounters: goldEncounters,
      moveNames: moveNames,
    );
    _writeDataset(
      path: 'lib/features/journal/data/silver_pokedex_generated.dart',
      variable: 'silverGeneratedSpecies',
      version: 'Silver',
      entries: entries,
      learnsets: learnsets,
      machines: machines,
      encounters: silverEncounters,
      moveNames: moveNames,
    );

    stdout.writeln(
      'Gen II shared data: ${entries.length}/251 Spanish entries, '
      '${learnsets.length}/251 learnsets, ${machines.length}/251 TM/HM tables, '
      '${moveNames.length}/251 Spanish move names.',
    );
    stdout.writeln(
      'Gold wild encounter locations: '
      '${goldEncounters.values.where((e) => e.isNotEmpty).length}/251 species.',
    );
    stdout.writeln(
      'Silver wild encounter locations: '
      '${silverEncounters.values.where((e) => e.isNotEmpty).length}/251 species.',
    );
  } finally {
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

Future<void> _clone(String url, String path) async {
  final result = await Process.run(
    'git',
    ['clone', '--depth', '1', '--quiet', url, path],
  );
  if (result.exitCode != 0) {
    throw StateError('git clone failed for $url: ${result.stderr}');
  }
}

Map<int, String> _readSpanishEntries(
  Directory root,
  Map<String, int> normalizedToId,
) {
  final result = <int, String>{};
  final dir = Directory('${root.path}/data/pokemon/dex_entries');
  for (final file in dir.listSync().whereType<File>()) {
    final filename = file.uri.pathSegments.last;
    if (!filename.toLowerCase().endsWith('.asm')) continue;
    final stem = filename.substring(0, filename.length - 4);
    final id = normalizedToId[_normalize(stem)];
    if (id != null) result[id] = _parseDexText(file.readAsStringSync());
  }
  return result;
}

void _writeDataset({
  required String path,
  required String variable,
  required String version,
  required Map<int, String> entries,
  required Map<int, List<_Move>> learnsets,
  required Map<int, List<String>> machines,
  required Map<int, List<_Encounter>> encounters,
  required Map<String, String> moveNames,
}) {
  final out = StringBuffer()
    ..writeln("import 'pokedex_models.dart';")
    ..writeln()
    ..writeln('// GENERATED FILE. Sources: pret/pokegold + erosunica/pokecrystal-es.')
    ..writeln('// Do not edit by hand; run tool/generate_gold_silver_pokedex.dart.')
    ..writeln('const Map<int, PokedexSpeciesDetail> $variable = {');

  for (var id = 1; id <= 251; id++) {
    out.writeln('  $id: PokedexSpeciesDetail(');
    out.writeln('    entry: ${jsonEncode(entries[id] ?? '')},');

    final wild = encounters[id] ?? const <_Encounter>[];
    if (wild.isNotEmpty) {
      out.writeln('    encounters: [');
      for (final e in wild) {
        out.writeln(
          '      PokedexEncounter(location: ${jsonEncode(e.location)}, '
          'method: ${jsonEncode(e.method)}, time: ${jsonEncode(e.time)}),',
        );
      }
      out.writeln('    ],');
    }

    final moves = learnsets[id] ?? const <_Move>[];
    if (moves.isNotEmpty) {
      out.writeln('    levelMoves: [');
      for (final move in moves) {
        final name = moveNames[move.name] ?? _display(move.name);
        out.writeln('      PokedexMove(${move.level}, ${jsonEncode(name)}),');
      }
      out.writeln('    ],');
    }

    final tms = machines[id] ?? const <String>[];
    if (tms.isNotEmpty) {
      out.writeln('    machineMoves: [');
      for (final tm in tms) {
        final name = moveNames[tm] ?? _display(tm);
        out.writeln("      PokedexMachineMove('MT/MO', ${jsonEncode(name)}),");
      }
      out.writeln('    ],');
    }
    out.writeln('  ),');
  }
  out.writeln('};');
  File(path).writeAsStringSync(out.toString());
  stdout.writeln('$version dataset written to $path.');
}

Map<int, String> _readDexPointerNames(File file) {
  final result = <int, String>{};
  var id = 0;
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(
      r'^\s*dw\s+([A-Za-z0-9]+)PokedexEntry\s*$',
    ).firstMatch(line);
    if (match == null) continue;
    id++;
    if (id <= 251) result[id] = match.group(1)!;
  }
  return result;
}

Map<String, String> _readSpanishMoveNames(File constantsFile, File namesFile) {
  final constants = <String>[];
  for (final line in constantsFile.readAsLinesSync()) {
    final match = RegExp(
      r'^\s*const\s+([A-Z0-9_]+)\s*;\s*([0-9a-fA-F]+)\s*$',
    ).firstMatch(line);
    if (match == null) continue;
    final id = int.tryParse(match.group(2)!, radix: 16);
    if (id == null || id < 1 || id > 251) continue;
    while (constants.length < id) constants.add('');
    constants[id - 1] = match.group(1)!;
  }

  final names = RegExp(
    r'^\s*db\s+"([^"]*)@"\s*$',
    multiLine: true,
  ).allMatches(namesFile.readAsStringSync()).map((m) => _sentenceCase(m.group(1)!)).toList();

  final result = <String, String>{};
  final count = constants.length < names.length ? constants.length : names.length;
  for (var i = 0; i < count; i++) {
    if (constants[i].isNotEmpty) result[constants[i]] = names[i];
  }
  return result;
}

String _parseDexText(String source) {
  final parts = RegExp(r'"([^"]*)"')
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toList();
  if (parts.length <= 1) return '';
  return parts
      .skip(1)
      .join(' ')
      .replaceAll('@', '')
      .replaceAll('#MON', 'Pokémon')
      .replaceAll(RegExp(r'-\s+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Map<int, List<_Move>> _parseLearnsets(
  String source,
  Map<String, int> normalizedToId,
) {
  final result = <int, List<_Move>>{};
  final labels = RegExp(
    r'^([A-Za-z0-9]+)EvosAttacks:\s*$',
    multiLine: true,
  ).allMatches(source).toList();

  for (var i = 0; i < labels.length; i++) {
    final id = normalizedToId[_normalize(labels[i].group(1)!)];
    if (id == null) continue;
    final block = source.substring(
      labels[i].end,
      i + 1 < labels.length ? labels[i + 1].start : source.length,
    );
    final zeroes = RegExp(r'^\s*db\s+0\b.*$', multiLine: true)
        .allMatches(block)
        .toList();
    if (zeroes.isEmpty) {
      result[id] = const <_Move>[];
      continue;
    }
    final body = block.substring(
      zeroes.first.end,
      zeroes.length > 1 ? zeroes[1].start : block.length,
    );
    final moves = <_Move>[];
    for (final line in body.split('\n')) {
      final match = RegExp(
        r'^\s*db\s+(\d+),\s*([A-Z0-9_]+)',
      ).firstMatch(line);
      if (match != null) {
        moves.add(_Move(int.parse(match.group(1)!), match.group(2)!));
      }
    }
    result[id] = moves;
  }
  return result;
}

Map<int, List<String>> _parseMachines(
  Directory dir,
  Map<String, int> normalizedToId,
) {
  final result = <int, List<String>>{};
  for (final file in dir.listSync().whereType<File>()) {
    final text = file.readAsStringSync();
    final species = RegExp(
      r'^\s*db\s+([A-Z0-9_]+)\s*;\s*\d+\s*$',
      multiLine: true,
    ).firstMatch(text)?.group(1);
    final id = species == null ? null : normalizedToId[_normalize(species)];
    if (id == null) continue;
    final tm = RegExp(r'^\s*tmhm(?:\s+([^\n;]+))?', multiLine: true)
        .firstMatch(text)
        ?.group(1);
    result[id] = tm == null
        ? const <String>[]
        : tm.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return result;
}

Map<int, List<_Encounter>> _parseWildEncounters(
  Directory dir,
  Map<String, int> normalizedToId,
  _Version version,
) {
  final raw = <int, Map<String, _EncounterAccumulator>>{};
  for (final spec in [
    ('johto_grass.asm', 'Hierba', true),
    ('kanto_grass.asm', 'Hierba', true),
    ('johto_water.asm', 'Surf', false),
    ('kanto_water.asm', 'Surf', false),
  ]) {
    final file = File('${dir.path}/${spec.$1}');
    if (!file.existsSync()) continue;
    final lines = _filterVersion(file.readAsLinesSync(), version);
    _parseWildFile(lines, spec.$2, spec.$3, normalizedToId, raw);
  }
  return {
    for (final entry in raw.entries)
      entry.key: entry.value.values.map((v) => v.build()).toList(),
  };
}

List<String> _filterVersion(List<String> lines, _Version version) {
  final output = <String>[];
  final stack = <_Conditional>[];
  var active = true;

  for (final line in lines) {
    final trimmed = line.trim();
    final ifMatch = RegExp(r'^IF\s+DEF\(_(GOLD|SILVER)\)').firstMatch(trimmed);
    if (ifMatch != null) {
      final parent = active;
      final matches = ifMatch.group(1) == version.name.toUpperCase();
      stack.add(_Conditional(parent, matches));
      active = parent && matches;
      continue;
    }
    final elifMatch = RegExp(r'^ELIF\s+DEF\(_(GOLD|SILVER)\)').firstMatch(trimmed);
    if (elifMatch != null && stack.isNotEmpty) {
      final current = stack.last;
      final matches = elifMatch.group(1) == version.name.toUpperCase();
      active = current.parentActive && !current.branchTaken && matches;
      current.branchTaken = current.branchTaken || matches;
      continue;
    }
    if (trimmed == 'ELSE' && stack.isNotEmpty) {
      final current = stack.last;
      active = current.parentActive && !current.branchTaken;
      current.branchTaken = true;
      continue;
    }
    if (trimmed == 'ENDC' && stack.isNotEmpty) {
      final current = stack.removeLast();
      active = current.parentActive;
      continue;
    }
    if (active) output.add(line);
  }
  return output;
}

void _parseWildFile(
  List<String> lines,
  String method,
  bool timed,
  Map<String, int> normalizedToId,
  Map<int, Map<String, _EncounterAccumulator>> out,
) {
  String? map;
  var time = 'Cualquier hora';
  for (final line in lines) {
    final mapMatch = RegExp(
      r'^\s*def_(?:grass|water)_wildmons\s+([A-Z0-9_]+)',
    ).firstMatch(line);
    if (mapMatch != null) {
      map = mapMatch.group(1);
      time = 'Cualquier hora';
      continue;
    }
    if (RegExp(r'^\s*end_(?:grass|water)_wildmons').hasMatch(line)) {
      map = null;
      time = 'Cualquier hora';
      continue;
    }
    if (timed) {
      final comment = line.trim().toLowerCase();
      if (comment == '; morn') {
        time = 'Mañana';
        continue;
      }
      if (comment == '; day') {
        time = 'Día';
        continue;
      }
      if (comment == '; nite') {
        time = 'Noche';
        continue;
      }
    }
    if (map == null) continue;
    final mon = RegExp(r'^\s*db\s+\d+,\s*([A-Z0-9_]+)')
        .firstMatch(line)
        ?.group(1);
    if (mon == null) continue;
    final id = normalizedToId[_normalize(mon)];
    if (id == null) continue;
    final location = _displayMap(map);
    final key = '$location|$method';
    final acc = out
        .putIfAbsent(id, () => <String, _EncounterAccumulator>{})
        .putIfAbsent(key, () => _EncounterAccumulator(location, method));
    acc.times.add(time);
  }
}

String _displayMap(String value) {
  final special = <String, String>{
    'NATIONAL_PARK': 'Parque Nacional',
    'SPROUT_TOWER_2F': 'Torre Bellsprout 2F',
    'SPROUT_TOWER_3F': 'Torre Bellsprout 3F',
    'BURNED_TOWER_1F': 'Torre Quemada 1F',
    'BURNED_TOWER_B1F': 'Torre Quemada Sótano',
    'RUINS_OF_ALPH_OUTSIDE': 'Ruinas Alfa',
    'UNION_CAVE_1F': 'Cueva Unión 1F',
    'UNION_CAVE_B1F': 'Cueva Unión Sótano 1',
    'UNION_CAVE_B2F': 'Cueva Unión Sótano 2',
    'ILEX_FOREST': 'Bosque Encinar',
    'LAKE_OF_RAGE': 'Lago de la Furia',
    'NEW_BARK_TOWN': 'Pueblo Primavera',
    'CHERRYGROVE_CITY': 'Ciudad Cerezo',
    'VIOLET_CITY': 'Ciudad Malva',
    'ECRUTEAK_CITY': 'Ciudad Iris',
    'OLIVINE_CITY': 'Ciudad Olivo',
    'CIANWOOD_CITY': 'Ciudad Orquídea',
    'BLACKTHORN_CITY': 'Ciudad Endrino',
  };
  if (special.containsKey(value)) return special[value]!;
  final route = RegExp(r'^ROUTE_(\d+)(?:_(.*))?$').firstMatch(value);
  if (route != null) {
    final suffix = route.group(2);
    return suffix == null
        ? 'Ruta ${route.group(1)}'
        : 'Ruta ${route.group(1)} · ${_display(suffix)}';
  }
  return _display(value)
      .replaceAll('Pokemon', 'Pokémon')
      .replaceAll('Cave', 'Cueva')
      .replaceAll('Tower', 'Torre')
      .replaceAll('Forest', 'Bosque')
      .replaceAll('Park', 'Parque')
      .replaceAll('Lake', 'Lago')
      .replaceAll('Mt ', 'Monte ');
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String _display(String value) => value
    .toLowerCase()
    .split('_')
    .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
    .join(' ');

String _sentenceCase(String value) {
  final clean = value.replaceAll('@', '').trim().toLowerCase();
  if (clean.isEmpty) return clean;
  return '${clean[0].toUpperCase()}${clean.substring(1)}';
}

enum _Version { gold, silver }

class _Conditional {
  final bool parentActive;
  bool branchTaken;
  _Conditional(this.parentActive, this.branchTaken);
}

class _Move {
  final int level;
  final String name;
  const _Move(this.level, this.name);
}

class _Encounter {
  final String location;
  final String method;
  final String time;
  const _Encounter(this.location, this.method, this.time);
}

class _EncounterAccumulator {
  final String location;
  final String method;
  final Set<String> times = <String>{};
  _EncounterAccumulator(this.location, this.method);

  _Encounter build() {
    const order = ['Mañana', 'Día', 'Noche', 'Cualquier hora'];
    final sorted = order.where(times.contains).toList();
    final allDay = sorted.length == 3 &&
        sorted.contains('Mañana') &&
        sorted.contains('Día') &&
        sorted.contains('Noche');
    final time = allDay ? 'Cualquier hora' : sorted.join(' · ');
    return _Encounter(location, method, time.isEmpty ? 'Cualquier hora' : time);
  }
}
