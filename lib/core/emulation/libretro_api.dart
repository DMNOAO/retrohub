import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'core_loader.dart';

typedef _RhLoadCoreNative = Int32 Function(Pointer<Utf8>);
typedef _RhLoadCoreDart = int Function(Pointer<Utf8>);

typedef _RhApiVersionNative = Int32 Function();
typedef _RhApiVersionDart = int Function();

typedef _RhStringNative = Pointer<Utf8> Function();
typedef _RhStringDart = Pointer<Utf8> Function();

typedef _RhLoadGameNative = Int32 Function(Pointer<Utf8>);
typedef _RhLoadGameDart = int Function(Pointer<Utf8>);

typedef _RhRunOnceNative = Int32 Function();
typedef _RhRunOnceDart = int Function();

typedef _RhGetFrameBufferNative = Pointer<Uint8> Function();
typedef _RhGetFrameBufferDart = Pointer<Uint8> Function();

typedef _RhGetIntNative = Int32 Function();
typedef _RhGetIntDart = int Function();

typedef _RhVoidNative = Void Function();
typedef _RhVoidDart = void Function();

typedef _RhSetButtonStateNative = Void Function(Int32, Int32);
typedef _RhSetButtonStateDart = void Function(int, int);

typedef _RhGetButtonStateNative = Int32 Function(Int32);
typedef _RhGetButtonStateDart = int Function(int);

typedef _RhFileOperationNative = Int32 Function(Pointer<Utf8>);
typedef _RhFileOperationDart = int Function(Pointer<Utf8>);

/// IDs oficiales de RETRO_DEVICE_ID_JOYPAD_*.
///
/// Game Boy y Game Boy Color usan principalmente:
/// B, Select, Start, direcciones y A.
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
}

class LibretroApi {
  LibretroApi._(this.library) {
    _loadCore = library.lookupFunction<
        _RhLoadCoreNative,
        _RhLoadCoreDart>('rh_load_core');

    _apiVersion = library.lookupFunction<
        _RhApiVersionNative,
        _RhApiVersionDart>('rh_api_version');

    _coreName = library.lookupFunction<
        _RhStringNative,
        _RhStringDart>('rh_core_name');

    _coreVersion = library.lookupFunction<
        _RhStringNative,
        _RhStringDart>('rh_core_version');

    _coreExtensions = library.lookupFunction<
        _RhStringNative,
        _RhStringDart>('rh_core_extensions');

    _loadGame = library.lookupFunction<
        _RhLoadGameNative,
        _RhLoadGameDart>('rh_load_game');

    _runOnce = library.lookupFunction<
        _RhRunOnceNative,
        _RhRunOnceDart>('rh_run_once');

    _getFrameBuffer = library.lookupFunction<
        _RhGetFrameBufferNative,
        _RhGetFrameBufferDart>('rh_get_frame_buffer');

    _getFrameWidth = library.lookupFunction<
        _RhGetIntNative,
        _RhGetIntDart>('rh_get_frame_width');

    _getFrameHeight = library.lookupFunction<
        _RhGetIntNative,
        _RhGetIntDart>('rh_get_frame_height');

    _isFrameReady = library.lookupFunction<
        _RhGetIntNative,
        _RhGetIntDart>('rh_is_frame_ready');

    _markFrameConsumed = library.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_mark_frame_consumed');

    _unloadGame = library.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_unload_game');

    _unload = library.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_unload');

    _setButtonState = library.lookupFunction<
        _RhSetButtonStateNative,
        _RhSetButtonStateDart>('rh_set_button_state');

    _getButtonState = library.lookupFunction<
        _RhGetButtonStateNative,
        _RhGetButtonStateDart>('rh_get_button_state');

    _resetInput = library.lookupFunction<
        _RhVoidNative,
        _RhVoidDart>('rh_reset_input');

    _saveSram = library.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_save_sram');

    _loadSram = library.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_load_sram');

    _saveState = library.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_save_state');

    _loadState = library.lookupFunction<
        _RhFileOperationNative,
        _RhFileOperationDart>('rh_load_state');
  }

  final DynamicLibrary library;

  late final _RhLoadCoreDart _loadCore;
  late final _RhApiVersionDart _apiVersion;
  late final _RhStringDart _coreName;
  late final _RhStringDart _coreVersion;
  late final _RhStringDart _coreExtensions;
  late final _RhLoadGameDart _loadGame;
  late final _RhRunOnceDart _runOnce;
  late final _RhGetFrameBufferDart _getFrameBuffer;
  late final _RhGetIntDart _getFrameWidth;
  late final _RhGetIntDart _getFrameHeight;
  late final _RhGetIntDart _isFrameReady;
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

  static LibretroApi? load() {
    final bridge = CoreLoader.loadBridge();

    if (bridge == null) {
      return null;
    }

    try {
      return LibretroApi._(bridge);
    } on Object catch (error) {
      print('No se pudieron enlazar las funciones del bridge: $error');
      return null;
    }
  }

  /// Mantiene compatibilidad con el nombre utilizado anteriormente.
  static LibretroApi? loadSameBoy() {
    final api = load();

    if (api == null) {
      return null;
    }

    if (!api.loadSameBoyCore()) {
      api.unload();
      return null;
    }

    return api;
  }

  bool loadSameBoyCore() {
    final corePath = CoreLoader.findSameBoyPath();

    if (corePath == null) {
      print(
        'No se encontró SameBoy.\n'
        '${CoreLoader.debugCoreSearchPaths}',
      );
      return false;
    }

    final nativePath = corePath.toNativeUtf8();

    try {
      return _loadCore(nativePath) == 1;
    } finally {
      malloc.free(nativePath);
    }
  }

  int get apiVersion => _apiVersion();

  String get coreName => _readNativeString(_coreName());

  String get coreVersion => _readNativeString(_coreVersion());

  String get coreExtensions => _readNativeString(_coreExtensions());

  bool loadGame(String romPath) {
    final nativePath = romPath.toNativeUtf8();

    try {
      return _loadGame(nativePath) == 1;
    } finally {
      malloc.free(nativePath);
    }
  }

  bool runOnce() {
    return _runOnce() == 1;
  }

  bool get isFrameReady => _isFrameReady() == 1;

  int get frameWidth => _getFrameWidth();

  int get frameHeight => _getFrameHeight();

  Pointer<Uint8> get frameBuffer => _getFrameBuffer();

  void markFrameConsumed() {
    _markFrameConsumed();
  }

  void setButtonState(int buttonId, bool pressed) {
    if (buttonId < 0 || buttonId > LibretroButton.r3) {
      return;
    }

    _setButtonState(buttonId, pressed ? 1 : 0);
  }

  void pressButton(int buttonId) {
    setButtonState(buttonId, true);
  }

  void releaseButton(int buttonId) {
    setButtonState(buttonId, false);
  }

  bool isButtonPressed(int buttonId) {
    return _getButtonState(buttonId) == 1;
  }

  void resetInput() {
    _resetInput();
  }

  bool saveSram(String filePath) {
    return _runFileOperation(filePath, _saveSram);
  }

  bool loadSram(String filePath) {
    return _runFileOperation(filePath, _loadSram);
  }

  bool saveState(String filePath) {
    return _runFileOperation(filePath, _saveState);
  }

  bool loadState(String filePath) {
    return _runFileOperation(filePath, _loadState);
  }

  bool _runFileOperation(
    String filePath,
    _RhFileOperationDart operation,
  ) {
    final normalizedPath = filePath.trim();

    if (normalizedPath.isEmpty) {
      return false;
    }

    final nativePath = normalizedPath.toNativeUtf8();

    try {
      return operation(nativePath) == 1;
    } finally {
      malloc.free(nativePath);
    }
  }

  void unloadGame() {
    _resetInput();
    _unloadGame();
  }

  void unload() {
    _resetInput();
    _unload();
  }

  String _readNativeString(Pointer<Utf8> pointer) {
    if (pointer == nullptr) {
      return '';
    }

    return pointer.toDartString();
  }
}
