# Generador de ubicaciones Pokémon (RetroHub)

Herramienta de desarrollo (no forma parte de la app) para generar las tablas
`Map<int, PokemonLocation>` a partir de las descompilaciones públicas de pret,
en vez de escribirlas a mano.

## Cómo funciona

```
sources/pokecrystal_map_names.txt   (nombres de mapa verificados, sin ID)
                +
sources/map_constants.txt           (IDs group:id verificados, uno por línea)
                ↓
        generate_locations.py
                ↓
lib/features/pokemon/decoder/locations/gen2/crystal_locations.g.dart
```

Regla de oro: **un mapa solo aparece en el Dart de salida si tiene un ID
confirmado en `map_constants.txt`**. Si no lo tiene, el script lo reporta
como pendiente y no lo escribe. Nunca se inventa un número.

## Estado actual (al generar este archivo)

- Catálogo de nombres: 85 símbolos de Johto + Kanto (de pokecrystal).
- IDs confirmados: 1 (`RUINS_OF_ALPH_OUTSIDE`, verificado por una fuente
  independiente — pokemontools — no por `map_constants.asm` directamente).
- Pendientes: 84.

**El archivo generado (`crystal_locations.g.dart`) todavía NO está conectado
a `pokemon_decoder.dart`.** Ahora mismo tiene menos cobertura (1 entrada) que
la tabla escrita a mano que ya usa la app (~20 entradas), así que conectarlo
hoy sería un retroceso. Se conecta cuando `map_constants.txt` tenga
suficientes IDs confirmados para igualar o superar la tabla manual actual.

## Cómo ampliar la cobertura

1. Consigue el contenido real de `constants/map_constants.asm` de
   [pokecrystal](https://github.com/pret/pokecrystal) (o el equivalente de
   `pokered`/`pokeyellow` para Kanto Gen I — ver más abajo).
2. Añade líneas a `sources/map_constants.txt` con el formato:
   ```
   NOMBRE_SIMBOLICO = group:id
   ```
   Ejemplo: `VIOLET_CITY = 5:0x03`
3. Vuelve a correr:
   ```
   python3 tools/pokemon_locations/generate_locations.py
   ```
4. El script te dice cuántos símbolos quedaron resueltos y cuáles siguen
   pendientes.

## Extender a otras generaciones (Gen I, Gen III...)

El script ya está preparado para varios juegos a la vez mediante una lista
`GAMES` (una entrada por juego) — agregar `pokered`, `pokeyellow` o, más
adelante, `pokeemerald` NO requiere tocar la arquitectura del script:

1. Crear `sources/pokered_map_names.txt` (catálogo de nombres, mismo
   formato que el de Crystal).
2. Crear `sources/pokered_map_constants.txt` (IDs confirmados).
3. Agregar una entrada nueva a la lista `GAMES` en `generate_locations.py`
   (hay un ejemplo comentado ahí mismo con Gold/Silver) apuntando a
   `locations/gen1/red_locations.g.dart`.
4. Correr `python3 generate_locations.py` — genera todos los juegos
   configurados en una sola pasada, cada uno con su propio reporte de
   confirmados/pendientes.

No hace falta rediseñar nada del motor de la bitácora ni de
`PokemonDecoder`: el modelo `PokemonLocation(name, kind)` no cambia, solo
cambia de dónde vienen los datos.

## Traducción de nombres (SPANISH_NAMES)

El diccionario `SPANISH_NAMES` dentro de `generate_locations.py` es una capa
separada de los IDs: traduce los símbolos en inglés a los nombres oficiales
en español de Pokémon Oro/Plata/Cristal. Si un símbolo no está en el
diccionario, se usa un nombre de respaldo derivado del inglés y marcado
`(sin traducir)` — nunca se inventa una traducción para un lugar que no se
reconoce con confianza.
