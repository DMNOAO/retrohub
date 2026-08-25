import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// ============================================================
// Tipos nativos y Dart
// ============================================================

typedef _RhLoadCoreNative = Int32 Function(Pointer<Utf8>);
typedef _RhLoadCoreDart = int Function(Pointer<Utf8>);

typedef _RhSetDirectoryNative = Void Function(Pointer<Utf8>);
typedef _RhSetDirectoryDart = void Function(Pointer<Utf8>);

typedef _RhApiVersionNative = Int32 Function();
typedef _RhApiVersionDart = int Function();

typedef _RhCoreTextNative = Pointer<Utf8> Function();
typedef _RhCoreTextDart = Pointer<Utf8> Function();

typedef _RhLoadGameNative = Int32 Function(Pointer<Utf8>);
typedef _RhLoadGameDart = int Function(Pointer<Utf8>);

typedef _RhRunOnceNative = Int32 Function();
typedef _RhRunOnceDart = int Function();

typedef _RhGetFrameBufferNative = Pointer<Uint8> Function();
typedef _RhGetFrameBufferDart = Pointer<Uint8> Function();

typedef _RhGetFrameDimensionNative = Int32 Function();
typedef _RhGetFrameDimensionDart = int Function();

typedef _RhIsFrameReadyNative = Int32 Function();
typedef _RhIsFrameReadyDart = int Function();

typedef _RhVoidNative = Void Function();
typedef _RhVoidDart = void Function();

typedef _RhSetButtonStateNative = Void Function(Int32, Int32);
typedef _RhSetButtonStateDart = void Function(int, int);
typedef _RhSetTouchStateNative = Void Function(Int32, Int32, Int32);
typedef _RhSetTouchStateDart = void Function(int, int, int);

typedef _RhGetButtonStateNative = Int32 Function(Int32);
typedef _RhGetButtonStateDart = int Function(int);

typedef _RhFileOperationNative = Int32 Function(Pointer<Utf8>);
typedef _RhFileOperationDart = int Function(Pointer<Utf8>);

typedef _RhGetMemoryRegionSizeNative = Size Function(Uint32);
typedef _RhGetMemoryRegionSizeDart = int Function(int);

typedef _RhGetMemoryRegionPointerNative = UintPtr Function(Uint32);
typedef _RhGetMemoryRegionPointerDart = int Function(int);

typedef _RhIsMemoryRegionMappedNative = Int32 Function(Uint32);
typedef _RhIsMemoryRegionMappedDart = int Function(int);

typedef _RhReadMemoryByteNative = Int32 Function(Uint32, Size);
typedef _RhReadMemoryByteDart = int Function(int, int);

typedef _RhReadMemoryBlockNative = Size Function(
  Uint32,
  Size,
  Pointer<Uint8>,
  Size,
);
typedef _RhReadMemoryBlockDart = int Function(
  int,
  int,
  Pointer<Uint8>,
  int,
);

typedef _RhIsMemoryAddressMappedNative = Int32 Function(Uint64);
typedef _RhIsMemoryAddressMappedDart = int Function(int);

typedef _RhReadMemoryAddressNative = Size Function(
  Uint64,
  Pointer<Uint8>,
  Size,
);
typedef _RhReadMemoryAddressDart = int Function(
  int,
  Pointer<Uint8>,
  int,
);

typedef _RhGetAudioSampleRateNative = Int32 Function();
typedef _RhGetAudioSampleRateDart = int Function();
typedef _RhReadAudioSamplesNative = Size Function(Pointer<Int16>, Size);
typedef _RhReadAudioSamplesDart = int Function(Pointer<Int16>, int);

// Cable Link (rh_link_*): rh_link_supported/enable/connected
// comparten la misma forma que _RhApiVersionNative/Dart
// (Int32 Function()) y rh_link_disable la de _RhVoidNative/Dart —
// se reutilizan esos typedefs. Solo hacen falta dos nuevos, para
// enviar/recibir bytes.
typedef _RhLinkTransferNative = Int32 Function(Pointer<Uint8>, Size);
typedef _RhLinkTransferDart = int Function(Pointer<Uint8>, int);


abstract final class LibretroMemoryRegion {
  static const int saveRam = 0;
  static const int rtc = 1;
  static const int systemRam = 2;
  static const int videoRam = 3;
}

class LibretroMemoryRegionDiagnostics {
  final int memoryId;
  final bool mapped;
  final int pointer;
  final int size;

  const LibretroMemoryRegionDiagnostics({
    required this.memoryId,
    required this.mapped,
    required this.pointer,
    required this.size,
  });
}

// ============================================================
// IDs oficiales de RETRO_DEVICE_ID_JOYPAD_*
// ============================================================

abstract final class LibretroButton {
  static const int b = 0;
  static const int y = 1;
  static const int select = 2;
  static const int start = 3;
  static const int up = 4;
  static const int down = 5;
  static const int left = 6;
  static const int right = 7;
  static const int a = 8;
  static const int x = 9;
  static const int l = 10;
  static const int r = 11;
  static const int l2 = 12;
  static const int r2 = 13;
  static const int l3 = 14;
  static const int r3 = 15;

  static const int minId = b;
  static const int maxId = r3;
}

// ============================================================
// Frame generado por Libretro
// ============================================================

class LibretroFrame {
  final int width;
  final int height;
  final Uint8List rgbaBytes;

  const LibretroFrame({
    required this.width,
    required this.height,
    required this.rgbaBytes,
  });

  int get byteLength => rgbaBytes.length;

  double get aspectRatio {
    if (height == 0) {
      return 1;
    }

    return width / height;
  }
}

// ============================================================
// Puente Dart ↔ C++ ↔ Libretro
// ============================================================

class LibretroBridge {
  late final DynamicLibrary _lib;

  late final _RhLoadCoreDart _loadCore;
  late final _RhSetDirectoryDart _setSaveDirectory;
  late final _RhSetDirectoryDart _setSystemDirectory;
  late final _RhApiVersionDart _apiVersion;

  late final _RhCoreTextDart _coreName;
  late final _RhCoreTextDart _coreVersion;
  late final _RhCoreTextDart _coreExtensions;

  late final _RhLoadGameDart _loadGame;
  late final _RhRunOnceDart _runOnce;

  late final _RhGetFrameBufferDart _getFrameBuffer;
  late final _RhGetFrameDimensionDart _getFrameWidth;
  late final _RhGetFrameDimensionDart _getFrameHeight;
  late final _RhIsFrameReadyDart _isFrameReady;

  late final _RhVoidDart _markFrameConsumed;
  late final _RhVoidDart _unloadGame;
  late final _RhVoidDart _unload;

  late final _RhSetButtonStateDart _setButtonState;
  _RhSetTouchStateDart? _setTouchState;
  late final _RhGetButtonStateDart _getButtonState;
  late final _RhVoidDart _resetInput;

  late final _RhFileOperationDart _saveSram;
  late final _RhFileOperationDart _loadSram;
  late final _RhFileOperationDart _saveState;
  late final _RhFileOperationDart _loadState;

  // RTC: puede no existir en bridges compilados antes de esta
  // versión, por eso se enlaza de forma tolerante (igual que las
  // funciones de memoria opcionales de más abajo).
  _RhFileOperationDart? _saveRtc;
  _RhFileOperationDart? _loadRtc;
  _RhApiVersionDart? _coreHasRtc;

  late final _RhGetMemoryRegionSizeDart _getMemoryRegionSize;
  _RhGetMemoryRegionPointerDart? _getMemoryRegionPointer;
  _RhIsMemoryRegionMappedDart? _isMemoryRegionMapped;
  late final _RhReadMemoryByteDart _readMemoryByte;
  late final _RhReadMemoryBlockDart _readMemoryBlock;
  _RhIsMemoryAddressMappedDart? _isMemoryAddressMapped;
  _RhReadMemoryAddressDart? _readMemoryAddress;
  late final _RhGetAudioSampleRateDart _getAudioSampleRate;
  late final _RhReadAudioSamplesDart _readAudioSamples;
  late final _RhVoidDart _clearAudio;

  // Cable Link (rh_link_*): puede no existir si el bridge nativo es
  // una versión anterior a este PR, o si el core cargado no es el
  // fork RetroHub de SameBoy con soporte Link. En ambos casos se
  // enlaza de forma tolerante, igual que RTC más arriba.
  _RhApiVersionDart? _linkSupported;
  _RhApiVersionDart? _linkEnable;
  _RhVoidDart? _linkDisable;
  _RhApiVersionDart? _linkConnected;
  _RhLinkTransferDart? _linkSend;
  _RhLinkTransferDart? _linkReceive;

  bool _coreLoaded = false;
  bool _gameLoaded = false;
  bool _disposed = false;

  LibretroBridge() {
    _lib = _openLibrary();
    _bindFunctions();
  }

  // ============================================================
  // Carga de DLL y enlace de funciones
  // ============================================================

  DynamicLibrary _openLibrary() {
      if (Platform.isAndroid) {
        return DynamicLibrary.open('libretro_bridge.so');
      }

      if (!Platform.isWindows) {
        return DynamicLibrary.process();
      }

    final candidates = <String>[
      'libretro_bridge.dll',
      '${Directory.current.path}/libretro_bridge.dll',
      '${Directory.current.path}/build/windows/x64/runner/Debug/'
          'libretro_bridge.dll',
      '${Directory.current.path}/build/windows/x64/runner/Release/'
          'libretro_bridge.dll',
      'C:/Users/dark_/OneDrive/Escritorio/retrohub/'
          'build/windows/x64/runner/Debug/libretro_bridge.dll',
      'C:/Users/dark_/OneDrive/Escritorio/retrohub/'
          'build/windows/x64/runner/Release/libretro_bridge.dll',
    ];

    Object? lastError;

    for (final candidate in candidates) {
      try {
        if (candidate != 'libretro_bridge.dll') {
          final file = File(candidate);

          if (!file.existsSync()) {
            continue;
          }
        }

        return DynamicLibrary.open(candidate);
      } on Object catch (error) {
        lastError = error;
      }
    }

    throw StateError(
      'No se pudo abrir libretro_bridge.dll.\n'
      'Rutas revisadas:\n${candidates.join('\n')}\n'
      'Último error: $lastError',
    );
  }

  void _bindFunctions() {
    _loadCore = _lib.lookupFunction<
        _RhLoadCoreNative,
        _RhLoadCoreDart>('rh_load_core');

    _setSaveDirectory = _lib.lookupFunction<
        _RhSetDirectoryNative,
        _RhSetDirectoryDart>('rh_set_save_directory');

    _setSystemDirectory = _lib.lookupFunction<
        _RhSetDirectoryNative,
        _RhSetDirectoryDart>('rh_set_system_directory');

    _apiVersion = _lib.lookupFunction<
        _RhApiVersionNative,
        _RhApiVersionDart>('rh_api_version');

    _coreName = _lib.lookupFunction<
        _RhCoreTextNative,
        _RhCoreTextDart>('rh_core_name');

    _coreVersion = _lib.lookupFunction<
        _RhCoreTextNative,
        _RhCoreTextDart>('rh_core_version');

    _coreExtensions = _lib.lookupFunction<
        _RhCoreTextNative,
        _RhCoreTextDart>('rh_core_extensions');

    _loadGame = _lib.lookupFunction<
        _RhLoadGameNative,
        _RhLoadGameDart>('rh_load_game');

    _runOnce = _lib.lookupFunction<
        _RhRunOnceNative,
        _RhRunOnceDart>('rh_run_once');

    _getFrameBuffer = _lib.lookupFunction<
        _RhGetFrameBufferNative,
        _RhGetFrameBufferDart>('rh_get_frame_buffer');

    _getFrameWidth = _lib.lookupFunction<
        _RhGetFrameDimensionNative,
        _RhGetFrameDimensionDart>('rh_get_frame_width');

    _getFrameHeight = _lib.lookupFunction<
        _RhGetFrameDimensionNative,
        _RhGetFrameDimensionDart>('rh_get_frame_height');

    _isFrameReady = _lib.lookupFunction<
        _RhIsFrameReadyNative,
        _RhIsFrameReadyDart>('rh_is_frame_ready');

    _markFrameConsumed = _lib.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_mark_frame_consumed');

    _getAudioSampleRate = _lib.lookupFunction<
        _RhGetAudioSampleRateNative,
        _RhGetAudioSampleRateDart>('rh_get_audio_sample_rate');
    _readAudioSamples = _lib.lookupFunction<
        _RhReadAudioSamplesNative,
        _RhReadAudioSamplesDart>('rh_read_audio_samples');
    _clearAudio = _lib.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_clear_audio');

    _unloadGame = _lib.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_unload_game');

    _unload = _lib.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_unload');

    _setButtonState = _lib.lookupFunction<
        _RhSetButtonStateNative,
        _RhSetButtonStateDart>('rh_set_button_state');

    try {
      _setTouchState = _lib.lookupFunction<
          _RhSetTouchStateNative,
          _RhSetTouchStateDart>('rh_set_touch_state');
    } on ArgumentError {
      _setTouchState = null;
      print('Touch bridge no disponible (rh_set_touch_state)');
    }

    _getButtonState = _lib.lookupFunction<
        _RhGetButtonStateNative,
        _RhGetButtonStateDart>('rh_get_button_state');

    _resetInput = _lib.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_reset_input');

    _saveSram = _lib.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_save_sram');

    _loadSram = _lib.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_load_sram');

    _saveState = _lib.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_save_state');

    _loadState = _lib.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_load_state');

    try {
      _saveRtc = _lib.lookupFunction<
          _RhFileOperationNative,
          _RhFileOperationDart>('rh_save_rtc');
    } on ArgumentError {
      _saveRtc = null;
      print('RTC bridge no disponible (rh_save_rtc)');
    }

    try {
      _loadRtc = _lib.lookupFunction<
          _RhFileOperationNative,
          _RhFileOperationDart>('rh_load_rtc');
    } on ArgumentError {
      _loadRtc = null;
      print('RTC bridge no disponible (rh_load_rtc)');
    }

    try {
      _coreHasRtc = _lib.lookupFunction<
          _RhApiVersionNative,
          _RhApiVersionDart>('rh_core_has_rtc');
    } on ArgumentError {
      _coreHasRtc = null;
    }

    _getMemoryRegionSize = _lib.lookupFunction<
        _RhGetMemoryRegionSizeNative,
        _RhGetMemoryRegionSizeDart>('rh_get_memory_region_size');

    _readMemoryByte = _lib.lookupFunction<
        _RhReadMemoryByteNative,
        _RhReadMemoryByteDart>('rh_read_memory_byte');

    _readMemoryBlock = _lib.lookupFunction<
        _RhReadMemoryBlockNative,
        _RhReadMemoryBlockDart>('rh_read_memory_block');

    try {
      _getMemoryRegionPointer = _lib.lookupFunction<
          _RhGetMemoryRegionPointerNative,
          _RhGetMemoryRegionPointerDart>('rh_get_memory_region_pointer');
    } on ArgumentError {
      _getMemoryRegionPointer = null;
    }

    try {
      _isMemoryRegionMapped = _lib.lookupFunction<
          _RhIsMemoryRegionMappedNative,
          _RhIsMemoryRegionMappedDart>('rh_is_memory_region_mapped');
    } on ArgumentError {
      _isMemoryRegionMapped = null;
    }

    try {
      _isMemoryAddressMapped = _lib.lookupFunction<
          _RhIsMemoryAddressMappedNative,
          _RhIsMemoryAddressMappedDart>('rh_is_memory_address_mapped');
    } on ArgumentError {
      _isMemoryAddressMapped = null;
    }

    try {
      _readMemoryAddress = _lib.lookupFunction<
          _RhReadMemoryAddressNative,
          _RhReadMemoryAddressDart>('rh_read_memory_address');
    } on ArgumentError {
      _readMemoryAddress = null;
    }
    try {
      _linkSupported = _lib.lookupFunction<
          _RhApiVersionNative,
          _RhApiVersionDart>('rh_link_supported');
    } on ArgumentError {
      _linkSupported = null;
    }

    try {
      _linkEnable = _lib.lookupFunction<
          _RhApiVersionNative,
          _RhApiVersionDart>('rh_link_enable');
    } on ArgumentError {
      _linkEnable = null;
    }

    try {
      _linkDisable = _lib.lookupFunction<
          _RhVoidNative,
          _RhVoidDart>('rh_link_disable');
    } on ArgumentError {
      _linkDisable = null;
    }

    try {
      _linkConnected = _lib.lookupFunction<
          _RhApiVersionNative,
          _RhApiVersionDart>('rh_link_connected');
    } on ArgumentError {
      _linkConnected = null;
    }

    try {
      _linkSend = _lib.lookupFunction<
          _RhLinkTransferNative,
          _RhLinkTransferDart>('rh_link_send');
    } on ArgumentError {
      _linkSend = null;
    }

    try {
      _linkReceive = _lib.lookupFunction<
          _RhLinkTransferNative,
          _RhLinkTransferDart>('rh_link_receive');
    } on ArgumentError {
      _linkReceive = null;
    }
  }

  // ============================================================
  // Estado
  // ============================================================

  bool get isCoreLoaded => _coreLoaded;

  bool get isGameLoaded => _gameLoaded;

  bool get isDisposed => _disposed;

  // ============================================================
  // Core
  // ============================================================

  bool loadCore(String corePath) {
    _ensureNotDisposed();

    final normalizedPath = corePath.trim();

    if (normalizedPath.isEmpty) {
      return false;
    }

    if (_coreLoaded) {
      return true;
    }

    final Pointer<Utf8> pathPointer = normalizedPath.toNativeUtf8();

    try {
      final int result = _loadCore(pathPointer);

      _coreLoaded = result == 1;

      return _coreLoaded;
    } finally {
      malloc.free(pathPointer);
    }
  }

  void setSaveDirectory(String path) {
    _ensureNotDisposed();

    final normalizedPath = path.trim();

    if (normalizedPath.isEmpty) {
      return;
    }

    final Pointer<Utf8> pathPointer = normalizedPath.toNativeUtf8();

    try {
      _setSaveDirectory(pathPointer);
    } finally {
      malloc.free(pathPointer);
    }
  }

  void setSystemDirectory(String path) {
    _ensureNotDisposed();

    final normalizedPath = path.trim();

    if (normalizedPath.isEmpty) {
      return;
    }

    final Pointer<Utf8> pathPointer = normalizedPath.toNativeUtf8();

    try {
      _setSystemDirectory(pathPointer);
    } finally {
      malloc.free(pathPointer);
    }
  }

  int apiVersion() {
    _ensureNotDisposed();

    if (!_coreLoaded) {
      return -1;
    }

    return _apiVersion();
  }

  String coreName() {
    _ensureNotDisposed();

    if (!_coreLoaded) {
      return 'Core no cargado';
    }

    return _readNativeString(_coreName());
  }

  String coreVersion() {
    _ensureNotDisposed();

    if (!_coreLoaded) {
      return 'Sin versión';
    }

    return _readNativeString(_coreVersion());
  }

  String coreExtensions() {
    _ensureNotDisposed();

    if (!_coreLoaded) {
      return '';
    }

    return _readNativeString(_coreExtensions());
  }

  // ============================================================
  // Juego
  // ============================================================

  bool loadGame(String romPath) {
    _ensureNotDisposed();

    final normalizedPath = romPath.trim();

    if (!_coreLoaded || normalizedPath.isEmpty) {
      return false;
    }

    if (_gameLoaded) {
      return true;
    }

    final Pointer<Utf8> pathPointer = normalizedPath.toNativeUtf8();

    try {
      final int result = _loadGame(pathPointer);

      _gameLoaded = result == 1;

      if (_gameLoaded) {
        resetInput();
      }

      return _gameLoaded;
    } finally {
      malloc.free(pathPointer);
    }
  }

  bool runOnce() {
    _ensureNotDisposed();

    if (!_coreLoaded || !_gameLoaded) {
      return false;
    }

    return _runOnce() == 1;
  }

  int get audioSampleRate {
    _ensureNotDisposed();
    return _getAudioSampleRate();
  }

  Uint8List readAudioBytes({int maxSamples = 8192}) {
    _ensureNotDisposed();
    if (!_gameLoaded || maxSamples <= 0) return Uint8List(0);
    final Pointer<Int16> buffer = malloc<Int16>(maxSamples);
    try {
      final int samplesRead = _readAudioSamples(buffer, maxSamples);
      if (samplesRead <= 0) return Uint8List(0);
      return Uint8List.fromList(
        buffer.cast<Uint8>().asTypedList(samplesRead * 2),
      );
    } finally {
      malloc.free(buffer);
    }
  }

  void clearAudio() {
    _ensureNotDisposed();
    _clearAudio();
  }

  // ============================================================
  // Video
  // ============================================================

  bool isFrameReady() {
    _ensureNotDisposed();

    if (!_gameLoaded) {
      return false;
    }

    return _isFrameReady() == 1;
  }

  int frameWidth() {
    _ensureNotDisposed();
    return _getFrameWidth();
  }

  int frameHeight() {
    _ensureNotDisposed();
    return _getFrameHeight();
  }

  LibretroFrame? readFrame() {
    _ensureNotDisposed();

    if (!_gameLoaded || !isFrameReady()) {
      return null;
    }

    final int width = _getFrameWidth();
    final int height = _getFrameHeight();

    if (width <= 0 || height <= 0) {
      _markFrameConsumed();
      return null;
    }

    final Pointer<Uint8> framePointer = _getFrameBuffer();

    if (framePointer == nullptr) {
      _markFrameConsumed();
      return null;
    }

    final int byteLength = width * height * 4;

    if (byteLength <= 0) {
      _markFrameConsumed();
      return null;
    }

    final Uint8List frameBytes = Uint8List.fromList(
      framePointer.asTypedList(byteLength),
    );

    _markFrameConsumed();

    return LibretroFrame(
      width: width,
      height: height,
      rgbaBytes: frameBytes,
    );
  }

  LibretroFrame? runAndReadFrame() {
    _ensureNotDisposed();

    if (!runOnce()) {
      return null;
    }

    return readFrame();
  }

  // ============================================================
  // Persistencia
  // ============================================================

  bool saveSram(String filePath) {
    return _runFileOperation(
      filePath: filePath,
      operation: _saveSram,
    );
  }

  bool loadSram(String filePath) {
    return _runFileOperation(
      filePath: filePath,
      operation: _loadSram,
    );
  }

  bool saveState(String filePath) {
    return _runFileOperation(
      filePath: filePath,
      operation: _saveState,
    );
  }

  bool loadState(String filePath) {
    return _runFileOperation(
      filePath: filePath,
      operation: _loadState,
    );
  }

  /// Indica si el core actualmente cargado expone RTC
  /// (RETRO_MEMORY_RTC > 0 bytes). Devuelve false tanto si el
  /// juego no tiene RTC (p.ej. Red/Blue/Yellow) como si este
  /// bridge nativo es una versión anterior sin soporte RTC.
  bool coreHasRtc() {
    _ensureNotDisposed();

    final operation = _coreHasRtc;

    if (!_coreLoaded || !_gameLoaded || operation == null) {
      return false;
    }

    return operation() == 1;
  }

  /// Guarda el RTC (reloj interno de cartuchos MBC3, usado por
  /// Pokémon Gold/Silver/Crystal) en [filePath], normalmente
  /// "<partida>.rtc" junto al "<partida>.srm".
  ///
  /// Devuelve true si se guardó correctamente O si el core no
  /// tiene RTC para este juego (no es un error). Devuelve false
  /// solo si el bridge no soporta RTC o hubo un fallo real de
  /// escritura.
  bool saveRtc(String filePath) {
    final operation = _saveRtc;

    if (operation == null) {
      print('RTC bridge no disponible: no se guardó $filePath');
      return false;
    }

    return _runFileOperation(
      filePath: filePath,
      operation: operation,
    );
  }

  /// Carga el RTC previamente guardado con [saveRtc]. Devuelve
  /// true tanto si se cargó correctamente como si el archivo aún
  /// no existe (primera partida) o el core no tiene RTC — ninguno
  /// de esos casos es un error. Devuelve false solo si el bridge
  /// no soporta RTC o el archivo existente está corrupto/con un
  /// tamaño inesperado.
  bool loadRtc(String filePath) {
    final operation = _loadRtc;

    if (operation == null) {
      print('RTC bridge no disponible: no se cargó $filePath');
      return false;
    }

    return _runFileOperation(
      filePath: filePath,
      operation: operation,
    );
  }

  // ============================================================
  // Cable Link (rh_link_*)
  //
  // Solo funciona si el core cargado es el fork RetroHub de
  // SameBoy con soporte Link (ver
  // native/sameboy_fork/RH_LINK_PATCH.md). En cualquier otro core,
  // o en un bridge nativo compilado antes de este PR, todos estos
  // métodos se degradan a "no soportado" sin lanzar excepciones.
  // ============================================================

  /// `true` si el core cargado expone la API `rh_link_*` (es decir,
  /// es el fork de SameBoy con soporte Link Cable) Y este bridge
  /// nativo fue compilado con este PR.
  bool get linkSupported {
    _ensureNotDisposed();

    final operation = _linkSupported;
    if (!_coreLoaded || operation == null) {
      return false;
    }

    return operation() == 1;
  }

  /// Activa el puente del puerto serie dentro del core. Requiere
  /// que ya haya un juego cargado y que [linkSupported] sea true.
  bool enableLink() {
    _ensureNotDisposed();

    final operation = _linkEnable;
    if (!_coreLoaded || !_gameLoaded || operation == null) {
      return false;
    }

    return operation() == 1;
  }

  /// Desactiva el puente del puerto serie. Seguro de llamar aunque
  /// nunca se haya activado.
  void disableLink() {
    _ensureNotDisposed();
    _linkDisable?.call();
  }

  /// `true` si el puente del puerto serie está activo en este
  /// momento (ver [enableLink]).
  bool get linkConnected {
    _ensureNotDisposed();

    final operation = _linkConnected;
    if (operation == null) {
      return false;
    }

    return operation() == 1;
  }

  /// Entrega [bytes] al core para que los inyecte, bit a bit, en el
  /// puerto serie emulado — normalmente bytes que acaban de llegar
  /// por Bluetooth desde el otro dispositivo. Devuelve false si el
  /// link no está soportado/activo o si la cola interna del core
  /// está llena (en ese caso, reintentar más tarde).
  bool linkSend(Uint8List bytes) {
    _ensureNotDisposed();

    final operation = _linkSend;
    if (operation == null || bytes.isEmpty) {
      return false;
    }

    final Pointer<Uint8> source = calloc<Uint8>(bytes.length);
    try {
      source.asTypedList(bytes.length).setAll(0, bytes);
      return operation(source, bytes.length) == 1;
    } finally {
      calloc.free(source);
    }
  }

  /// Extrae los bytes que el core ya armó a partir de lo que el
  /// Game Boy local mandó por el puerto serie desde la última
  /// llamada — para reenviarlos por Bluetooth al otro dispositivo.
  /// Devuelve una lista vacía si no hay nada nuevo o el link no
  /// está soportado/activo.
  Uint8List linkReceive({int maxLength = 256}) {
    _ensureNotDisposed();

    final operation = _linkReceive;
    if (operation == null || maxLength <= 0) {
      return Uint8List(0);
    }

    final Pointer<Uint8> destination = calloc<Uint8>(maxLength);
    try {
      final int bytesRead = operation(destination, maxLength);
      if (bytesRead <= 0) {
        return Uint8List(0);
      }
      return Uint8List.fromList(destination.asTypedList(bytesRead));
    } finally {
      calloc.free(destination);
    }
  }

  bool _runFileOperation({
    required String filePath,
    required _RhFileOperationDart operation,
  }) {
    _ensureNotDisposed();

    final String normalizedPath = filePath.trim();

    if (!_coreLoaded || !_gameLoaded || normalizedPath.isEmpty) {
      return false;
    }

    final Pointer<Utf8> pathPointer = normalizedPath.toNativeUtf8();

    try {
      return operation(pathPointer) == 1;
    } finally {
      malloc.free(pathPointer);
    }
  }


  // ============================================================
  // Memoria
  // ============================================================

  int memoryRegionSize(int memoryId) {
    _ensureNotDisposed();

    if (!_coreLoaded || !_gameLoaded) {
      return 0;
    }

    return _getMemoryRegionSize(memoryId);
  }

  int? readMemoryByte({
    required int memoryId,
    required int offset,
  }) {
    _ensureNotDisposed();

    if (!_coreLoaded || !_gameLoaded || offset < 0) {
      return null;
    }

    final int value = _readMemoryByte(memoryId, offset);

    return value < 0 ? null : value;
  }

  Uint8List readMemoryBlock({
    required int memoryId,
    required int offset,
    required int length,
  }) {
    _ensureNotDisposed();

    if (!_coreLoaded ||
        !_gameLoaded ||
        offset < 0 ||
        length <= 0) {
      return Uint8List(0);
    }

    final Pointer<Uint8> destination = calloc<Uint8>(length);

    try {
      final int bytesRead = _readMemoryBlock(
        memoryId,
        offset,
        destination,
        length,
      );

      if (bytesRead <= 0) {
        return Uint8List(0);
      }

      return Uint8List.fromList(
        destination.asTypedList(bytesRead),
      );
    } finally {
      calloc.free(destination);
    }
  }

  bool isMemoryAddressMapped(int address) {
    _ensureNotDisposed();
    if (!_coreLoaded || !_gameLoaded || address < 0) return false;
    final _RhIsMemoryAddressMappedDart? operation = _isMemoryAddressMapped;
    return operation != null && operation(address) == 1;
  }

  Uint8List readMemoryAddress({
    required int address,
    required int length,
  }) {
    _ensureNotDisposed();

    if (!_coreLoaded || !_gameLoaded || address < 0 || length <= 0) {
      return Uint8List(0);
    }

    final Pointer<Uint8> destination = calloc<Uint8>(length);
    try {
      final _RhReadMemoryAddressDart? operation = _readMemoryAddress;
      if (operation == null) return Uint8List(0);
      final int bytesRead = operation(
        address,
        destination,
        length,
      );
      if (bytesRead <= 0) return Uint8List(0);
      return Uint8List.fromList(destination.asTypedList(bytesRead));
    } finally {
      calloc.free(destination);
    }
  }

  Map<String, int> inspectMemoryRegions() {
    return <String, int>{
      'saveRam': memoryRegionSize(LibretroMemoryRegion.saveRam),
      'rtc': memoryRegionSize(LibretroMemoryRegion.rtc),
      'systemRam': memoryRegionSize(LibretroMemoryRegion.systemRam),
      'videoRam': memoryRegionSize(LibretroMemoryRegion.videoRam),
    };
  }

  Map<String, LibretroMemoryRegionDiagnostics>
      inspectMemoryRegionDiagnostics() {
    const Map<String, int> regions = <String, int>{
      'SAVE_RAM': LibretroMemoryRegion.saveRam,
      'RTC': LibretroMemoryRegion.rtc,
      'SYSTEM_RAM': LibretroMemoryRegion.systemRam,
      'VIDEO_RAM': LibretroMemoryRegion.videoRam,
    };
    return regions.map((String name, int memoryId) {
      return MapEntry<String, LibretroMemoryRegionDiagnostics>(
        name,
        LibretroMemoryRegionDiagnostics(
          memoryId: memoryId,
          mapped: _isMemoryRegionMapped?.call(memoryId) == 1,
          pointer: _getMemoryRegionPointer?.call(memoryId) ?? 0,
          size: memoryRegionSize(memoryId),
        ),
      );
    });
  }

  // ============================================================
  // Controles
  // ============================================================

  void setButtonState(int buttonId, bool pressed) {
    _ensureNotDisposed();

    if (!_coreLoaded || !_gameLoaded) {
      return;
    }

    if (!_isValidButtonId(buttonId)) {
      return;
    }

    _setButtonState(
      buttonId,
      pressed ? 1 : 0,
    );
  }

  void setTouchState({
    required int x,
    required int y,
    required bool pressed,
  }) {
    _ensureNotDisposed();

    if (!_coreLoaded || !_gameLoaded) {
      return;
    }

    _setTouchState?.call(
      x.clamp(0, 255).toInt(),
      y.clamp(0, 191).toInt(),
      pressed ? 1 : 0,
    );
  }

  void pressButton(int buttonId) {
    setButtonState(buttonId, true);
  }

  void releaseButton(int buttonId) {
    setButtonState(buttonId, false);
  }

  bool isButtonPressed(int buttonId) {
    _ensureNotDisposed();

    if (!_isValidButtonId(buttonId)) {
      return false;
    }

    return _getButtonState(buttonId) == 1;
  }

  void resetInput() {
    if (_disposed) {
      return;
    }

    _resetInput();
  }

  bool _isValidButtonId(int buttonId) {
    return buttonId >= LibretroButton.minId &&
        buttonId <= LibretroButton.maxId;
  }

  // ============================================================
  // Descarga y liberación
  // ============================================================

  void unloadGame() {
    if (_disposed || !_gameLoaded) {
      return;
    }

    resetInput();
    _unloadGame();

    _gameLoaded = false;
  }

  void unload() {
    if (_disposed) {
      return;
    }

    resetInput();
    _unload();

    _gameLoaded = false;
    _coreLoaded = false;
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    unload();
    _disposed = true;
  }

  // ============================================================
  // Utilidades
  // ============================================================

  String _readNativeString(Pointer<Utf8> pointer) {
    if (pointer == nullptr) {
      return '';
    }

    return pointer.toDartString();
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError(
        'LibretroBridge ya fue liberado y no puede volver a utilizarse.',
      );
    }
  }
}
