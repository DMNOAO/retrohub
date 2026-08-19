import 'dart:convert';
import 'dart:io';

/// Generates Ruby, Sapphire and Emerald Pokedex detail datasets from pret data.
///
/// Run with:
///   dart run tool/generate_gen3_pokedex.dart
Future<void> main() async {
  final tmp = await Directory.systemTemp.createTemp('retrohub_gen3_');
  final rs = Directory('${tmp.path}/pokeruby');
  final emerald = Directory('${tmp.path}/pokeemerald');
  try {
    await _clone('https://github.com/pret/pokeruby.git', rs.path);
    await _clone('https://github.com/pret/pokeemerald.git', emerald.path);

    final species = _speciesIds(File('${emerald.path}/include/constants/species.h'));
    final moveNames = _moveNames(File('${emerald.path}/include/constants/moves.h'));
    final entries = _entries(File('${emerald.path}/src/data/pokemon/pokedex_text.h'), species);
    final rsLearn = _learnsets(File('${rs.path}/src/data/pokemon/level_up_learnsets.h'), species, moveNames);
    final emeraldLearn = _learnsets(File('${emerald.path}/src/data/pokemon/level_up_learnsets.h'), species, moveNames);
    final rsMachines = _machines(File('${rs.path}/src/data/pokemon/tmhm_learnsets.h'), species, moveNames);
    final emeraldMachines = _machines(File('${emerald.path}/src/data/pokemon/tmhm_learnsets.h'), species, moveNames);

    final rsJson = jsonDecode(File('${rs.path}/src/data/wild_encounters.json').readAsStringSync()) as Map<String,dynamic>;
    final emeraldJson = jsonDecode(File('${emerald.path}/src/data/wild_encounters.json').readAsStringSync()) as Map<String,dynamic>;
    final rubyEnc = _encounters(rsJson, species, version: 'Ruby');
    final sapphireEnc = _encounters(rsJson, species, version: 'Sapphire');
    final emeraldEnc = _encounters(emeraldJson, species, version: 'Emerald');

    _write('lib/features/journal/data/ruby_pokedex_generated.dart','rubyGeneratedSpecies',entries,rsLearn,rsMachines,rubyEnc);
    _write('lib/features/journal/data/sapphire_pokedex_generated.dart','sapphireGeneratedSpecies',entries,rsLearn,rsMachines,sapphireEnc);
    _write('lib/features/journal/data/emerald_pokedex_generated.dart','emeraldGeneratedSpecies',entries,emeraldLearn,emeraldMachines,emeraldEnc);

    stdout.writeln('Gen III entries loaded: ${entries.length}/386.');
    stdout.writeln('Ruby/Sapphire learnsets: ${rsLearn.length}/386; TM/HM: ${rsMachines.length}/386.');
    stdout.writeln('Emerald learnsets: ${emeraldLearn.length}/386; TM/HM: ${emeraldMachines.length}/386.');
    stdout.writeln('Ruby wild encounter species: ${rubyEnc.length}/386.');
    stdout.writeln('Sapphire wild encounter species: ${sapphireEnc.length}/386.');
    stdout.writeln('Emerald wild encounter species: ${emeraldEnc.length}/386.');
  } finally {
    if (tmp.existsSync()) tmp.deleteSync(recursive:true);
  }
}

Future<void> _clone(String url,String path) async {
  final r=await Process.run('git',['clone','--depth','1','--quiet',url,path]);
  if(r.exitCode!=0) throw StateError('git clone failed: ${r.stderr}');
}

String _norm(String value)=>value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'),'');
String _pretty(String value)=>value.toLowerCase().split('_').map((p)=>p.isEmpty?'':p[0].toUpperCase()+p.substring(1)).join(' ');
String _esc(String value)=>value.replaceAll(r'\',r'\\').replaceAll("'",r"\'").replaceAll('\n',' ');

Map<String,int> _speciesIds(File file) {
  final out=<String,int>{};
  for(final line in file.readAsLinesSync()) {
    final m=RegExp(r'#define\s+SPECIES_([A-Z0-9_]+)\s+(\d+)').firstMatch(line);
    if(m!=null) {
      final id=int.parse(m.group(2)!);
      if(id>=1 && id<=386) out[_norm(m.group(1)!)]=id;
    }
  }
  return out;
}

Map<String,String> _moveNames(File file) {
  final out=<String,String>{};
  for(final line in file.readAsLinesSync()) {
    final m=RegExp(r'#define\s+MOVE_([A-Z0-9_]+)\s+\d+').firstMatch(line);
    if(m!=null) out[m.group(1)!]=_pretty(m.group(1)!);
  }
  return out;
}

Map<int,String> _entries(File file,Map<String,int> species) {
  final out=<int,String>{};
  final text=file.readAsStringSync();
  final labels=RegExp(r'const u8 g([A-Za-z0-9]+)PokedexText\[\]\s*=\s*_\(', multiLine:true).allMatches(text).toList();
  for(var i=0;i<labels.length;i++) {
    final id=species[_norm(labels[i].group(1)!)];
    if(id==null) continue;
    final end=i+1<labels.length?labels[i+1].start:text.length;
    final block=text.substring(labels[i].end,end);
    final pieces=RegExp(r'"([^"]*)"').allMatches(block).map((m)=>m.group(1)!).toList();
    if(pieces.isNotEmpty) out[id]=pieces.join(' ').replaceAll(r'\n',' ').replaceAll(RegExp(r'\s+'),' ').trim();
  }
  return out;
}

Map<int,List<_Move>> _learnsets(File file,Map<String,int> species,Map<String,String> moveNames) {
  final out=<int,List<_Move>>{};
  final text=file.readAsStringSync();
  final labels=RegExp(r's([A-Za-z0-9]+)LevelUpLearnset\[\]', multiLine:true).allMatches(text).toList();
  for(var i=0;i<labels.length;i++) {
    final id=species[_norm(labels[i].group(1)!)];
    if(id==null) continue;
    final end=i+1<labels.length?labels[i+1].start:text.length;
    final block=text.substring(labels[i].end,end);
    final moves=<_Move>[];
    for(final m in RegExp(r'LEVEL_UP_MOVE\(\s*(\d+)\s*,\s*MOVE_([A-Z0-9_]+)\s*\)').allMatches(block)) {
      moves.add(_Move(int.parse(m.group(1)!),moveNames[m.group(2)!]??_pretty(m.group(2)!)));
    }
    out[id]=moves;
  }
  return out;
}

Map<int,List<String>> _machines(File file,Map<String,int> species,Map<String,String> moveNames) {
  final out=<int,List<String>>{};
  final text=file.readAsStringSync();
  final labels=RegExp(r'\[SPECIES_([A-Z0-9_]+)\]\s*=\s*TMHM_LEARNSET\(', multiLine:true).allMatches(text).toList();
  for(var i=0;i<labels.length;i++) {
    final id=species[_norm(labels[i].group(1)!)];
    if(id==null) continue;
    final end=i+1<labels.length?labels[i+1].start:text.length;
    final block=text.substring(labels[i].end,end);
    out[id]=RegExp(r'TMHM\(\s*([A-Z0-9_]+)\s*\)').allMatches(block).map((m)=>moveNames[m.group(1)!]??_pretty(m.group(1)!)).toList();
  }
  return out;
}

Map<int,List<_Encounter>> _encounters(Map<String,dynamic> root,Map<String,int> species,{required String version}) {
  final out=<int,List<_Encounter>>{};
  final groups=(root['wild_encounter_groups'] as List?)??const[];
  for(final group in groups) {
    if(group is! Map<String,dynamic>) continue;
    final encounters=(group['encounters'] as List?)??const[];
    for(final encounter in encounters) {
      if(encounter is! Map<String,dynamic>) continue;
      final label=(encounter['base_label']??'').toString().toLowerCase();
      if((label.contains('_ruby') && version=='Sapphire') || (label.contains('_sapphire') && version=='Ruby')) continue;
      final location=_pretty((encounter['map']??'Unknown').toString().replaceFirst('MAP_',''));
      for(final field in const ['land_mons','water_mons','rock_smash_mons','fishing_mons']) {
        final data=encounter[field];
        if(data is! Map<String,dynamic>) continue;
        final method=field=='land_mons'?'Hierba':field=='water_mons'?'Surf':field=='rock_smash_mons'?'Golpe Roca':'Pesca';
        final mons=(data['mons'] as List?)??const[];
        for(final mon in mons) {
          if(mon is! Map<String,dynamic>) continue;
          final raw=(mon['species']??'').toString().replaceFirst('SPECIES_','');
          final id=species[_norm(raw)];
          if(id==null) continue;
          final list=out.putIfAbsent(id,()=>[]);
          if(!list.any((e)=>e.location==location&&e.method==method)) list.add(_Encounter(location,method));
        }
      }
    }
  }
  return out;
}

void _write(String path,String variable,Map<int,String> entries,Map<int,List<_Move>> learn,Map<int,List<String>> machines,Map<int,List<_Encounter>> encounters) {
  final b=StringBuffer("import 'pokedex_models.dart';\n\n// GENERATED FILE. Run: dart run tool/generate_gen3_pokedex.dart\nconst Map<int, PokedexSpeciesDetail> $variable = {\n");
  for(var id=1;id<=386;id++) {
    b.writeln('  $id: PokedexSpeciesDetail(');
    final entry=entries[id];
    if(entry!=null) b.writeln("    entry: '${_esc(entry)}',");
    b.writeln('    levelMoves: [');
    for(final m in learn[id]??const[]) b.writeln("      PokedexMove(${m.level}, '${_esc(m.name)}'),");
    b.writeln('    ],');
    b.writeln('    machineMoves: [');
    for(final m in machines[id]??const[]) b.writeln("      PokedexMachineMove('MT/MO', '${_esc(m)}'),");
    b.writeln('    ],');
    b.writeln('    encounters: [');
    for(final e in encounters[id]??const[]) b.writeln("      PokedexEncounter(location: '${_esc(e.location)}', method: '${e.method}', time: 'Cualquier hora'),");
    b.writeln('    ],');
    b.writeln('  ),');
  }
  b.writeln('};');
  File(path).writeAsStringSync(b.toString());
  stdout.writeln('Dataset written: $path');
}

class _Move { final int level; final String name; const _Move(this.level,this.name); }
class _Encounter { final String location; final String method; const _Encounter(this.location,this.method); }
