# RetroHub Beta Android — preparación inicial

## Cambios incluidos

- Bridge C++ compatible con Windows y Android (`LoadLibrary`/`dlopen`).
- Compilación automática de `libretro_bridge.so` mediante CMake y Android NDK.
- Carga FFI por nombre de biblioteca en Android.
- SameBoy cargado como `libsameboy_libretro.so` desde `jniLibs`.
- Persistencia de SRAM, estados y capturas dentro del sandbox privado de Android.
- ABIs iniciales: `arm64-v8a` y `x86_64`.
- Paquete Beta: `com.retrohub.beta`.

## Antes de compilar

Desde PowerShell, en la raíz del proyecto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\prepare_android_cores.ps1
```

El script descarga SameBoy desde el buildbot oficial de Libretro.

## Instalar herramientas Android

En Android Studio > SDK Manager > SDK Tools instala:

- Android SDK Command-line Tools
- NDK (Side by side)
- CMake 3.22.1

Después verifica:

```powershell
flutter doctor -v
flutter devices
```

## Probar directamente en el teléfono

Activa Opciones de desarrollador y Depuración USB. Luego:

```powershell
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <ID_DEL_TELEFONO>
```

## Generar APK Beta

```powershell
flutter build apk --release --split-per-abi
```

La APK principal para teléfonos actuales será:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Limitaciones de esta entrega

- Este paquete prepara la integración nativa, pero la APK no fue compilada en este entorno porque no dispone del Flutter SDK ni del Android NDK.
- Debe probarse la importación de ROM mediante `file_picker` en un teléfono real.
- Esta primera Beta se centra en GB/GBC con SameBoy.
