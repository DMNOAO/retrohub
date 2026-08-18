import 'dart:convert';
import 'dart:io';

/// Generates the offline Crystal Pokédex dataset from pret/pokecrystal.
/// Run from the RetroHub repository root:
///   dart run tool/generate_crystal_pokedex.dart
Future<void> main() async {
  final temp = await Directory.systemTemp.createTemp('retrohub_pokecrystal_');
  try {
    final clone = await Process.run('git', ['clone', '--depth', '1', '--quiet', 'https://github.com/pret/pokecrystal.git', temp.path]);
    if (clone.exitCode != 0) { stderr.writeln(clone.stderr); exitCode = clone.exitCode; return; }

    // The pointer table is the canonical National Dex order. Using its labels
    // also avoids special-name mismatches such as NidoranF, FarfetchD,
    // MrMime and HoOh.
    final dexNames = _readDexPointerNames(File('${temp.path}/data/pokemon/dex_entry_pointers.asm'));
    final normalizedToId = <String, int>{
      for (final e in dexNames.entries) _normalize(e.value): e.key,
    };

    final entries = <int, String>{};
    for (final file in Directory('${temp.path}/data/pokemon/dex_entries').listSync().whereType<File>()) {
      final text = file.readAsStringSync();
      final label = RegExp(r'^([A-Za-z0-9]+)PokedexEntry:\s*$', multiLine: true).firstMatch(text)?.group(1);
      final id = label == null ? null : normalizedToId[_normalize(label)];
      if (id != null) entries[id] = _parseDexText(text);
    }

    final learnsets = _parseLearnsets(
      File('${temp.path}/data/pokemon/evos_attacks.asm').readAsStringSync(),
      normalizedToId,
    );
    final machines = _parseMachines(
      Directory('${temp.path}/data/pokemon/base_stats'),
      normalizedToId,
    );

    final out = StringBuffer()
      ..writeln("import 'pokedex_models.dart';")
      ..writeln()
      ..writeln('// GENERATED FILE. Source: pret/pokecrystal. Do not edit by hand.')
      ..writeln('const Map<int, PokedexSpeciesDetail> crystalGeneratedSpecies = {');
    for (var id = 1; id <= 251; id++) {
      out.writeln('  $id: PokedexSpeciesDetail(');
      out.writeln('    entry: ${jsonEncode(entries[id] ?? '')},');
      final moves = learnsets[id] ?? const <_Move>[];
      if (moves.isNotEmpty) {
        out.writeln('    levelMoves: [');
        for (final m in moves) { out.writeln("      PokedexMove(${m.level}, '${_display(m.name)}'),"); }
        out.writeln('    ],');
      }
      final tms = machines[id] ?? const <String>[];
      if (tms.isNotEmpty) {
        out.writeln('    machineMoves: [');
        for (final tm in tms) { out.writeln("      PokedexMachineMove('MT/MO', '${_display(tm)}'),"); }
        out.writeln('    ],');
      }
      out.writeln('  ),');
    }
    out.writeln('};');

    final target = File('lib/features/journal/data/crystal_pokedex_generated.dart');
    target.writeAsStringSync(out.toString());

    final missingEntries = [for (var id = 1; id <= 251; id++) if (!entries.containsKey(id)) id];
    final missingLearnsets = [for (var id = 1; id <= 251; id++) if (!learnsets.containsKey(id)) id];
    final missingMachines = [for (var id = 1; id <= 251; id++) if (!machines.containsKey(id)) id];
    stdout.writeln('Crystal dataset generated: ${entries.length}/251 entries, ${learnsets.length}/251 learnsets, ${machines.length}/251 TM/HM tables.');
    if (missingEntries.isNotEmpty) stdout.writeln('Missing entries: $missingEntries');
    if (missingLearnsets.isNotEmpty) stdout.writeln('Missing learnsets: $missingLearnsets');
    if (missingMachines.isNotEmpty) stdout.writeln('Missing TM/HM tables: $missingMachines');
  } finally {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  }
}

Map<int, String> _readDexPointerNames(File file) {
  final result = <int, String>{};
  var id = 0;
  for (final line in file.readAsLinesSync()) {
    final m = RegExp(r'^\s*dw\s+([A-Za-z0-9]+)PokedexEntry\s*$').firstMatch(line);
    if (m == null) continue;
    id++;
    if (id <= 251) result[id] = m.group(1)!;
  }
  return result;
}

String _parseDexText(String source) {
  final p = RegExp(r'"([^"]*)"').allMatches(source).map((m) => m.group(1)!).toList();
  return p.length <= 1 ? '' : p.skip(1).join(' ').replaceAll('@', '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

Map<int, List<_Move>> _parseLearnsets(String source, Map<String, int> normalizedToId) {
  final result = <int, List<_Move>>{};
  final labels = RegExp(r'^([A-Za-z0-9]+)EvosAttacks:\s*$', multiLine: true).allMatches(source).toList();
  for (var i = 0; i < labels.length; i++) {
    final id = normalizedToId[_normalize(labels[i].group(1)!)];
    if (id == null) continue;
    final block = source.substring(labels[i].end, i + 1 < labels.length ? labels[i + 1].start : source.length);
    final zeroes = RegExp(r'^\s*db 0.*$', multiLine: true).allMatches(block).toList();
    if (zeroes.isEmpty) { result[id] = const <_Move>[]; continue; }
    final body = block.substring(zeroes.first.end, zeroes.length > 1 ? zeroes[1].start : block.length);
    final moves = <_Move>[];
    for (final line in body.split('\n')) {
      final m = RegExp(r'^\s*db\s+(\d+),\s*([A-Z0-9_]+)').firstMatch(line);
      if (m != null) moves.add(_Move(int.parse(m.group(1)!), m.group(2)!));
    }
    result[id] = moves;
  }
  return result;
}

Map<int, List<String>> _parseMachines(Directory dir, Map<String, int> normalizedToId) {
  final result = <int, List<String>>{};
  for (final file in dir.listSync().whereType<File>()) {
    final text = file.readAsStringSync();
    // Current pokecrystal base-stat files use: `db TOTODILE ; 158`.
    final species = RegExp(r'^\s*db\s+([A-Z0-9_]+)\s*;\s*\d+\s*$', multiLine: true).firstMatch(text)?.group(1);
    final id = species == null ? null : normalizedToId[_normalize(species)];
    if (id == null) continue;
    final tm = RegExp(r'^\s*tmhm\s+([^\n;]+)', multiLine: true).firstMatch(text)?.group(1);
    result[id] = tm == null
        ? const <String>[]
        : tm.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return result;
}

String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
String _display(String v) => v.toLowerCase().split('_').map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');

class _Move {
  final int level;
  final String name;
  const _Move(this.level, this.name);
}
