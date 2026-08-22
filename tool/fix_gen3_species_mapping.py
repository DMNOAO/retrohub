from pathlib import Path
import re
import urllib.request

SPECIES_URL = 'https://raw.githubusercontent.com/pret/pokeemerald/master/include/constants/species.h'
POKEDEX_URL = 'https://raw.githubusercontent.com/pret/pokeemerald/master/include/constants/pokedex.h'
TARGETS = [
    Path('lib/features/journal/data/ruby_pokedex_generated.dart'),
    Path('lib/features/journal/data/sapphire_pokedex_generated.dart'),
    Path('lib/features/journal/data/emerald_pokedex_generated.dart'),
]

def download(url):
    with urllib.request.urlopen(url) as r:
        return r.read().decode()

def national_ids(pokedex):
    out = {}
    in_enum = False
    idx = -1
    for raw in pokedex.splitlines():
        line = raw.strip()
        if line == '// National Pokédex order':
            in_enum = True
            continue
        if not in_enum:
            continue
        if line == '};':
            break
        m = re.match(r'^NATIONAL_DEX_([A-Z0-9_]+),?$', line)
        if not m:
            continue
        idx += 1
        if m.group(1) != 'NONE' and 1 <= idx <= 386:
            out[m.group(1)] = idx
    return out

def wrong_to_correct(species, national):
    out = {}
    for m in re.finditer(r'^#define\s+SPECIES_([A-Z0-9_]+)\s+(\d+)\s*$', species, re.M):
        name, internal = m.group(1), int(m.group(2))
        if name in national:
            wrong = internal if internal <= 251 else internal - 25
            if 1 <= wrong <= 386:
                out[wrong] = national[name]
    return out

def split_blocks(text):
    matches = list(re.finditer(r'^  (\d+): PokedexSpeciesDetail\(', text, re.M))
    prefix = text[:matches[0].start()]
    suffix_start = text.rfind('};')
    suffix = text[suffix_start:]
    blocks = {}
    for i, m in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < len(matches) else suffix_start
        blocks[int(m.group(1))] = text[m.start():end]
    return prefix, blocks, suffix

def field(block, name, next_name):
    m = re.search(rf'    {name}: \[\n(.*?)    \],\n    {next_name}:', block, re.S)
    if not m:
        raise RuntimeError(f'Could not parse {name}')
    return m.group(1)

def replace_field(block, name, next_name, body):
    return re.sub(
        rf'(    {name}: \[\n).*?(    \],\n    {next_name}:)',
        lambda m: m.group(1) + body + m.group(2),
        block,
        count=1,
        flags=re.S,
    )

def remap_dataset(path, mapping):
    text = path.read_text(encoding='utf-8')
    prefix, blocks, suffix = split_blocks(text)
    source = dict(blocks)
    for wrong, correct in mapping.items():
        if wrong == correct or wrong not in source or correct not in blocks:
            continue
        src = source[wrong]
        dst = blocks[correct]
        dst = replace_field(dst, 'levelMoves', 'machineMoves', field(src, 'levelMoves', 'machineMoves'))
        dst = replace_field(dst, 'machineMoves', 'encounters', field(src, 'machineMoves', 'encounters'))
        # encounters is the final list before the species object closes.
        em = re.search(r'    encounters: \[\n(.*?)    \],\n  \),', src, re.S)
        if not em:
            raise RuntimeError('Could not parse encounters')
        dst = re.sub(
            r'(    encounters: \[\n).*?(    \],\n  \),)',
            lambda m: m.group(1) + em.group(1) + m.group(2),
            dst,
            count=1,
            flags=re.S,
        )
        blocks[correct] = dst
    path.write_text(prefix + ''.join(blocks[i] for i in sorted(blocks)) + suffix, encoding='utf-8')

def patch_generator():
    path = Path('tool/generate_gen3_pokedex.dart')
    text = path.read_text(encoding='utf-8')
    text = text.replace("File('${emerald.path}/include/constants/species.h'),\n    );\n    final moveNames", "File('${emerald.path}/include/constants/pokedex.h'),\n    );\n    final moveNames", 1)
    start = text.index('Map<String, int> _nationalSpeciesIds(File file) {')
    end = text.index('\nMap<String, String> _moveNames', start)
    fn = '''Map<String, int> _nationalSpeciesIds(File file) {
  final out = <String, int>{};
  var nationalId = -1;
  var inNationalEnum = false;
  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line == '// National Pokédex order') {
      inNationalEnum = true;
      continue;
    }
    if (!inNationalEnum) continue;
    if (line == '};') break;
    final match = RegExp(r'^NATIONAL_DEX_([A-Z0-9_]+),?$').firstMatch(line);
    if (match == null) continue;
    nationalId++;
    final name = match.group(1)!;
    if (name != 'NONE' && nationalId >= 1 && nationalId <= 386) {
      out[_norm(name)] = nationalId;
    }
  }
  return out;
}
'''
    text = text[:start] + fn + text[end:]
    path.write_text(text, encoding='utf-8')

species = download(SPECIES_URL)
pokedex = download(POKEDEX_URL)
mapping = wrong_to_correct(species, national_ids(pokedex))
for target in TARGETS:
    remap_dataset(target, mapping)
patch_generator()
print(f'Remapped {sum(1 for a,b in mapping.items() if a != b)} Gen III species entries.')
