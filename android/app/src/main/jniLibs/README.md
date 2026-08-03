# Cores libretro para Android

Ejecuta `prepare_android_cores.ps1` desde la raíz del proyecto antes de compilar el APK. El script descarga:

- SameBoy para juegos GB y GBC.
- mGBA para juegos GBA.
- `arm64-v8a` para teléfonos Android actuales.
- `x86_64` para el emulador de Android Studio.

Los archivos finales deben quedar como:

```text
android/app/src/main/jniLibs/arm64-v8a/libsameboy_libretro.so
android/app/src/main/jniLibs/arm64-v8a/libmgba_libretro.so
android/app/src/main/jniLibs/x86_64/libsameboy_libretro.so
android/app/src/main/jniLibs/x86_64/libmgba_libretro.so
```

Para preparar mGBA en Windows, ejecuta `prepare_windows_gba_core.ps1`. El archivo quedará en:

```text
cores/mgba/mgba_libretro.dll
```
