import 'dart:io';

Future<void> main() async {
  final tmp = await Directory.systemTemp.createTemp('retrohub_gen1_es_');
  try {
    final repo = Directory('${tmp.path}/pokered-es');
    final clone = await Process.run('git', ['clone', '--depth', '1', '--quiet', 'https://github.com/einstein95/pokered-es.git', repo.path]);
    if (clone.exitCode != 0) throw StateError('git clone failed: ${clone.stderr}');
    final constants = File('${repo.path}/constants/move_constants.asm').readAsLinesSync();
    final symbols = <String>[];
    var moves = false;
    for (final line in constants) {
      final m = RegExp(r'^\s*const\s+([A-Z][A-Z0-9_]*)').firstMatch(line);
      if (m == null) continue;
      final s = m.group(1)!;
      if (s == 'NO_MOVE') { moves = true; continue; }
      if (!moves) continue;
      if (s == 'SHOWPIC_ANIM') break;
      symbols.add(s);
    }
    final labels = RegExp(r'li\s+"([^"]+)"').allMatches(File('${repo.path}/data/moves/names.asm').readAsStringSync()).map((m) => m.group(1)!).toList();
    final replacements = <String, String>{};
    for (var i = 0; i < symbols.length && i < labels.length; i++) {
      replacements[_pretty(symbols[i])] = labels[i];
    }
    for (final path in ['lib/features/journal/data/red_pokedex_generated.dart','lib/features/journal/data/blue_pokedex_generated.dart','lib/features/journal/data/yellow_pokedex_generated.dart']) {
      final file = File(path);
      var text = file.readAsStringSync();
      for (final e in replacements.entries) {
        text = text.replaceAll("'${_escape(e.key)}'", "'${_escape(e.value)}'");
      }
      file.writeAsStringSync(text);
    }
    stdout.writeln('Gen I Spanish move names applied: ${replacements.length}/165.');
  } finally {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  }
}

String _pretty(String s) => s.toLowerCase().split('_').map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join(' ');
String _escape(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
