# Cores libretro para Android

Ejecuta `prepare_android_cores.ps1` desde la raíz del proyecto antes de compilar el APK. El script descarga:

- SameBoy para juegos GB y GBC.
- mGBA para juegos GBA.
- Supafaust para juegos SNES (`.smc` y `.sfc`).
- melonDS DS para juegos Nintendo DS (`.nds`).
- `arm64-v8a` para teléfonos Android actuales.
- `x86_64` para el emulador de Android Studio.

Los archivos finales deben quedar como:

```text
android/app/src/main/jniLibs/arm64-v8a/libsameboy_libretro.so
android/app/src/main/jniLibs/arm64-v8a/libmgba_libretro.so
android/app/src/main/jniLibs/arm64-v8a/libsnes9x_libretro.so
android/app/src/main/jniLibs/arm64-v8a/libmelondsds_libretro.so
android/app/src/main/jniLibs/x86_64/libsameboy_libretro.so
android/app/src/main/jniLibs/x86_64/libmgba_libretro.so
android/app/src/main/jniLibs/x86_64/libsnes9x_libretro.so
android/app/src/main/jniLibs/x86_64/libmelondsds_libretro.so
```

Para preparar mGBA en Windows, ejecuta `prepare_windows_gba_core.ps1`. El archivo quedará en:

```text
cores/mgba/mgba_libretro.dll
```

En Windows se usa Snes9x y el core se incluye en:

```text
cores/snes9x/snes9x_libretro.dll
```

Para preparar melonDS DS en Windows, ejecuta
`prepare_windows_nds_core.ps1`. El archivo quedará en:

```text
cores/melondsds/melondsds_libretro.dll
```

Los archivos BIOS/firmware opcionales o requeridos por una configuración
concreta de melonDS DS deben ser volcados por el usuario desde su propia
consola. RetroHub nunca los incluye en la aplicación.
