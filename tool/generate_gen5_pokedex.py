#!/usr/bin/env python3
"""Generate Pokémon Black/White Pokédex and ability data from PokeAPI CSVs."""

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV = Path('/tmp/retrohub-pokeapi/data/v2/csv')
VERSION_GROUP = 11
VERSIONS = {17, 18}
LANGUAGE = 7


def rows(name):
    with (CSV / name).open(encoding='utf-8', newline='') as source:
        return list(csv.DictReader(source))


def localized(name, id_field, text_field='name'):
    return {int(r[id_field]): r[text_field] for r in rows(name)
            if int(r.get('local_language_id', r.get('language_id', 0))) == LANGUAGE}


def esc(value):
    return value.replace('\\', '\\\\').replace("'", "\\'").replace('\n', ' ').replace('\f', ' ').strip()


def main():
    move_names = localized('move_names.csv', 'move_id')
    ability_names = localized('ability_names.csv', 'ability_id')
    location_names = localized('location_names.csv', 'location_id')
    species_names = localized('pokemon_species_names.csv', 'pokemon_species_id')
    locations = {int(r['id']): r['identifier'] for r in rows('locations.csv')}
    areas = {int(r['id']): r for r in rows('location_areas.csv')}
    slots = {int(r['id']): int(r['encounter_method_id']) for r in rows('encounter_slots.csv')}
    methods = {1: 'Hierba', 2: 'Cueva', 3: 'Puente', 4: 'Surf', 5: 'Pesca',
               6: 'Pesca', 7: 'Pesca', 8: 'Pesca', 9: 'Hierba oscura',
               10: 'Hierba', 11: 'Hierba agitada', 12: 'Polvo',
               13: 'Sombra', 14: 'Agua agitada', 15: 'Pesca'}

    entries = {}
    for row in rows('pokemon_species_flavor_text.csv'):
        species = int(row['species_id'])
        if int(row['language_id']) != LANGUAGE or species > 649:
            continue
        # PokeAPI lacks Spanish BW flavor text. Prefer the earliest available
        # official Spanish entry, which keeps the application fully localized.
        entries.setdefault(species, row['flavor_text'])

    level_moves, machine_moves = {}, {}
    machines = {(int(r['move_id']), int(r['version_group_id'])): int(r['machine_number'])
                for r in rows('machines.csv')}
    for row in rows('pokemon_moves.csv'):
        if int(row['version_group_id']) != VERSION_GROUP:
            continue
        species, move, method = int(row['pokemon_id']), int(row['move_id']), int(row['pokemon_move_method_id'])
        if species > 649:
            continue
        if method == 1:
            level_moves.setdefault(species, []).append((int(row['level']), move))
        elif method == 4:
            number = machines.get((move, VERSION_GROUP))
            if number is not None:
                label = f'MT{number:02d}' if number <= 95 else f'MO{number - 100:02d}'
                machine_moves.setdefault(species, []).append((label, move))

    encounters = {}
    for row in rows('encounters.csv'):
        if int(row['version_id']) not in VERSIONS:
            continue
        species = int(row['pokemon_id'])
        area = areas.get(int(row['location_area_id']))
        if species > 649 or area is None:
            continue
        location_id = int(area['location_id'])
        place = location_names.get(location_id, locations.get(location_id, 'Teselia').replace('-', ' ').title())
        area_name = area['identifier'].replace('-', ' ').title()
        if area_name and area_name not in {'', 'Area'} and area_name.lower() not in place.lower():
            place = f'{place} · {area_name}'
        value = (place, methods.get(slots.get(int(row['encounter_slot_id']), 0), 'Encuentro'), 'Cualquier hora')
        if value not in encounters.setdefault(species, []):
            encounters[species].append(value)
    for species, place in ((495, 'Pueblo Arcilla'), (498, 'Pueblo Arcilla'), (501, 'Pueblo Arcilla')):
        encounters[species] = [(place, 'Pokémon inicial', 'Cualquier hora')]

    species_rows = {int(r['id']): r for r in rows('pokemon_species.csv') if int(r['id']) <= 649}
    evolutions = {}
    evolution_rows = {int(r['evolved_species_id']): r for r in rows('pokemon_evolution.csv')}
    for target, species_row in species_rows.items():
        parent = species_row['evolves_from_species_id']
        if not parent:
            continue
        rule = evolution_rows.get(target, {})
        trigger = int(rule.get('evolution_trigger_id') or 0)
        if rule.get('minimum_level'):
            condition = f'al Nv. {rule["minimum_level"]}'
        elif rule.get('minimum_happiness'):
            condition = 'con amistad alta'
        elif trigger == 2:
            condition = 'mediante intercambio'
        elif trigger == 3:
            condition = 'usando el objeto evolutivo correspondiente'
        else:
            condition = 'cumpliendo su condición especial'
        evolutions.setdefault(int(parent), []).append(
            f'Evoluciona a {species_names.get(target, "Pokémon #" + str(target))} {condition}.'
        )

    def render_species(first, last, variable):
        output = ["import 'pokedex_models.dart';", '',
                  '// GENERATED FILE. Run: python tool/generate_gen5_pokedex.py',
                  f'const Map<int, PokedexSpeciesDetail> {variable} = {{']
        for species in range(first, last + 1):
            output.append(f'  {species}: PokedexSpeciesDetail(')
            if species in entries:
                output.append(f"    entry: '{esc(entries[species])}',")
            output.append('    levelMoves: [')
            for level, move in sorted(set(level_moves.get(species, []))):
                output.append(f"      PokedexMove({level}, '{esc(move_names.get(move, 'Movimiento ' + str(move)))}'),")
            output.append('    ],')
            output.append('    machineMoves: [')
            for machine, move in sorted(set(machine_moves.get(species, []))):
                output.append(f"      PokedexMachineMove('{machine}', '{esc(move_names.get(move, 'Movimiento ' + str(move)))}'),")
            output.append('    ],')
            output.append('    encounters: [')
            for place, method, time in encounters.get(species, []):
                output.append(f"      PokedexEncounter(location: '{esc(place)}', method: '{method}', time: '{time}'),")
            output.extend(['    ],', '  ),'])
        output.append('};')
        return '\n'.join(output) + '\n'

    generated_dir = ROOT / 'lib/features/journal/data'
    chunks = []
    for first in range(1, 650, 50):
        last = min(first + 49, 649)
        variable = f'blackWhiteSpecies{first}To{last}'
        filename = f'black_white_pokedex_{first}_{last}.dart'
        (generated_dir / filename).write_text(render_species(first, last, variable))
        chunks.append((filename, variable))
    imports = [f"import '{filename}';" for filename, _ in chunks]
    output = imports + ["import 'pokedex_models.dart';", '',
                        '// GENERATED FILE. Run: python tool/generate_gen5_pokedex.py',
                        'const Map<int, PokedexSpeciesDetail> blackWhiteGeneratedSpecies = {']
    output += [f'  ...{variable},' for _, variable in chunks]
    output.append('};')
    (generated_dir / 'black_white_pokedex_generated.dart').write_text('\n'.join(output) + '\n')

    species_abilities = {}
    for row in rows('pokemon_abilities.csv'):
        species = int(row['pokemon_id'])
        if species <= 649:
            species_abilities.setdefault(species, []).append((int(row['slot']), int(row['ability_id'])))
    ability_desc = {}
    for row in rows('ability_flavor_text.csv'):
        if int(row['language_id']) == LANGUAGE:
            ability_desc[int(row['ability_id'])] = row['flavor_text']
    abilities = ['// GENERATED FILE. Run: python tool/generate_gen5_pokedex.py',
                 'const Map<int, List<int>> gen5SpeciesAbilities = {']
    for species, values in species_abilities.items():
        ordered = [ability for _, ability in sorted(values)]
        abilities.append(f'  {species}: <int>{ordered},')
    abilities.extend(['};', '', 'const Map<int, (String, String)> gen5Abilities = {'])
    for ability in range(1, 165):
        if ability in ability_names:
            abilities.append(f"  {ability}: ('{esc(ability_names[ability])}', '{esc(ability_desc.get(ability, ''))}'),")
    abilities.append('};')
    (ROOT / 'lib/features/pokemon/decoder/gen5_ability_data.dart').write_text('\n'.join(abilities) + '\n')

    evolution_output = ['// GENERATED FILE. Run: python tool/generate_gen5_pokedex.py',
                        'const Map<int, String> gen5EvolutionData = {']
    for species, rules in evolutions.items():
        evolution_output.append(f"  {species}: '{esc(chr(10).join(rules))}',")
    evolution_output.append('};')
    (ROOT / 'lib/features/journal/data/gen5_evolution_data.dart').write_text('\n'.join(evolution_output) + '\n')


if __name__ == '__main__':
    main()
