# 🎮 RetroHub

> **RetroHub no busca emular juegos. Busca preservar la historia de cada partida.**

RetroHub es una aplicación desarrollada en Flutter cuyo objetivo es combinar la emulación de consolas retro con un sistema de seguimiento del progreso del jugador.

A diferencia de un emulador tradicional, RetroHub registra automáticamente la aventura del usuario mediante una bitácora dinámica que almacena información relevante de cada partida.

---

## Características actuales

### Biblioteca de juegos
- Importación de ROMs.
- Organización automática por consola.
- Carátulas de los juegos.
- Biblioteca persistente.

### Emulación
- Soporte para Game Boy.
- Soporte para Game Boy Color.
- Integración mediante Libretro.

### Bitácora
- Registro automático del progreso.
- Lectura de memoria del juego.
- Historial de eventos.
- Capturas del estado de la partida.

### Pokémon (GB/GBC)

Actualmente se detectan automáticamente:

- Nombre del jugador
- Dinero
- Tiempo de juego
- Medallas
- Pokédex
- Equipo Pokémon
- Ubicación
- Último guardado

---

## Tecnologías

- Flutter
- Dart
- Drift (SQLite)
- Libretro
- SameBoy Core
- FFI (C++)

---

## Plataformas

- Android
- Windows

---

## Estado del proyecto

Versión actual:

**v0.1.0**

Funcionalidades implementadas:

- Biblioteca
- Importación de ROMs
- Emulación GB/GBC
- Controles virtuales
- Bitácora
- Lectura de memoria Pokémon
- Historial
- Organización automática de ROMs

---

## Próximos objetivos

- Soporte Game Boy Advance
- Save States
- Capturas automáticas
- Estadísticas de juego
- Sistema de logros
- Marcos personalizables
- Sincronización en la nube

---

## Filosofía

RetroHub busca transformar una partida en una historia.

Cada medalla, cada Pokémon capturado y cada aventura forman parte de una bitácora que permanece incluso después de apagar la consola.

---

Desarrollado con ❤️ usando Flutter.
