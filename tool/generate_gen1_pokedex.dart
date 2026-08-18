import 'dart:io';

/// Generates Red, Blue and Yellow Pokédex detail datasets.
/// Gameplay data comes from pret/pokered and pret/pokeyellow. Spanish
/// presentation text/names comes from einstein95/pokered-es.
Future<void> main() async {
  final tmp = await Directory.systemTemp.createTemp('retrohub_gen1_');
  final rb = Directory('${tmp.path}/pokered');
  final yellow = Directory('${tmp.path}/pokeyellow');
  final es = Directory('${tmp.path}/pokered-es');
  try {
    await _clone('https://github.com/pret/pokered.git', rb.path);
    await _clone('https://github.com/pret/pokeyellow.git', yellow.path);
    await _clone('https://github.com/einstein95/pokered-es.git', es.path);

    final names = _dexNames(File('${rb.path}/constants/pokedex_constants.asm'));
    final ids = <String,int>{for (final e in names.entries) _norm(e.value): e.key};
    final entries = _entries(File('${es.path}/data/pokemon/dex_text.asm'), ids);
    final moveNames = _moveNames(es);

    final rbLearn = _learnsets(File('${rb.path}/data/pokemon/evos_moves.asm'), ids);
    final yLearn = _learnsets(File('${yellow.path}/data/pokemon/evos_moves.asm'), ids);
    final rbMachines = _machines(Directory('${rb.path}/data/pokemon/base_stats'), ids);
    final yMachines = _machines(Directory('${yellow.path}/data/pokemon/base_stats'), ids);
    final redEnc = _encounters(Directory('${rb.path}/data/wild/maps'), ids, 'RED');
    final blueEnc = _encounters(Directory('${rb.path}/data/wild/maps'), ids, 'BLUE');
    final yellowEnc = _encounters(Directory('${yellow.path}/data/wild/maps'), ids, 'YELLOW');

    _write('lib/features/journal/data/red_pokedex_generated.dart','redGeneratedSpecies','Red',names,entries,rbLearn,rbMachines,redEnc,moveNames);
    _write('lib/features/journal/data/blue_pokedex_generated.dart','blueGeneratedSpecies','Blue',names,entries,rbLearn,rbMachines,blueEnc,moveNames);
    _write('lib/features/journal/data/yellow_pokedex_generated.dart','yellowGeneratedSpecies','Yellow',names,entries,yLearn,yMachines,yellowEnc,moveNames);

    stdout.writeln('Gen I Spanish entries: ${entries.length}/151.');
    stdout.writeln('Red/Blue learnsets: ${rbLearn.length}/151; TM/HM: ${rbMachines.length}/151.');
    stdout.writeln('Yellow learnsets: ${yLearn.length}/151; TM/HM: ${yMachines.length}/151.');
    stdout.writeln('Spanish move names: ${moveNames.length}.');
    stdout.writeln('Red wild encounters: ${redEnc.length}/151 species.');
    stdout.writeln('Blue wild encounters: ${blueEnc.length}/151 species.');
    stdout.writeln('Yellow wild encounters: ${yellowEnc.length}/151 species.');
  } finally { if (tmp.existsSync()) tmp.deleteSync(recursive:true); }
}

Future<void> _clone(String url,String path) async { final r=await Process.run('git',['clone','--depth','1','--quiet',url,path]); if(r.exitCode!=0) throw StateError('${r.stderr}'); }
String _norm(String s)=>s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'),'');
String _pretty(String s)=>s.toLowerCase().split('_').map((p)=>p.isEmpty?'':p[0].toUpperCase()+p.substring(1)).join(' ');
String _esc(String s)=>s.replaceAll(r'\',r'\\').replaceAll("'",r"\'").replaceAll('\n',' ');

Map<int,String> _dexNames(File f){ final out=<int,String>{}; for(final l in f.readAsLinesSync()){ final m=RegExp(r'const DEX_([A-Z0-9_]+)\s*;\s*(\d+)').firstMatch(l); if(m!=null) out[int.parse(m.group(2)!)]=m.group(1)!; } return out; }

Map<int,String> _entries(File f,Map<String,int> ids){
  final out=<int,String>{}; final text=f.readAsStringSync();
  final labels=RegExp(r'(?m)^([A-Za-z0-9_]+)DexEntry:').allMatches(text).toList();
  for(var i=0;i<labels.length;i++){
    final label=labels[i].group(1)!; final id=ids[_norm(label)]; if(id==null) continue;
    final end=i+1<labels.length?labels[i+1].start:text.length; final block=text.substring(labels[i].end,end);
    final pieces=<String>[]; for(final m in RegExp(r'(?:(?:text|next|line|para|cont) )"([^"]*)"').allMatches(block)){ pieces.add(m.group(1)!); }
    if(pieces.isNotEmpty) out[id]=pieces.join(' ').replaceAll('@','').replaceAll(RegExp(r'\s+'),' ').trim();
  } return out;
}

Map<String,String> _moveNames(Directory root){
  final f=File('${root.path}/data/moves/names.asm'); if(!f.existsSync()) return {};
  final out=<String,String>{}; var n=1; for(final m in RegExp(r'db\s+"([^"]+)@"').allMatches(f.readAsStringSync())){ out['#${n++}']=m.group(1)!; } return out;
}

Map<int,List<_Move>> _learnsets(File f,Map<String,int> ids){
  final out=<int,List<_Move>>{}; if(!f.existsSync()) return out; final text=f.readAsStringSync();
  final labels=RegExp(r'(?m)^([A-Za-z0-9_]+)EvosMoves:').allMatches(text).toList();
  for(var i=0;i<labels.length;i++){
    final id=ids[_norm(labels[i].group(1)!)]; if(id==null) continue; final end=i+1<labels.length?labels[i+1].start:text.length; final block=text.substring(labels[i].end,end);
    final marker=block.indexOf('; Learnset'); if(marker<0){out[id]=[];continue;} final part=block.substring(marker);
    final moves=< _Move>[]; for(final m in RegExp(r'db\s+(\d+)\s*,\s*([A-Z0-9_]+)').allMatches(part)){ moves.add(_Move(int.parse(m.group(1)!),m.group(2)!)); } out[id]=moves;
  } return out;
}

Map<int,List<String>> _machines(Directory dir,Map<String,int> ids){
  final out=<int,List<String>>{}; if(!dir.existsSync()) return out;
  for(final f in dir.listSync().whereType<File>().where((f)=>f.path.endsWith('.asm'))){ final t=f.readAsStringSync(); final dm=RegExp(r'DEX_([A-Z0-9_]+)').firstMatch(t); if(dm==null) continue; final id=ids[_norm(dm.group(1)!)]; if(id==null) continue; final m=RegExp(r'tmhm\s+([\s\S]*?)(?:; end|\n\s*db\s+0)').firstMatch(t); if(m==null){out[id]=[];continue;} out[id]=RegExp(r'[A-Z][A-Z0-9_]+').allMatches(m.group(1)!.replaceAll(r'\',' ')).map((x)=>x.group(0)!).toList(); }
  return out;
}

Map<int,List<_Encounter>> _encounters(Directory dir,Map<String,int> ids,String version){
  final out=<int,List<_Encounter>>{}; if(!dir.existsSync()) return out;
  for(final f in dir.listSync().whereType<File>()){
    var enabled=true; final stack=<bool>[]; final location=_pretty(f.uri.pathSegments.last.replaceAll('.asm',''));
    for(final raw in f.readAsLinesSync()){
      final l=raw.trim(); final cond=RegExp(r'IF DEF\(_([A-Z]+)\)').firstMatch(l); if(cond!=null){stack.add(enabled); enabled=enabled&&cond.group(1)==version; continue;} if(l.startsWith('ELSE')){if(stack.isNotEmpty) enabled=stack.last&&!enabled;continue;} if(l.startsWith('ENDC')){if(stack.isNotEmpty) enabled=stack.removeLast();continue;} if(!enabled) continue;
      final m=RegExp(r'db\s+\d+\s*,\s*([A-Z][A-Z0-9_]*)').firstMatch(l); if(m==null) continue; final id=ids[_norm(m.group(1)!)]; if(id==null) continue; final list=out.putIfAbsent(id,()=>[]); if(!list.any((e)=>e.location==location)) list.add(_Encounter(location,'Hierba/agua'));
    }
  } return out;
}

void _write(String path,String variable,String version,Map<int,String> names,Map<int,String> entries,Map<int,List<_Move>> learn,Map<int,List<String>> machines,Map<int,List<_Encounter>> enc,Map<String,String> moveNames){
  final b=StringBuffer("import 'pokedex_models.dart';\n\n// GENERATED FILE. Run: dart run tool/generate_gen1_pokedex.dart\nconst Map<int, PokedexSpeciesDetail> $variable = {\n");
  for(var id=1;id<=151;id++){
    b.writeln('  $id: PokedexSpeciesDetail('); final entry=entries[id]; if(entry!=null) b.writeln("    entry: '${_esc(entry)}',");
    b.writeln('    levelUpMoves: ['); for(final m in learn[id]??const[]){ b.writeln("      PokedexMove(level: ${m.level}, name: '${_esc(_pretty(m.name))}'),"); } b.writeln('    ],');
    b.writeln('    machines: ['); for(final m in machines[id]??const[]){ b.writeln("      '${_esc(_pretty(m))}',"); } b.writeln('    ],');
    b.writeln('    encounters: ['); for(final e in enc[id]??const[]){ b.writeln("      PokedexEncounter(location: '${_esc(e.location)}', method: '${e.method}', time: 'Cualquier hora'),"); } b.writeln('    ],'); b.writeln('  ),');
  } b.writeln('};'); File(path).writeAsStringSync(b.toString()); stdout.writeln('$version dataset written to $path.');
}
class _Move{final int level;final String name;const _Move(this.level,this.name);} class _Encounter{final String location;final String method;const _Encounter(this.location,this.method);}
