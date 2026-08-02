#!/usr/bin/env python3
"""
Generador de tablas de ubicaciones Pokémon para RetroHub.

Flujo:
    sources/pokecrystal_map_names.txt  (nombres verificados, sin IDs)
                    +
    sources/map_constants.txt          (IDs group:id verificados, uno por línea)
                    ↓
              este script
                    ↓
    lib/features/pokemon/decoder/locations/gen2/crystal_locations.dart
    (y gold/silver cuando tengan sus propios map_constants confirmados)

REGLA DE ORO: un símbolo SOLO aparece en el Dart de salida si tiene un ID
confirmado en sources/map_constants.txt. Si no lo tiene, se omite (se
reporta en el resumen como "pendiente"), nunca se inventa un número.

Para ampliar cobertura:
  1. Consigue el contenido real de constants/map_constants.asm (pokecrystal)
     o el equivalente de pokered/pokeyellow.
  2. Añade líneas `SYMBOLO = group:id` a sources/map_constants.txt.
  3. Vuelve a correr: python3 generate_locations.py
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).parent
SOURCES = ROOT / "sources"

# --- Capa de traducción/clasificación (curada a mano, separada de los IDs) ---
# Nombres oficiales en español de Pokémon Oro/Plata/Cristal, ampliamente
# documentados. Si un símbolo no está aquí, se usa un nombre de respaldo
# derivado del símbolo en inglés (marcado como sin traducir) en vez de
# inventar una traducción.
SPANISH_NAMES: dict[str, str] = {
    "NEW_BARK_TOWN": "Pueblo Primavera",
    "CHERRYGROVE_CITY": "Ciudad Cerezo",
    "VIOLET_CITY": "Ciudad Malva",
    "AZALEA_TOWN": "Pueblo Azalea",
    "GOLDENROD_CITY": "Ciudad Trigal",
    "ECRUTEAK_CITY": "Ciudad Iris",
    "OLIVINE_CITY": "Ciudad Olivo",
    "CIANWOOD_CITY": "Ciudad Orquídea",
    "MAHOGANY_TOWN": "Pueblo Caoba",
    "BLACKTHORN_CITY": "Ciudad Endrino",
    "SPROUT_TOWER_1F": "Torre Bellsprout (1F)",
    "SPROUT_TOWER_2F": "Torre Bellsprout (2F)",
    "SPROUT_TOWER_3F": "Torre Bellsprout (3F)",
    "RUINS_OF_ALPH_OUTSIDE": "Ruinas de Alph",
    "UNION_CAVE_1F": "Cueva Unión (1F)",
    "SLOWPOKE_WELL": "Pozo Slowpoke",
    "ILEX_FOREST": "Bosque Azalea",
    "RADIO_TOWER_1F": "Torre Radio",
    "NATIONAL_PARK": "Parque Nacional",
    "BURNED_TOWER_1F": "Torre Quemada",
    "TIN_TOWER_1F": "Torre Hojalata",
    "OLIVINE_PORT": "Puerto de Ciudad Olivo",
    "WHIRL_ISLAND_NW": "Islas Remolino",
    "LAKE_OF_RAGE": "Lago Furia",
    "ICE_PATH_1F": "Camino Helado",
    "DRAGONS_DEN_1F": "Guarida Dragón",
    "DARK_CAVE_VIOLET_ENTRANCE": "Cueva Oscura (entrada Malva)",
    "DARK_CAVE_BLACKTHORN_ENTRANCE": "Cueva Oscura (entrada Endrino)",
    "VICTORY_ROAD_GATE": "Calle Victoria",
    "MT_SILVER_OUTSIDE": "Monte Plateado",
    "SILVER_CAVE_OUTSIDE": "Cueva Plateada",
    "INDIGO_PLATEAU": "Meseta Añil",
    # Kanto ya cubierto en la tabla de Red/Blue/Yellow existente; se
    # reutilizan los mismos nombres para consistencia si aparecen aquí.
    "PEWTER_CITY": "Ciudad Plateada",
    "VIRIDIAN_CITY": "Ciudad Verde",
    "PALLET_TOWN": "Pueblo Paleta",
    "CINNABAR_ISLAND": "Isla Canela",
    "FUCHSIA_CITY": "Ciudad Fucsia",
    "CELADON_CITY": "Ciudad Azulona",
    "LAVENDER_TOWN": "Pueblo Lavanda",
    "VERMILION_CITY": "Ciudad Carmín",
    "SAFFRON_CITY": "Ciudad Azafrán",
    "CERULEAN_CITY": "Ciudad Celeste",
}


def infer_kind(symbol: str) -> str:
    """Clasifica el tipo de ubicación a partir del propio nombre simbólico.

    Esto es una heurística de PRESENTACIÓN (ciudad/ruta/etc.) y no afecta
    en nada a la corrección del ID numérico, que viene siempre de
    map_constants.txt.
    """
    if symbol.startswith("ROUTE_"):
        return "route"
    if symbol.endswith("_CITY") or symbol.endswith("_TOWN"):
        return "city"
    if "PLATEAU" in symbol or "VICTORY_ROAD" in symbol or "LEAGUE" in symbol:
        return "league"
    if "GYM" in symbol:
        return "gym"
    return "other"


def fallback_name(symbol: str) -> str:
    words = symbol.replace("_", " ").title()
    return f"{words} (sin traducir)"


def load_symbol_catalog(path: Path) -> list[str]:
    symbols = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        symbols.append(line)
    return symbols


def load_pret_map_constants_asm(path: Path) -> dict[str, int]:
    """Parsea el archivo REAL de pret (constants/map_constants.asm), tal cual
    se ve en el repositorio: bloques `newgroup NOMBRE ... ; N` seguidos de
    varias líneas `map_const NOMBRE, ancho, alto ; M`.

    El número de grupo y de mapa se toman de los comentarios `; N` / `; M`
    que el propio archivo trae — son los valores reales que asignan las
    macros const_def/const_skip de pokecrystal, no una inferencia.
    """
    ids: dict[str, int] = {}
    group_re = re.compile(r"^\s*newgroup\s+\w+.*;\s*(\d+)\s*$")
    map_re = re.compile(
        r"^\s*map_const\s+([A-Za-z0-9_]+)\s*,.*;\s*(\d+)\s*$"
    )
    current_group: int | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        g = group_re.match(raw_line)
        if g:
            current_group = int(g.group(1))
            continue
        m = map_re.match(raw_line)
        if m and current_group is not None:
            symbol, map_num = m.group(1), int(m.group(2))
            ids[symbol] = (current_group << 8) | map_num
    return ids


def load_known_ids(path: Path) -> dict[str, int]:
    ids: dict[str, int] = {}
    pattern = re.compile(r"^([A-Z0-9_]+)\s*=\s*(\d+):(0x[0-9A-Fa-f]+|\d+)$")
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        m = pattern.match(line)
        if not m:
            print(f"  [aviso] línea no reconocida, se ignora: {raw_line!r}")
            continue
        symbol, group, mapid = m.groups()
        group_n = int(group)
        mapid_n = int(mapid, 16) if mapid.startswith("0x") else int(mapid)
        ids[symbol] = (group_n << 8) | mapid_n
    return ids


from dataclasses import dataclass


@dataclass(frozen=True)
class GameSource:
    """Una entrada por juego: de dónde vienen sus nombres/IDs y a dónde
    escribir su tabla generada. Agregar un juego nuevo (pokered, pokeyellow,
    pokeemerald...) es agregar una entrada aquí + sus archivos en sources/
    — no requiere tocar el resto del script.
    """
    key: str                 # p.ej. "crystal"
    dart_var: str            # nombre de la variable Dart generada
    out_relpath: tuple[str, ...]  # ruta bajo lib/ como tupla de partes
    names_file: str | None = None          # catálogo manual (símbolos, sin ID)
    ids_file: str | None = None            # IDs manuales confirmados (SYMBOLO = group:id)
    constants_asm_file: str | None = None  # archivo REAL de pret (newgroup/map_const)
    # ^ si constants_asm_file existe, es la fuente autoritativa: da nombres
    #   e IDs juntos y tiene prioridad sobre names_file/ids_file para esos
    #   símbolos. names_file/ids_file quedan como complemento manual para
    #   símbolos que ese archivo no cubra (o para juegos que aún no tengan
    #   su .asm real disponible).


GAMES: list[GameSource] = [
    GameSource(
        key="crystal",
        dart_var="generatedCrystalLocations",
        out_relpath=("features", "pokemon", "decoder", "locations", "gen2", "crystal_locations.g.dart"),
        names_file="pokecrystal_map_names.txt",
        ids_file="map_constants.txt",
        constants_asm_file="pokecrystal_map_constants.asm",
    ),
    # Cuando existan sources/pokegold_map_constants.asm (o su names/ids manual):
    # GameSource(
    #     key="gold",
    #     dart_var="generatedGoldLocations",
    #     out_relpath=("features", "pokemon", "decoder", "locations", "gen2", "gold_locations.g.dart"),
    #     constants_asm_file="pokegold_map_constants.asm",
    # ),
    # Igual para silver, y para pokered/pokeyellow (gen1) apuntando a
    # locations/gen1/*.g.dart.
]

def generate_for_game(game: GameSource) -> None:
    LIB_ROOT = ROOT.parent.parent / "lib"

    # 1) Fuente autoritativa: el .asm real de pret, si está disponible.
    #    Da nombres + IDs juntos para todos sus símbolos.
    asm_ids: dict[str, int] = {}
    if game.constants_asm_file:
        asm_path = SOURCES / game.constants_asm_file
        if asm_path.exists():
            asm_ids = load_pret_map_constants_asm(asm_path)

    # 2) Complemento manual: catálogo de nombres sin ID + IDs confirmados
    #    sueltos (para símbolos que el .asm real no cubra, o mientras no
    #    exista el .asm real de un juego todavía).
    manual_catalog: list[str] = []
    if game.names_file:
        names_path = SOURCES / game.names_file
        if names_path.exists():
            manual_catalog = load_symbol_catalog(names_path)
    manual_ids: dict[str, int] = {}
    if game.ids_file:
        ids_path = SOURCES / game.ids_file
        if ids_path.exists():
            manual_ids = load_known_ids(ids_path)

    if not asm_ids and not manual_catalog:
        print(f"[{game.key}] omitido: no hay fuentes disponibles todavía")
        return

    # Catálogo completo de símbolos = todos los del .asm real + los del
    # catálogo manual que no estén ya cubiertos por el .asm real.
    all_symbols = list(dict.fromkeys(list(asm_ids.keys()) + manual_catalog))

    # IDs conocidos: el .asm real manda; el manual solo rellena huecos.
    known_ids: dict[str, int] = {**manual_ids, **asm_ids}

    resolved: list[tuple[int, str, str]] = []  # (key, spanish_name, kind)
    pending: list[str] = []

    for symbol in all_symbols:
        kind = infer_kind(symbol)
        name = SPANISH_NAMES.get(symbol, fallback_name(symbol))
        if symbol in known_ids:
            resolved.append((known_ids[symbol], name, kind))
        else:
            pending.append(symbol)

    out_file = LIB_ROOT.joinpath(*game.out_relpath)
    out_file.parent.mkdir(parents=True, exist_ok=True)

    depth = len(game.out_relpath) - 1  # carpetas en la ruta, sin el archivo
    levels_under_pokemon = depth - 2   # features/pokemon/ es el punto de referencia
    relative_prefix = "../" * levels_under_pokemon

    lines = [
        "// GENERADO AUTOMÁTICAMENTE por tools/pokemon_locations/generate_locations.py",
        "// No editar a mano: los cambios se pierden al regenerar.",
        f"// Fuente de nombres: sources/{game.names_file} (catálogo pret)",
        f"// Fuente de IDs:     sources/{game.ids_file} (solo IDs confirmados)",
        "",
        f"import '{relative_prefix}models/pokemon_location.dart';",
        "",
        f"const Map<int, PokemonLocation> {game.dart_var} = <int, PokemonLocation>{{",
    ]
    for key, name, kind in sorted(resolved):
        lines.append(f"  0x{key:04X}: PokemonLocation('{name}', PokemonLocationKind.{kind}),")
    lines.append("};")
    out_file.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"[{game.key}] catálogo: {len(all_symbols)}  confirmados: {len(resolved)}  "
          f"pendientes: {len(pending)}  -> {out_file.relative_to(ROOT.parent.parent)}")
    if pending:
        print(f"  pendientes de {game.ids_file}:")
        for symbol in pending:
            print(f"    - {symbol}")


def main() -> None:
    for game in GAMES:
        generate_for_game(game)


if __name__ == "__main__":
    main()
