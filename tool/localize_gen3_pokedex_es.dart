import 'dart:convert';
import 'dart:io';

/// Applies official Spanish Gen III names/text from PokéAPI's game data to
/// the generated Ruby, Sapphire and Emerald Pokedex datasets.
///
/// Run after generate_gen3_pokedex.dart:
///   dart run tool/localize_gen3_pokedex_es.dart
Future<void> main() async {
  const base = 'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv';
  stdout.writeln('Downloading official Spanish Gen III localization data...');

  final moveCsv = await _download('$base/move_names.csv');
  final flavorCsv = await _download('$base/pokemon_species_flavor_text.csv');
  final movesHeader = await _download(
    'https://raw.githubusercontent.com/pret/pokeemerald/master/include/constants/moves.h',
  );

  final moveNames = _spanishMoveNames(moveCsv, movesHeader);
  final entries = _spanishEntries(flavorCsv);

  final targets = <_Target>[
    const _Target(
      'lib/features/journal/data/ruby_pokedex_generated.dart',
      7,
      'Ruby',
    ),
    const _Target(
      'lib/features/journal/data/sapphire_pokedex_generated.dart',
      8,
      'Sapphire',
    ),
    const _Target(
      'lib/features/journal/data/emerald_pokedex_generated.dart',
      9,
      'Emerald',
    ),
  ];

  for (final target in targets) {
    final file = File(target.path);
    if (!file.existsSync()) {
      throw StateError(
        '${target.path} does not exist. Run generate_gen3_pokedex.dart first.',
      );
    }
    final count = _localizeFile(
      file,
      entries[target.versionId] ?? const <int, String>{},
      moveNames,
    );
    stdout.writeln(
      '${target.label}: ${count.entries} Spanish entries, '
      '${count.moves} localized move references.',
    );
  }

  stdout.writeln(
    'Gen III Spanish localization complete. Move dictionary: '
    '${moveNames.length} Gen III moves.',
  );
}

Future<String> _download(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.userAgentHeader, 'RetroHub-Pokedex-Generator');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode} for $url');
    }
    return await utf8.decoder.bind(response).join();
  } finally {
    client.close(force: true);
  }
}

Map<String, String> _spanishMoveNames(String csv, String movesHeader) {
  // PokéAPI language 7 is the Spanish localization used by the older games.
  final spanishById = <int, String>{};
  for (final row in _parseCsv(csv).skip(1)) {
    if (row.length < 3) continue;
    final moveId = int.tryParse(row[0]);
    final languageId = int.tryParse(row[1]);
    if (moveId != null && languageId == 7) {
      spanishById[moveId] = row[2].trim();
    }
  }

  // The generator writes _pretty(MOVE_CONSTANT), so key the translation by
  // that exact generated form rather than relying on modern English names.
  final out = <String, String>{};
  for (final line in const LineSplitter().convert(movesHeader)) {
    final match = RegExp(
      r'#define\s+MOVE_([A-Z0-9_]+)\s+(\d+)',
    ).firstMatch(line);
    if (match == null) continue;
    final id = int.parse(match.group(2)!);
    if (id <= 0 || id > 354) continue; // Gen III move range.
    final spanish = spanishById[id];
    if (spanish == null || spanish.isEmpty) continue;
    out[_pretty(match.group(1)!)] = spanish;
  }
  return out;
}

Map<int, Map<int, String>> _spanishEntries(String csv) {
  // PokeAPI version IDs: Ruby=7, Sapphire=8, Emerald=9. Language 7=Spanish.
  final out = <int, Map<int, String>>{
    7: <int, String>{},
    8: <int, String>{},
    9: <int, String>{},
  };
  for (final row in _parseCsv(csv).skip(1)) {
    if (row.length < 4) continue;
    final speciesId = int.tryParse(row[0]);
    final versionId = int.tryParse(row[1]);
    final languageId = int.tryParse(row[2]);
    if (speciesId == null || speciesId < 1 || speciesId > 386) continue;
    if (versionId == null || !out.containsKey(versionId)) continue;
    if (languageId != 7) continue;
    final text = _cleanFlavorText(row[3]);
    if (text.isNotEmpty) out[versionId]![speciesId] = text;
  }
  return out;
}

_LocalizeCount _localizeFile(
  File file,
  Map<int, String> entries,
  Map<String, String> moveNames,
) {
  var text = file.readAsStringSync();
  var entryCount = 0;
  var moveCount = 0;

  final blockPattern = RegExp(
    r'  (\d+): PokedexSpeciesDetail\((.*?)\n  \),',
    dotAll: true,
  );
  text = text.replaceAllMapped(blockPattern, (match) {
    final id = int.parse(match.group(1)!);
    var body = match.group(2)!;
    final entry = entries[id];
    if (entry != null) {
      final line = "\n    entry: '${_esc(entry)}',";
      final existing = RegExp(r"\n    entry: '(?:\\.|[^'])*',");
      if (existing.hasMatch(body)) {
        body = body.replaceFirst(existing, line);
      } else {
        body = '$line$body';
      }
      entryCount++;
    }

    body = body.replaceAllMapped(
      RegExp(r"PokedexMove\((\d+), '((?:\\.|[^'])*)'\)"),
      (moveMatch) {
        final oldName = _unescape(moveMatch.group(2)!);
        final spanish = moveNames[oldName];
        if (spanish == null) return moveMatch.group(0)!;
        moveCount++;
        return "PokedexMove(${moveMatch.group(1)}, '${_esc(spanish)}')";
      },
    );
    body = body.replaceAllMapped(
      RegExp(r"PokedexMachineMove\('MT/MO', '((?:\\.|[^'])*)'\)"),
      (moveMatch) {
        final oldName = _unescape(moveMatch.group(1)!);
        final spanish = moveNames[oldName];
        if (spanish == null) return moveMatch.group(0)!;
        moveCount++;
        return "PokedexMachineMove('MT/MO', '${_esc(spanish)}')";
      },
    );

    return '  $id: PokedexSpeciesDetail($body\n  ),';
  });

  file.writeAsStringSync(text);
  return _LocalizeCount(entryCount, moveCount);
}

String _pretty(String value) => value
    .toLowerCase()
    .split('_')
    .map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
    .join(' ');

String _cleanFlavorText(String value) => value
    .replaceAll('\f', ' ')
    .replaceAll('\n', ' ')
    .replaceAll('\r', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _esc(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('\n', ' ');

String _unescape(String value) =>
    value.replaceAll(r"\'", "'").replaceAll(r'\\', r'\');

/// Small RFC-4180-compatible parser. Needed because flavor text contains
/// quoted commas and embedded line breaks.
List<List<String>> _parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;

  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }

    if (char == '"' && field.isEmpty) {
      quoted = true;
    } else if (char == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (char == '\n') {
      row.add(field.toString().replaceAll('\r', ''));
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(char);
    }
  }

  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString().replaceAll('\r', ''));
    rows.add(row);
  }
  return rows;
}

class _Target {
  final String path;
  final int versionId;
  final String label;
  const _Target(this.path, this.versionId, this.label);
}

class _LocalizeCount {
  final int entries;
  final int moves;
  const _LocalizeCount(this.entries, this.moves);
}
