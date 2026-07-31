# SameBoy para Android

Ejecuta `prepare_android_cores.ps1` desde la raíz del proyecto. El script descarga las compilaciones oficiales de SameBoy para:

- `arm64-v8a`: teléfonos Android actuales.
- `x86_64`: emulador de Android Studio.

Los archivos finales deben quedar como:

```text
android/app/src/main/jniLibs/arm64-v8a/libsameboy_libretro.so
android/app/src/main/jniLibs/x86_64/libsameboy_libretro.so
```
