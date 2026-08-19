import 'dart:convert';
import 'dart:io';

/// Replaces Gen III Pokédex flavor text with the Spanish Ruby/Sapphire/Emerald
/// entries published by Pokémon Project.
///
/// Run after:
///   dart run tool/generate_gen3_pokedex.dart
///   dart run tool/localize_gen3_pokedex_es.dart
///
/// PokeAPI currently has no Spanish flavor-text rows for these three original
/// Gen III versions, so the move localizer cannot provide the entries itself.
Future<void> main() async {
  stdout.writeln('Downloading Spanish Ruby/Sapphire/Emerald Pokédex entries...');

  final speciesCsv = await _download(
    'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon_species.csv',
  );
  final slugs = _speciesSlugs(speciesCsv);
  if (slugs.length != 386) {
    throw StateError('Expected 386 species slugs, found ${slugs.length}.');
  }

  final ruby = <int, String>{};
  final sapphire = <int, String>{};
  final emerald = <int, String>{};

  // Keep concurrency deliberately small so the source site is not hammered.
  const batchSize = 6;
  for (var start = 1; start <= 386; start += batchSize) {
    final end = (start + batchSize - 1).clamp(1, 386);
    final ids = [for (var id = start; id <= end; id++) id];
    final results = await Future.wait(
      ids.map((id) => _fetchEntries(id, slugs[id]!)),
    );
    for (final result in results) {
      final r = result.entries['Rubí'];
      final s = result.entries['Zafiro'];
      final e = result.entries['Esmeralda'];
      if (r != null && r.isNotEmpty) ruby[result.id] = r;
      if (s != null && s.isNotEmpty) sapphire[result.id] = s;
      if (e != null && e.isNotEmpty) emerald[result.id] = e;
    }
    stdout.write('\rSpanish entries downloaded: $end/386');
  }
  stdout.writeln();

  _apply(
    File('lib/features/journal/data/ruby_pokedex_generated.dart'),
    ruby,
  );
  _apply(
    File('lib/features/journal/data/sapphire_pokedex_generated.dart'),
    sapphire,
  );
  _apply(
    File('lib/features/journal/data/emerald_pokedex_generated.dart'),
    emerald,
  );

  stdout.writeln('Ruby Spanish entries: ${ruby.length}/386.');
  stdout.writeln('Sapphire Spanish entries: ${sapphire.length}/386.');
  stdout.writeln('Emerald Spanish entries: ${emerald.length}/386.');

  // These are useful sentinels because the previous bug was first noticed on
  // Mudkip (#258). Fail instead of silently producing another English dataset.
  if (!ruby.containsKey(258) ||
      !sapphire.containsKey(258) ||
      !emerald.containsKey(258)) {
    throw StateError('Spanish Mudkip entries were not loaded; dataset not accepted.');
  }

  stdout.writeln('Gen III Spanish Pokédex entries applied successfully.');
}

Map<int, String> _speciesSlugs(String csv) {
  final out = <int, String>{};
  for (final line in const LineSplitter().convert(csv).skip(1)) {
    final comma = line.indexOf(',');
    if (comma <= 0) continue;
    final id = int.tryParse(line.substring(0, comma));
    if (id == null || id < 1 || id > 386) continue;
    final rest = line.substring(comma + 1);
    final nextComma = rest.indexOf(',');
    if (nextComma <= 0) continue;
    out[id] = rest.substring(0, nextComma);
  }
  return out;
}

Future<_SpeciesEntries> _fetchEntries(int id, String slug) async {
  final encodedPath = Uri.encodeComponent('rubí-zafiro-esmeralda');
  final url = 'https://pkproject.net/dex/$encodedPath/$slug';
  String html = '';
  Object? lastError;
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      html = await _download(url);
      if (html.isNotEmpty) break;
    } catch (error) {
      lastError = error;
      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }
  if (html.isEmpty) {
    stderr.writeln('\nWarning: #$id $slug could not be downloaded: $lastError');
    return _SpeciesEntries(id, const {});
  }
  return _SpeciesEntries(id, _parseEditionRows(html));
}

Map<String, String> _parseEditionRows(String html) {
  final out = <String, String>{};
  final rowPattern = RegExp(r'<tr\b[^>]*>(.*?)</tr>', caseSensitive: false, dotAll: true);
  final cellPattern = RegExp(r'<t[dh]\b[^>]*>(.*?)</t[dh]>', caseSensitive: false, dotAll: true);

  for (final row in rowPattern.allMatches(html)) {
    final cells = cellPattern
        .allMatches(row.group(1)!)
        .map((m) => _htmlText(m.group(1)!))
        .where((v) => v.isNotEmpty)
        .toList();
    if (cells.length < 2) continue;

    final editionCell = cells.first;
    String? edition;
    if (editionCell.contains('Rubí')) {
      edition = 'Rubí';
    } else if (editionCell.contains('Zafiro')) {
      edition = 'Zafiro';
    } else if (editionCell.contains('Esmeralda')) {
      edition = 'Esmeralda';
    }
    if (edition == null || out.containsKey(edition)) continue;

    final description = cells.sublist(1).join(' ').trim();
    if (description.isNotEmpty) out[edition] = description;
  }
  return out;
}

String _htmlText(String html) {
  var value = html
      .replaceAll(RegExp(r'<script\b[^>]*>.*?</script>', caseSensitive: false, dotAll: true), ' ')
      .replaceAll(RegExp(r'<style\b[^>]*>.*?</style>', caseSensitive: false, dotAll: true), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ');

  const entities = <String, String>{
    '&nbsp;': ' ',
    '&amp;': '&',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&aacute;': 'á',
    '&eacute;': 'é',
    '&iacute;': 'í',
    '&oacute;': 'ó',
    '&uacute;': 'ú',
    '&Aacute;': 'Á',
    '&Eacute;': 'É',
    '&Iacute;': 'Í',
    '&Oacute;': 'Ó',
    '&Uacute;': 'Ú',
    '&ntilde;': 'ñ',
    '&Ntilde;': 'Ñ',
    '&uuml;': 'ü',
    '&Uuml;': 'Ü',
  };
  for (final entry in entities.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }
  value = value.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) => String.fromCharCode(int.parse(m.group(1)!)),
  );
  value = value.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
    (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
  );
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void _apply(File file, Map<int, String> entries) {
  if (!file.existsSync()) {
    throw StateError('${file.path} does not exist. Run the Gen III generator first.');
  }
  var text = file.readAsStringSync();
  var replaced = 0;

  final blockPattern = RegExp(
    r'  (\d+): PokedexSpeciesDetail\((.*?)\n  \),',
    dotAll: true,
  );
  text = text.replaceAllMapped(blockPattern, (match) {
    final id = int.parse(match.group(1)!);
    final entry = entries[id];
    if (entry == null) return match.group(0)!;

    var body = match.group(2)!;
    final line = "\n    entry: '${_esc(entry)}',";
    final existing = RegExp(r"\n    entry: '(?:\\.|[^'])*',");
    if (existing.hasMatch(body)) {
      body = body.replaceFirst(existing, line);
    } else {
      body = '$line$body';
    }
    replaced++;
    return '  $id: PokedexSpeciesDetail($body\n  ),';
  });

  file.writeAsStringSync(text);
  stdout.writeln('${file.path}: $replaced Spanish entries written.');
}

Future<String> _download(String url) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.userAgentHeader, 'RetroHub-Pokedex-Generator/1.0');
    request.headers.set(HttpHeaders.acceptHeader, 'text/html,text/plain,*/*');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode} for $url');
    }
    return await utf8.decoder.bind(response).join();
  } finally {
    client.close(force: true);
  }
}

String _esc(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('\n', ' ');

class _SpeciesEntries {
  final int id;
  final Map<String, String> entries;
  const _SpeciesEntries(this.id, this.entries);
}
