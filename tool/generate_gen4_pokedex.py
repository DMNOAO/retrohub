#!/usr/bin/env python3
"""Generate RetroHub's Gen IV data from pret/pokeplatinum and PokeAPI CSVs."""

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLATINUM = Path('/tmp/retrohub-pokeplatinum')
CSV = Path('/tmp/retrohub-pokeapi/data/v2/csv')


def rows(name):
    with (CSV / name).open(encoding='utf-8', newline='') as source:
        return list(csv.DictReader(source))


def localized(name, id_field, language=7):
    return {int(r[id_field]): r['name'] for r in rows(name)
            if int(r['local_language_id']) == language}


def identifiers(name, id_field):
    return {r['identifier'].upper().replace('-', '_'): int(r[id_field]) for r in rows(name)}


def esc(value):
    return value.replace('\\', '\\\\').replace("'", "\\'").replace('\n', ' ').strip()


def location(raw):
    value = raw.removeprefix('encounters_').replace('_', ' ').title()
    replacements = {
        'Route ': 'Ruta ', 'Mt Coronet': 'Monte Corona', 'Oreburgh': 'Pirita',
        'Eterna': 'Vetusta', 'Hearthome': 'Corazón', 'Solaceon': 'Sosiego',
        'Veilstone': 'Rocavelo', 'Pastoria': 'Pradera', 'Canalave': 'Canal',
        'Snowpoint': 'Puntaneva', 'Sunyshore': 'Marina', 'Victory Road': 'Calle Victoria',
        'Old Chateau': 'Vieja Mansión', 'Great Marsh': 'Gran Pantano',
        'Iron Island': 'Isla Hierro', 'Turnback Cave': 'Cueva Retorno',
        'Lakefront': 'Orilla del Lago', 'Stark Mountain': 'Montaña Dura',
    }
    for source, target in replacements.items():
        value = value.replace(source, target)
    return value


def main():
    species_ids = identifiers('pokemon_species.csv', 'id')
    move_ids = identifiers('moves.csv', 'id')
    ability_ids = identifiers('abilities.csv', 'id')
    move_names = localized('move_names.csv', 'move_id')
    species_names = localized('pokemon_species_names.csv', 'pokemon_species_id')
    ability_names = localized('ability_names.csv', 'ability_id')
    ability_desc = {int(r['ability_id']): r['short_effect'] for r in rows('ability_prose.csv')
                    if int(r['local_language_id']) == 7}
    for row in rows('ability_flavor_text.csv'):
        if int(row['language_id']) == 7:
            ability_desc[int(row['ability_id'])] = row['flavor_text']
    tm_moves = {}
    for path in (PLATINUM / 'res/items/data').glob('[th]m*.json'):
        data = json.loads(path.read_text())
        if data.get('teachesMove'):
            tm_moves[data['name']] = move_ids[data['teachesMove'].removeprefix('MOVE_')]

    details = {}
    abilities = {}
    types = {}
    tutor_moves = {}
    egg_moves = {}
    base_species = {}
    evolutions = {}
    for species_id in range(1, 494):
        identifier = next((key for key, value in species_ids.items() if value == species_id), None)
        if not identifier:
            continue
        path = PLATINUM / 'res/pokemon' / identifier.lower() / 'data.json'
        if not path.exists():
            continue
        data = json.loads(path.read_text())
        learnset = data.get('learnset', {})
        entry = ''.join(data.get('pokedex_data', {}).get('es', {}).get('entry_text', []))
        details[species_id] = {
            'entry': entry,
            'level': [(level, move_ids.get(move.removeprefix('MOVE_'), 0))
                      for level, move in learnset.get('by_level', [])],
            'machines': [(machine, tm_moves.get(machine, 0)) for machine in learnset.get('by_tm', [])],
        }
        abilities[species_id] = [ability_ids[a.removeprefix('ABILITY_')]
                                 for a in data.get('abilities', []) if a != 'ABILITY_NONE']
        types[species_id] = list(dict.fromkeys(
            value.removeprefix('TYPE_').lower() for value in data.get('types', [])
        ))
        tutor_moves[species_id] = [move_ids[m.removeprefix('MOVE_')]
                                   for m in learnset.get('by_tutor', [])
                                   if m.removeprefix('MOVE_') in move_ids]
        egg_moves[species_id] = [move_ids[m.removeprefix('MOVE_')]
                                 for m in learnset.get('egg_moves', [])
                                 if m.removeprefix('MOVE_') in move_ids]
        offspring = data.get('offspring', '').removeprefix('SPECIES_')
        base_species[species_id] = species_ids.get(offspring, species_id)
        rules = []
        for evolution in data.get('evolutions', []):
            method, parameter, target = (evolution[0], '', evolution[1]) if len(evolution) == 2 else evolution
            target_id = species_ids.get(target.removeprefix('SPECIES_'))
            target_name = species_names.get(target_id, target.removeprefix('SPECIES_').title())
            labels = {
                'EVO_LEVEL': f'al Nv. {parameter}', 'EVO_TRADE': 'mediante intercambio',
                'EVO_FRIENDSHIP': 'con amistad alta', 'EVO_FRIENDSHIP_DAY': 'con amistad alta de día',
                'EVO_FRIENDSHIP_NIGHT': 'con amistad alta de noche',
                'EVO_TRADE_WITH_HELD_ITEM': f'al intercambiarlo con {str(parameter).removeprefix("ITEM_").replace("_", " ").title()}',
                'EVO_USE_ITEM': f'usando {str(parameter).removeprefix("ITEM_").replace("_", " ").title()}',
                'EVO_LEVEL_ATK_GT_DEF': f'al Nv. {parameter} si Ataque > Defensa',
                'EVO_LEVEL_ATK_EQ_DEF': f'al Nv. {parameter} si Ataque = Defensa',
                'EVO_LEVEL_ATK_LT_DEF': f'al Nv. {parameter} si Ataque < Defensa',
                'EVO_LEVEL_MALE': f'al Nv. {parameter} si es macho',
                'EVO_LEVEL_FEMALE': f'al Nv. {parameter} si es hembra',
                'EVO_LEVEL_DAY': f'al Nv. {parameter} de día', 'EVO_LEVEL_NIGHT': f'al Nv. {parameter} de noche',
                'EVO_LEVEL_KNOW_MOVE': f'al subir de nivel con el movimiento requerido',
                'EVO_LEVEL_WITH_MON_IN_PARTY': 'al subir de nivel con el Pokémon requerido en el equipo',
                'EVO_LEVEL_MAGNETIC_FIELD': 'al subir de nivel en Monte Corona',
                'EVO_LEVEL_MOSS_ROCK': 'al subir de nivel cerca de la Roca Musgo',
                'EVO_LEVEL_ICE_ROCK': 'al subir de nivel cerca de la Roca Hielo',
                'EVO_LEVEL_HAPPINESS': 'con amistad alta',
                'EVO_LEVEL_HAPPINESS_DAY': 'con amistad alta de día',
                'EVO_LEVEL_HAPPINESS_NIGHT': 'con amistad alta de noche',
            }
            rules.append(f'Evoluciona a {target_name} {labels.get(method, "cumpliendo su condición especial")}.')
        evolutions[species_id] = rules

    encounters = {}
    fields = {
        'land_encounters': ('Hierba', 'Cualquier hora'), 'day': ('Hierba', 'Día'),
        'night': ('Hierba', 'Noche'), 'surf_encounters': ('Surf', 'Cualquier hora'),
        'old_rod_encounters': ('Caña Vieja', 'Cualquier hora'),
        'good_rod_encounters': ('Caña Buena', 'Cualquier hora'),
        'super_rod_encounters': ('Supercaña', 'Cualquier hora'),
    }
    for path in (PLATINUM / 'res/field/encounters').glob('encounters_*.json'):
        data = json.loads(path.read_text())
        for field, (method, time) in fields.items():
            for item in data.get(field, []):
                raw = item.get('species') if isinstance(item, dict) else item
                if not raw or raw == 'SPECIES_NONE':
                    continue
                species_id = species_ids.get(raw.removeprefix('SPECIES_'))
                if not species_id:
                    continue
                value = (location(path.stem), method, time)
                if value not in encounters.setdefault(species_id, []):
                    encounters[species_id].append(value)
    for species_id in (387, 390, 393):
        encounters.setdefault(species_id, []).insert(0, ('Lago Veraz', 'Pokémon inicial', 'Cualquier hora'))

    out = ["import 'pokedex_models.dart';", '', '// GENERATED FILE. Run: python tool/generate_gen4_pokedex.py',
           'const Map<int, PokedexSpeciesDetail> platinumGeneratedSpecies = {']
    for species_id in range(1, 494):
        data = details.get(species_id, {})
        out.append(f'  {species_id}: PokedexSpeciesDetail(')
        if data.get('entry'):
            out.append(f"    entry: '{esc(data['entry'])}',")
        out.append('    levelMoves: [')
        for level, move_id in data.get('level', []):
            out.append(f"      PokedexMove({level}, '{esc(move_names.get(move_id, 'Movimiento ' + str(move_id)))}'),")
        out.append('    ],')
        out.append('    machineMoves: [')
        for machine, move_id in data.get('machines', []):
            out.append(f"      PokedexMachineMove('{machine}', '{esc(move_names.get(move_id, 'Movimiento ' + str(move_id)))}'),")
        out.append('    ],')
        out.append('    encounters: [')
        for place, method, time in encounters.get(species_id, []):
            out.append(f"      PokedexEncounter(location: '{esc(place)}', method: '{method}', time: '{time}'),")
        out.extend(['    ],', '  ),'])
    out.append('};')
    (ROOT / 'lib/features/journal/data/platinum_pokedex_generated.dart').write_text('\n'.join(out) + '\n')

    ability_out = ['// GENERATED FILE. Run: python tool/generate_gen4_pokedex.py',
                   'const Map<int, List<int>> gen4SpeciesAbilities = {']
    ability_out += [f'  {key}: <int>{value},' for key, value in abilities.items()]
    ability_out += ['};', '', 'const Map<int, (String, String)> gen4Abilities = {']
    for ability_id in range(1, 124):
        if ability_id in ability_names:
            ability_out.append(f"  {ability_id}: ('{esc(ability_names[ability_id])}', '{esc(ability_desc.get(ability_id, ''))}'),")
    ability_out.append('};')
    (ROOT / 'lib/features/pokemon/decoder/gen4_ability_data.dart').write_text('\n'.join(ability_out) + '\n')

    type_out = ["import 'move_type_resolver.dart';", '',
                '// GENERATED FILE. Run: python tool/generate_gen4_pokedex.py',
                'const Map<int, List<PokemonMoveType>> gen4PokemonTypes = {']
    for species_id, values in types.items():
        rendered = ', '.join(f'PokemonMoveType.{value}' for value in values)
        type_out.append(f'  {species_id}: <PokemonMoveType>[{rendered}],')
    type_out.append('};')
    (ROOT / 'lib/features/pokemon/decoder/gen4_pokemon_types.dart').write_text('\n'.join(type_out) + '\n')

    learnset_out = ['// GENERATED FILE. Run: python tool/generate_gen4_pokedex.py']
    for name, values in [('gen4TutorMoves', tutor_moves), ('gen4EggMoves', egg_moves)]:
        learnset_out.append(f'const Map<int, List<int>> {name} = {{')
        learnset_out += [f'  {key}: <int>{value},' for key, value in values.items() if value]
        learnset_out.append('};')
    learnset_out.append('const Map<int, int> gen4BaseSpecies = {')
    learnset_out += [f'  {key}: {value},' for key, value in base_species.items()]
    learnset_out.append('};')
    (ROOT / 'lib/features/pokemon/decoder/gen4_learnset_data.dart').write_text('\n'.join(learnset_out) + '\n')

    move_out = ['// GENERATED FILE. Run: python tool/generate_gen4_pokedex.py',
                'const Map<int, String> gen4MoveNames = {']
    move_out += [f"  {move_id}: '{esc(name)}'," for move_id, name in move_names.items()
                 if 355 <= move_id <= 467]
    move_out.append('};')
    (ROOT / 'lib/features/pokemon/decoder/gen4_move_names.dart').write_text('\n'.join(move_out) + '\n')

    evolution_out = ['// GENERATED FILE. Run: python tool/generate_gen4_pokedex.py',
                     'const Map<int, String> gen4EvolutionData = {']
    for species_id, rules in evolutions.items():
        if rules:
            evolution_out.append(f"  {species_id}: '{esc(chr(10).join(rules))}',")
    evolution_out.append('};')
    (ROOT / 'lib/features/journal/data/gen4_evolution_data.dart').write_text('\n'.join(evolution_out) + '\n')


if __name__ == '__main__':
    main()
