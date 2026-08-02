import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// ============================================================
// Tipos nativos y Dart
// ============================================================

typedef _RhLoadCoreNative = Int32 Function(Pointer<Utf8>);
typedef _RhLoadCoreDart = int Function(Pointer<Utf8>);

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

typedef _RhGetButtonStateNative = Int32 Function(Int32);
typedef _RhGetButtonStateDart = int Function(int);

typedef _RhFileOperationNative = Int32 Function(Pointer<Utf8>);
typedef _RhFileOperationDart = int Function(Pointer<Utf8>);

typedef _RhGetMemoryRegionSizeNative = Size Function(Uint32);
typedef _RhGetMemoryRegionSizeDart = int Function(int);

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


abstract final class LibretroMemoryRegion {
  static const int saveRam = 0;
  static const int rtc = 1;
  static const int systemRam = 2;
  static const int videoRam = 3;
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
  late final _RhGetButtonStateDart _getButtonState;
  late final _RhVoidDart _resetInput;

  late final _RhFileOperationDart _saveSram;
  late final _RhFileOperationDart _loadSram;
  late final _RhFileOperationDart _saveState;
  late final _RhFileOperationDart _loadState;

  late final _RhGetMemoryRegionSizeDart _getMemoryRegionSize;
  late final _RhReadMemoryByteDart _readMemoryByte;
  late final _RhReadMemoryBlockDart _readMemoryBlock;

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

    _unloadGame = _lib.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_unload_game');

    _unload = _lib.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_unload');

    _setButtonState = _lib.lookupFunction<
        _RhSetButtonStateNative,
        _RhSetButtonStateDart>('rh_set_button_state');

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

    _getMemoryRegionSize = _lib.lookupFunction<
        _RhGetMemoryRegionSizeNative,
        _RhGetMemoryRegionSizeDart>('rh_get_memory_region_size');

    _readMemoryByte = _lib.lookupFunction<
        _RhReadMemoryByteNative,
        _RhReadMemoryByteDart>('rh_read_memory_byte');

    _readMemoryBlock = _lib.lookupFunction<
        _RhReadMemoryBlockNative,
        _RhReadMemoryBlockDart>('rh_read_memory_block');
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

  Map<String, int> inspectMemoryRegions() {
    return <String, int>{
      'saveRam': memoryRegionSize(LibretroMemoryRegion.saveRam),
      'rtc': memoryRegionSize(LibretroMemoryRegion.rtc),
      'systemRam': memoryRegionSize(LibretroMemoryRegion.systemRam),
      'videoRam': memoryRegionSize(LibretroMemoryRegion.videoRam),
    };
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
