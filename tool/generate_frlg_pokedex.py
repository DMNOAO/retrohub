#!/usr/bin/env python3
"""Generate the FireRed/LeafGreen journal dataset from pret/pokefirered."""

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRET = Path('/tmp/pokefirered')


def norm(value: str) -> str:
    return re.sub(r'[^A-Z0-9]', '', value.upper())


def pretty(value: str) -> str:
    return ' '.join(part.capitalize() for part in value.lower().split('_'))


def escaped(value: str) -> str:
    return value.replace('\\', '\\\\').replace("'", "\\'").replace('\n', ' ')


def species_ids() -> dict[str, int]:
    result = {}
    text = (PRET / 'include/constants/species.h').read_text()
    for name, raw_id in re.findall(r'#define\s+SPECIES_([A-Z0-9_]+)\s+(\d+)', text):
        internal_id = int(raw_id)
        if 1 <= internal_id <= 251:
            result[norm(name)] = internal_id
        elif 277 <= internal_id <= 411:
            result[norm(name)] = internal_id - 25
    return result


def move_names() -> tuple[dict[str, str], dict[str, str]]:
    ids = {}
    text = (PRET / 'include/constants/moves.h').read_text()
    for name, raw_id in re.findall(r'#define\s+MOVE_([A-Z0-9_]+)\s+(\d+)', text):
        ids[name] = int(raw_id)
    spanish = {}
    with Path('/tmp/move_names.csv').open(newline='') as source:
        for row in csv.reader(source):
            if len(row) >= 3 and row[0].isdigit() and row[1] == '7':
                spanish[int(row[0])] = row[2].strip()
    localized = {
        name: spanish.get(move_id, pretty(name))
        for name, move_id in ids.items()
        if move_id <= 354
    }
    return localized, {name: pretty(name) for name in ids}


def spanish_entries() -> dict[int, str]:
    text = (ROOT / 'lib/features/journal/data/emerald_pokedex_generated.dart').read_text()
    result = {}
    pattern = re.compile(r"  (\d+): PokedexSpeciesDetail\((.*?)\n  \),", re.S)
    for raw_id, body in pattern.findall(text):
        match = re.search(r"\n    entry: '((?:\\.|[^'])*)',", body)
        if match:
            result[int(raw_id)] = match.group(1)
    return result


def blocks(path: Path, label_pattern: str) -> dict[str, str]:
    text = path.read_text()
    labels = list(re.finditer(label_pattern, text))
    result = {}
    for index, label in enumerate(labels):
        end = labels[index + 1].start() if index + 1 < len(labels) else len(text)
        result[norm(label.group(1))] = text[label.end():end]
    return result


def learnsets(species: dict[str, int], names: dict[str, str]) -> dict[int, list[tuple[int, str]]]:
    source = blocks(
        PRET / 'src/data/pokemon/level_up_learnsets.h',
        r'static const u16 s([A-Za-z0-9]+)LevelUpLearnset\[\]',
    )
    result = {}
    for name, block in source.items():
        species_id = species.get(name)
        if species_id is None:
            continue
        result[species_id] = [
            (int(level), names.get(move, pretty(move)))
            for level, move in re.findall(
                r'LEVEL_UP_MOVE\(\s*(\d+)\s*,\s*MOVE_([A-Z0-9_]+)\s*\)',
                block,
            )
        ]
    return result


def machines(species: dict[str, int], names: dict[str, str]) -> dict[int, list[str]]:
    source = blocks(
        PRET / 'src/data/pokemon/tmhm_learnsets.h',
        r'\[SPECIES_([A-Z0-9_]+)\]\s*=\s*TMHM_LEARNSET\(',
    )
    result = {}
    for name, block in source.items():
        species_id = species.get(name)
        if species_id is None:
            continue
        result[species_id] = [
            names.get(move, pretty(move))
            for move in re.findall(r'TMHM\(\s*(?:TM\d+_|HM\d+_)?([A-Z0-9_]+)\s*\)', block)
        ]
    return result


LOCATION_REPLACEMENTS = {
    'Pallet Town': 'Pueblo Paleta', 'Viridian City': 'Ciudad Verde',
    'Pewter City': 'Ciudad Plateada', 'Cerulean City': 'Ciudad Celeste',
    'Lavender Town': 'Pueblo Lavanda', 'Vermilion City': 'Ciudad Carmín',
    'Celadon City': 'Ciudad Azulona', 'Fuchsia City': 'Ciudad Fucsia',
    'Cinnabar Island': 'Isla Canela', 'Saffron City': 'Ciudad Azafrán',
    'Viridian Forest': 'Bosque Verde', 'Mt Moon': 'Monte Moon',
    'Pokemon Mansion': 'Mansión Pokémon', 'Safari Zone': 'Zona Safari',
    'Power Plant': 'Central Energía', 'Seafoam Islands': 'Islas Espuma',
    'Cerulean Cave': 'Cueva Celeste', 'Rock Tunnel': 'Túnel Roca',
    'Digletts Cave': 'Cueva Diglett', 'Victory Road': 'Calle Victoria',
}


def location_name(raw: str) -> str:
    value = pretty(raw.replace('MAP_', ''))
    value = re.sub(r'Route (\d+)', r'Ruta \1', value)
    for source, target in LOCATION_REPLACEMENTS.items():
        value = value.replace(source, target)
    return value.replace(' Pokemon Center', ' Centro Pokémon').replace(' Gym', ' Gimnasio')


def encounters(species: dict[str, int]) -> dict[int, list[tuple[str, str]]]:
    root = json.loads((PRET / 'src/data/wild_encounters.json').read_text())
    result: dict[int, list[tuple[str, str]]] = {}
    methods = {
        'land_mons': 'Hierba', 'water_mons': 'Surf',
        'rock_smash_mons': 'Golpe Roca', 'fishing_mons': 'Pesca',
    }
    for group in root.get('wild_encounter_groups', []):
        for encounter in group.get('encounters', []):
            location = location_name(str(encounter.get('map', 'Unknown')))
            for field, method in methods.items():
                data = encounter.get(field)
                if not isinstance(data, dict):
                    continue
                for mon in data.get('mons', []):
                    species_id = species.get(norm(str(mon.get('species', '')).replace('SPECIES_', '')))
                    if species_id is None:
                        continue
                    item = (location, method)
                    values = result.setdefault(species_id, [])
                    if item not in values:
                        values.append(item)
    return result


def main() -> None:
    species = species_ids()
    localized_moves, _ = move_names()
    entries = spanish_entries()
    level_moves = learnsets(species, localized_moves)
    machine_moves = machines(species, localized_moves)
    wild = encounters(species)
    wild.setdefault(1, []).insert(0, ('Pueblo Paleta', 'Pokémon inicial'))
    wild.setdefault(4, []).insert(0, ('Pueblo Paleta', 'Pokémon inicial'))
    wild.setdefault(7, []).insert(0, ('Pueblo Paleta', 'Pokémon inicial'))
    output = ROOT / 'lib/features/journal/data/fire_red_leaf_green_pokedex_generated.dart'
    lines = [
        "import 'pokedex_models.dart';", '',
        '// GENERATED FILE. Run: python tool/generate_frlg_pokedex.py',
        'const Map<int, PokedexSpeciesDetail> fireRedLeafGreenGeneratedSpecies = {',
    ]
    for species_id in range(1, 387):
        lines.append(f'  {species_id}: PokedexSpeciesDetail(')
        if species_id in entries:
            lines.append(f"    entry: '{entries[species_id]}',")
        lines.append('    levelMoves: [')
        for level, move in level_moves.get(species_id, []):
            lines.append(f"      PokedexMove({level}, '{escaped(move)}'),")
        lines.append('    ],')
        lines.append('    machineMoves: [')
        for move in machine_moves.get(species_id, []):
            lines.append(f"      PokedexMachineMove('MT/MO', '{escaped(move)}'),")
        lines.append('    ],')
        lines.append('    encounters: [')
        for location, method in wild.get(species_id, []):
            lines.append(
                f"      PokedexEncounter(location: '{escaped(location)}', "
                f"method: '{method}', time: 'Cualquier hora'),"
            )
        lines.extend(['    ],', '  ),'])
    lines.append('};')
    output.write_text('\n'.join(lines) + '\n')
    print(f'Generated {output}: entries={len(entries)}, learnsets={len(level_moves)}, machines={len(machine_moves)}, encounters={len(wild)}')


if __name__ == '__main__':
    main()
