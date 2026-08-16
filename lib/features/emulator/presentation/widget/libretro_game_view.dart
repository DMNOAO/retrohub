import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/emulation/core_loader.dart';
import '../../data/libretro_bridge.dart';
import '../../data/save_state_service.dart';
import '../../special_events/crystal_gs_ball_service.dart';
import '../../audio/libretro_audio_player.dart';
import '../../../game_engine/game_engine_status.dart';
import '../../../pokemon/decoder/pokemon_decoder.dart';
import '../../../pokemon/engine/pokemon_engine.dart';
import '../../../pokemon/models/pokemon_memory_snapshot.dart';
import '../../link/link_manager.dart';
import '../../link/link_state.dart';
import '../../link/link_transport_factory.dart';

class LibretroGameController {
  bool hapticsEnabled = false;
  void Function(int buttonId, bool pressed)? _setButtonState;
  VoidCallback? _resetInput;
  Future<bool> Function(int slot, String title)? _saveState;
  Future<bool> Function(int slot)? _loadState;
  Future<bool> Function()? _saveSram;
  Future<CrystalGsBallStatus> Function()? _inspectGsBall;
  Future<CrystalGsBallActivationResult> Function(bool allowBeforeLeague)?
      _activateGsBall;
  Future<void> Function()? _restart;
  void Function(bool paused)? _setPaused;
  int Function()? _currentPlayTimeMinutes;
  Map<String, int> Function()? _inspectMemoryRegions;
  Map<String, LibretroMemoryRegionDiagnostics> Function()?
  _inspectMemoryRegionDiagnostics;
  Uint8List Function(int memoryId, int offset, int length)? _readMemoryBlock;
  Uint8List Function(int address, int length)? _readMemoryAddress;
  Map<String, String> Function()? _runtimeIdentity;

  final ValueNotifier<int> _fallbackSpeedMultiplier = ValueNotifier<int>(1);
  ValueNotifier<int>? _speedMultiplierNotifier;
  VoidCallback? _cycleSpeed;

  LinkManager? _linkManager;

  bool get isAttached => _setButtonState != null;

  /// Administrador de la sesión Link (arquitectura preparada para Cable
  /// Link; todavía sin transporte real, ver [DummyLinkTransport]).
  /// `null` mientras el controlador no esté adjunto a un
  /// [LibretroGameView].
  LinkManager? get linkManager => _linkManager;

  /// Multiplicador de velocidad actual (x1, x2, x4, x8), reutilizando
  /// exactamente el mismo estado que ya maneja internamente
  /// [LibretroGameView]. Antes de que el controlador esté adjunto,
  /// devuelve un valor por defecto de 1x.
  ValueListenable<int> get speedMultiplier =>
      _speedMultiplierNotifier ?? _fallbackSpeedMultiplier;

  /// Avanza al siguiente multiplicador de velocidad (x1→x2→x4→x8→x1),
  /// reutilizando el mismo `_cycleSpeed` ya implementado en
  /// [LibretroGameView]. No introduce lógica de emulación nueva.
  void cycleSpeed() => _cycleSpeed?.call();

  void pressButton(int buttonId) {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    _setButtonState?.call(buttonId, true);
  }

  void releaseButton(int buttonId) => _setButtonState?.call(buttonId, false);

  void resetInput() => _resetInput?.call();

  Future<bool> saveState({required int slot, required String title}) async {
    return await _saveState?.call(slot, title) ?? false;
  }

  Future<bool> loadState(int slot) async {
    return await _loadState?.call(slot) ?? false;
  }

  Future<bool> saveSram() async {
    return await _saveSram?.call() ?? false;
  }

  Future<CrystalGsBallStatus> inspectGsBall() async {
    return await _inspectGsBall?.call() ?? CrystalGsBallStatus.noSave;
  }

  Future<CrystalGsBallActivationResult> activateGsBall({
    bool allowBeforeLeague = false,
  }) async {
    return await _activateGsBall?.call(allowBeforeLeague) ??
        const CrystalGsBallActivationResult(
          status: CrystalGsBallStatus.noSave,
        );
  }

  Future<void> restart() async => _restart?.call();

  void setPaused(bool paused) => _setPaused?.call(paused);

  int get currentPlayTimeMinutes {
    return _currentPlayTimeMinutes?.call() ?? 0;
  }

  Map<String, int> inspectMemoryRegions() {
    return _inspectMemoryRegions?.call() ?? const <String, int>{};
  }

  Map<String, LibretroMemoryRegionDiagnostics>
  inspectMemoryRegionDiagnostics() {
    return _inspectMemoryRegionDiagnostics?.call() ??
        const <String, LibretroMemoryRegionDiagnostics>{};
  }

  Uint8List readMemoryBlock({
    required int memoryId,
    required int offset,
    required int length,
  }) {
    return _readMemoryBlock?.call(memoryId, offset, length) ?? Uint8List(0);
  }

  Uint8List readMemoryAddress({required int address, required int length}) {
    return _readMemoryAddress?.call(address, length) ?? Uint8List(0);
  }

  Map<String, String> runtimeIdentity() {
    return _runtimeIdentity?.call() ?? const <String, String>{};
  }

  void _attach({
    required void Function(int buttonId, bool pressed) setButtonState,
    required VoidCallback resetInput,
    required Future<bool> Function(int slot, String title) saveState,
    required Future<bool> Function(int slot) loadState,
    required Future<bool> Function() saveSram,
    required Future<CrystalGsBallStatus> Function() inspectGsBall,
    required Future<CrystalGsBallActivationResult> Function(
      bool allowBeforeLeague,
    ) activateGsBall,
    required Future<void> Function() restart,
    required void Function(bool paused) setPaused,
    required int Function() currentPlayTimeMinutes,
    required Map<String, int> Function() inspectMemoryRegions,
    required Map<String, LibretroMemoryRegionDiagnostics> Function()
    inspectMemoryRegionDiagnostics,
    required Uint8List Function(int memoryId, int offset, int length)
    readMemoryBlock,
    required Uint8List Function(int address, int length) readMemoryAddress,
    required Map<String, String> Function() runtimeIdentity,
    required ValueNotifier<int> speedMultiplierNotifier,
    required VoidCallback cycleSpeed,
    required LinkManager linkManager,
  }) {
    _setButtonState = setButtonState;
    _resetInput = resetInput;
    _saveState = saveState;
    _loadState = loadState;
    _saveSram = saveSram;
    _inspectGsBall = inspectGsBall;
    _activateGsBall = activateGsBall;
    _restart = restart;
    _setPaused = setPaused;
    _currentPlayTimeMinutes = currentPlayTimeMinutes;
    _inspectMemoryRegions = inspectMemoryRegions;
    _inspectMemoryRegionDiagnostics = inspectMemoryRegionDiagnostics;
    _readMemoryBlock = readMemoryBlock;
    _readMemoryAddress = readMemoryAddress;
    _runtimeIdentity = runtimeIdentity;
    _speedMultiplierNotifier = speedMultiplierNotifier;
    _cycleSpeed = cycleSpeed;
    _linkManager = linkManager;
  }

  void _detach() {
    _setButtonState = null;
    _resetInput = null;
    _saveState = null;
    _loadState = null;
    _saveSram = null;
    _inspectGsBall = null;
    _activateGsBall = null;
    _restart = null;
    _setPaused = null;
    _currentPlayTimeMinutes = null;
    _inspectMemoryRegions = null;
    _inspectMemoryRegionDiagnostics = null;
    _readMemoryBlock = null;
    _readMemoryAddress = null;
    _runtimeIdentity = null;
    _speedMultiplierNotifier = null;
    _cycleSpeed = null;
    _linkManager = null;
  }
}

class LibretroGameView extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final String corePath;
  final String romPath;
  final int initialPlayTimeMinutes;
  final LibretroGameController? controller;
  final BoxFit screenFit;
  final FilterQuality filterQuality;
  final bool autoLoadState;

  const LibretroGameView({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.corePath,
    required this.romPath,
    this.initialPlayTimeMinutes = 0,
    this.controller,
    this.screenFit = BoxFit.contain,
    this.filterQuality = FilterQuality.none,
    this.autoLoadState = false,
  });

  @override
  State<LibretroGameView> createState() => _LibretroGameViewState();
}

class _LibretroGameViewState extends State<LibretroGameView> {
  static const int _buttonB = 0;
  static const int _buttonY = 1;
  static const int _buttonSelect = 2;
  static const int _buttonStart = 3;
  static const int _buttonUp = 4;
  static const int _buttonDown = 5;
  static const int _buttonLeft = 6;
  static const int _buttonRight = 7;
  static const int _buttonA = 8;
  static const int _buttonX = 9;
  static const int _buttonL = 10;
  static const int _buttonR = 11;

  final FocusNode _focusNode = FocusNode(
    debugLabel: 'LibretroGameViewKeyboard',
  );

  final Set<int> _pressedButtons = <int>{};

  LibretroBridge? _bridge;
  LibretroAudioPlayer? _audioPlayer;
  Timer? _emulationTimer;
  Timer? _sramTimer;
  Timer? _memoryDebugTimer;

  ui.Image? _currentImage;
  GamePersistencePaths? _persistencePaths;
  SaveStateService? _saveStateService;
  late final DateTime _sessionStartedAt;

  bool _isStarting = true;
  bool _isRunning = false;
  bool _isDecodingFrame = false;
  bool _disposed = false;
  bool _persistenceOperationInProgress = false;
  bool _paused = false;
  bool _autoLoadAttempted = false;

  String? _errorMessage;
  String _statusMessage = 'Preparando emulador...';

  int _framesRendered = 0;
  final ValueNotifier<int> _speedMultiplierNotifier = ValueNotifier<int>(1);
  int _systemRamSize = 0;

  late final LinkManager _linkManager;

  bool _linkBridgeEnabled = false;
  late final StreamSubscription<LinkState> _linkStateSubscription;
  late final StreamSubscription<Uint8List> _linkPacketSubscription;
  final List<Uint8List> _pendingLinkPackets = <Uint8List>[];

  final CrystalGsBallService _crystalGsBallService =
      const CrystalGsBallService();

  PokemonEngine? _pokemonEngine;
  GameEngineStatus<PokemonMemorySnapshot>? _pokemonStatus;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _linkManager = LinkManager(transport: createDefaultLinkTransport());
    _linkStateSubscription = _linkManager.onStateChanged.listen(
      _handleLinkStateChanged,
    );
    _linkPacketSubscription = _linkManager.onPacket.listen(
      _handleLinkPacketFromBluetooth,
    );
    _saveStateService = SaveStateService(
      gameId: widget.gameId,
      romPath: widget.romPath,
    );
    _attachController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }

      _startEmulator();
    });
  }

  @override
  void didUpdateWidget(covariant LibretroGameView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      _attachController();
    }
    if (!oldWidget.autoLoadState && widget.autoLoadState) {
      unawaited(_tryAutoLoadState());
    }
  }

  void _attachController() {
    widget.controller?._attach(
      setButtonState: _setButtonPressed,
      resetInput: _releaseAllButtons,
      saveState: _saveState,
      loadState: _loadState,
      saveSram: _saveSram,
      inspectGsBall: _inspectGsBall,
      activateGsBall: _activateGsBall,
      restart: _restartEmulator,
      setPaused: _setPaused,
      currentPlayTimeMinutes: _currentPlayTimeMinutes,
      inspectMemoryRegions: _inspectMemoryRegions,
      inspectMemoryRegionDiagnostics: _inspectMemoryRegionDiagnostics,
      readMemoryBlock: _readMemoryBlock,
      readMemoryAddress: _readMemoryAddress,
      runtimeIdentity: _runtimeIdentity,
      speedMultiplierNotifier: _speedMultiplierNotifier,
      cycleSpeed: _cycleSpeed,
      linkManager: _linkManager,
    );
  }

  /// Deriva la ruta del archivo .rtc a partir de la ruta .srm de la
  /// misma partida (p.ej. "Pokemon Crystal.srm" -> "Pokemon
  /// Crystal.rtc"). Reemplaza únicamente el sufijo ".srm"; nunca
  /// concatena.
  String _rtcFilePathFor(String sramFilePath) {
    const String sramSuffix = '.srm';

    if (sramFilePath.toLowerCase().endsWith(sramSuffix)) {
      return '${sramFilePath.substring(0, sramFilePath.length - sramSuffix.length)}.rtc';
    }

    return '$sramFilePath.rtc';
  }

  Map<String, int> _inspectMemoryRegions() {
    final bridge = _bridge;
    if (_disposed || !_isRunning || bridge == null)
      return const <String, int>{};
    try {
      return bridge.inspectMemoryRegions();
    } catch (error) {
      debugPrint('Error inspeccionando memoria: $error');
      return const <String, int>{};
    }
  }

  Map<String, LibretroMemoryRegionDiagnostics>
  _inspectMemoryRegionDiagnostics() {
    final bridge = _bridge;
    if (_disposed || !_isRunning || bridge == null) {
      return const <String, LibretroMemoryRegionDiagnostics>{};
    }
    try {
      return bridge.inspectMemoryRegionDiagnostics();
    } catch (error) {
      debugPrint('Error inspeccionando regiones de memoria: $error');
      return const <String, LibretroMemoryRegionDiagnostics>{};
    }
  }

  Uint8List _readMemoryBlock(int memoryId, int offset, int length) {
    final bridge = _bridge;
    if (_disposed ||
        !_isRunning ||
        bridge == null ||
        _persistenceOperationInProgress)
      return Uint8List(0);
    try {
      return bridge.readMemoryBlock(
        memoryId: memoryId,
        offset: offset,
        length: length,
      );
    } catch (error) {
      debugPrint('Error leyendo memoria: $error');
      return Uint8List(0);
    }
  }

  Uint8List _readMemoryAddress(int address, int length) {
    final bridge = _bridge;
    if (_disposed ||
        !_isRunning ||
        bridge == null ||
        _persistenceOperationInProgress) {
      return Uint8List(0);
    }
    try {
      return bridge.readMemoryAddress(address: address, length: length);
    } catch (error) {
      debugPrint('Error leyendo dirección GBA: $error');
      return Uint8List(0);
    }
  }

  Map<String, String> _runtimeIdentity() {
    final bridge = _bridge;
    return <String, String>{
      'core': bridge == null
          ? 'Unavailable'
          : '${bridge.coreName()} ${bridge.coreVersion()}'.trim(),
      'rom': widget.romPath,
      'game': widget.gameTitle,
    };
  }

  Future<void> _startEmulator() async {
    if (_disposed) return;

    try {
      setState(() {
        _isStarting = true;
        _errorMessage = null;
        _statusMessage = 'Preparando carpetas de guardado...';
      });

      _persistencePaths = CoreLoader.ensurePersistenceDirectories(
        gameId: widget.gameId,
        romPath: widget.romPath,
      );

      final bridge = LibretroBridge();
      _bridge = bridge;

      setState(() {
        _statusMessage = 'Cargando core libretro...';
      });

      final coreLoaded = bridge.loadCore(widget.corePath);

      if (!coreLoaded) {
        throw Exception('No se pudo cargar el core:\n${widget.corePath}');
      }

      final coreName = bridge.coreName();
      final coreVersion = bridge.coreVersion();

      setState(() {
        _statusMessage = 'Core cargado: $coreName $coreVersion';
      });

      final persistencePaths = _persistencePaths;
      if (persistencePaths != null) {
        Directory(persistencePaths.sramDirectory).createSync(recursive: true);

        bridge.setSaveDirectory(persistencePaths.sramDirectory);
        bridge.setSystemDirectory(persistencePaths.sramDirectory);
      }

      final gameLoaded = bridge.loadGame(widget.romPath);

      if (!gameLoaded) {
        throw Exception('$coreName no pudo cargar la ROM:\n${widget.romPath}');
      }

      // El pipeline PCM/SoLoud se usa exclusivamente para SNES.
      // GB/GBC (SameBoy) y GBA (mGBA) mantienen su comportamiento previo.
      final String normalizedCoreName = coreName.toLowerCase();
      final bool usesSoLoudAudio =
          normalizedCoreName.contains('snes9x') ||
          normalizedCoreName.contains('snes');

      if (usesSoLoudAudio) {
        final audioPlayer = LibretroAudioPlayer();
        _audioPlayer = audioPlayer;
        await audioPlayer.start(bridge);
      } else {
        _audioPlayer = null;
      }

      final paths = _persistencePaths;
      if (paths != null && File(paths.sramFile).existsSync()) {
        final bool loaded = bridge.loadSram(paths.sramFile);
        debugPrint(
          loaded
              ? 'SRAM cargada: ${paths.sramFile}'
              : 'No se pudo cargar SRAM: ${paths.sramFile}',
        );
      }

      // RTC: siempre después de la SRAM y antes del primer frame,
      // para que el core arranque ya con la hora restaurada en
      // lugar de inicializar su propio reloj y luego pisarlo.
      if (paths != null && bridge.coreHasRtc()) {
        final String rtcPath = _rtcFilePathFor(paths.sramFile);
        debugPrint('Cargando RTC...');
        final bool rtcLoaded = bridge.loadRtc(rtcPath);
        debugPrint(
          rtcLoaded ? 'RTC cargado' : 'No se pudo cargar RTC: $rtcPath',
        );
      }

      if (_disposed) {
        bridge.dispose();
        return;
      }

      bridge.resetInput();

      _pokemonEngine = PokemonEngine(
        bridge: bridge,
        gameTitle: widget.gameTitle,
        romPath: widget.romPath,
      );

      setState(() {
        _isStarting = false;
        _isRunning = true;
        _statusMessage = 'Juego ejecutándose';
      });

      _handleLinkStateChanged(_linkManager.state);
      _focusNode.requestFocus();

      _emulationTimer = Timer.periodic(
        const Duration(microseconds: 16667),
        (_) => _emulationTick(),
      );

      _sramTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _saveSram();
      });

      _memoryDebugTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _refreshPokemonDiagnostic(),
      );

      _refreshPokemonDiagnostic();
      unawaited(_tryAutoLoadState());
    } catch (error, stackTrace) {
      debugPrint('Error iniciando Libretro: $error');
      debugPrintStack(stackTrace: stackTrace);

      _stopEmulator(saveSram: false);

      if (!mounted || _disposed) return;

      setState(() {
        _isStarting = false;
        _isRunning = false;
        _errorMessage = error.toString();
        _statusMessage = 'No se pudo iniciar el emulador';
      });
    }
  }

  void _emulationTick() {
    if (_disposed ||
        !_isRunning ||
        _paused ||
        _isDecodingFrame ||
        _persistenceOperationInProgress ||
        _bridge == null)
      return;

    final LibretroBridge bridge = _bridge!;
    final int runs = _linkBridgeEnabled ? 1 : _speedMultiplierNotifier.value;

    for (int index = 0; index < runs; index++) {
      if (!bridge.runOnce()) return;
      _pumpLinkCable(bridge);
    }

    _audioPlayer?.pump(bridge);
    final LibretroFrame? frame = bridge.readFrame();
    if (frame != null) _decodeFrame(frame);
  }

  void _setPaused(bool paused) {
    if (_disposed || _paused == paused) return;
    _paused = paused;
    if (paused) _releaseAllButtons();
    _audioPlayer?.setPaused(paused || _speedMultiplierNotifier.value != 1);
  }

  Future<void> _tryAutoLoadState() async {
    if (_autoLoadAttempted || !widget.autoLoadState || !_isRunning) return;
    _autoLoadAttempted = true;
    await _loadState(SaveStateService.autoSaveSlot);
  }

  void _handleLinkStateChanged(LinkState state) {
    final bridge = _bridge;
    if (bridge == null || !bridge.linkSupported) return;
    final active = state == LinkState.connected || state == LinkState.syncing;

    if (active && !_linkBridgeEnabled) {
      _linkBridgeEnabled = bridge.enableLink();
      if (_linkBridgeEnabled) {
        _speedMultiplierNotifier.value = 1;
        _audioPlayer?.setPaused(false);
      }
      debugPrint('[RetroHub Link] enableLink() -> $_linkBridgeEnabled');
    } else if (!active && _linkBridgeEnabled) {
      bridge.disableLink();
      _linkBridgeEnabled = false;
      _pendingLinkPackets.clear();
    } else if (!active) {
      _pendingLinkPackets.clear();
    }
  }

  void _handleLinkPacketFromBluetooth(Uint8List bytes) {
    if (!_linkBridgeEnabled || bytes.isEmpty) return;
    _pendingLinkPackets.add(Uint8List.fromList(bytes));
    debugPrint(
      '[RetroHub Link] BT -> CORE queued: ${bytes.length} bytes (pending=${_pendingLinkPackets.length})',
    );
  }

  void _pumpLinkCable(LibretroBridge bridge) {
    if (!_linkBridgeEnabled) return;

    while (_pendingLinkPackets.isNotEmpty) {
      final incoming = _pendingLinkPackets.first;
      if (!bridge.linkSend(incoming)) break;
      _pendingLinkPackets.removeAt(0);
      debugPrint(
        '[RetroHub Link] BT -> CORE: ${incoming.length} bytes (pending=${_pendingLinkPackets.length})',
      );
    }

    final outgoing = bridge.linkReceive();
    if (outgoing.isEmpty) return;
    debugPrint('[RetroHub Link] CORE -> BT: ${outgoing.length} bytes');
    _linkManager.sendPacket(outgoing);
  }

  void _cycleSpeed() {
    if (!mounted || _disposed || _linkBridgeEnabled) {
      return;
    }

    switch (_speedMultiplierNotifier.value) {
      case 1:
        _speedMultiplierNotifier.value = 2;
        break;
      case 2:
        _speedMultiplierNotifier.value = 4;
        break;
      case 4:
        _speedMultiplierNotifier.value = 8;
        break;
      default:
        _speedMultiplierNotifier.value = 1;
    }

    _audioPlayer?.setPaused(_speedMultiplierNotifier.value != 1);

    _focusNode.requestFocus();
  }

  void _decodeFrame(LibretroFrame frame) {
    if (_disposed || _isDecodingFrame) return;

    _isDecodingFrame = true;

    ui.decodeImageFromPixels(
      frame.rgbaBytes,
      frame.width,
      frame.height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        _isDecodingFrame = false;

        if (_disposed || !mounted) {
          image.dispose();
          return;
        }

        final previousImage = _currentImage;

        setState(() {
          _currentImage = image;
          _framesRendered++;
        });

        previousImage?.dispose();
      },
      rowBytes: frame.width * 4,
    );
  }

  void _refreshPokemonDiagnostic() {
    final PokemonEngine? engine = _pokemonEngine;

    if (_disposed ||
        !_isRunning ||
        engine == null ||
        _persistenceOperationInProgress) {
      return;
    }

    final GameEngineStatus<PokemonMemorySnapshot> status = engine.readStatus();

    if (!mounted || _disposed) return;

    setState(() {
      _systemRamSize = status.systemRamSize;
      _pokemonStatus = status;
    });
  }

  Future<CrystalGsBallStatus> _inspectGsBall() async {
    final paths = _persistencePaths;
    if (paths == null) return CrystalGsBallStatus.noSave;

    if (!_persistenceOperationInProgress) {
      await _saveSram();
    }
    return _crystalGsBallService.inspect(paths.sramFile);
  }

  Future<CrystalGsBallActivationResult> _activateGsBall(
    bool allowBeforeLeague,
  ) async {
    final bridge = _bridge;
    final paths = _persistencePaths;
    if (_disposed ||
        !_isRunning ||
        bridge == null ||
        paths == null ||
        _persistenceOperationInProgress) {
      return const CrystalGsBallActivationResult(
        status: CrystalGsBallStatus.noSave,
      );
    }

    final bool wasPaused = _paused;
    _paused = true;
    _persistenceOperationInProgress = true;
    try {
      Directory(paths.sramDirectory).createSync(recursive: true);
      if (!bridge.saveSram(paths.sramFile)) {
        throw StateError('No se pudo guardar la SRAM antes de activar el evento.');
      }

      final result = await _crystalGsBallService.activate(
        paths.sramFile,
        allowBeforeLeague: allowBeforeLeague,
      );
      if (result.succeeded && !bridge.loadSram(paths.sramFile)) {
        throw StateError('El evento se activó, pero no se pudo recargar la SRAM.');
      }
      return result;
    } finally {
      _persistenceOperationInProgress = false;
      _paused = wasPaused;
    }
  }

  Future<bool> _saveSram() async {
    final bridge = _bridge;
    final paths = _persistencePaths;

    if (_disposed ||
        !_isRunning ||
        bridge == null ||
        paths == null ||
        _persistenceOperationInProgress) {
      return false;
    }

    _persistenceOperationInProgress = true;

    try {
      Directory(paths.sramDirectory).createSync(recursive: true);
      final bool saved = bridge.saveSram(paths.sramFile);

      if (saved) {
        debugPrint('SRAM guardada: ${paths.sramFile}');
      }

      if (bridge.coreHasRtc()) {
        debugPrint('Guardando RTC...');
        final bool rtcSaved = bridge.saveRtc(_rtcFilePathFor(paths.sramFile));
        debugPrint(rtcSaved ? 'RTC OK' : 'Error guardando RTC');
      }

      return saved;
    } catch (error) {
      debugPrint('Error guardando SRAM: $error');
      return false;
    } finally {
      _persistenceOperationInProgress = false;
    }
  }

  Future<bool> _saveState(int slot, String title) async {
    final bridge = _bridge;
    final service = _saveStateService;

    if (_disposed ||
        !_isRunning ||
        bridge == null ||
        service == null ||
        _persistenceOperationInProgress) {
      return false;
    }

    _persistenceOperationInProgress = true;

    try {
      final String statePath = service.statePath(slot);
      final bool saved = bridge.saveState(statePath);

      if (!saved) {
        return false;
      }

      final ui.Image? image = _currentImage;
      bool hasThumbnail = false;

      if (image != null) {
        final ByteData? pngData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (pngData != null) {
          hasThumbnail = await service.writeThumbnail(
            slot: slot,
            bytes: pngData.buffer.asUint8List(),
          );
        }
      }

      await service.writeMetadata(
        slot: slot,
        title: title,
        playTimeMinutes: _currentPlayTimeMinutes(),
        createdAt: DateTime.now(),
        hasThumbnail: hasThumbnail,
      );

      final paths = _persistencePaths;
      if (paths != null) {
        bridge.saveSram(paths.sramFile);
      }

      debugPrint('Estado guardado: $statePath');

      return true;
    } catch (error) {
      debugPrint('Error guardando estado: $error');
      return false;
    } finally {
      _persistenceOperationInProgress = false;
    }
  }

  Future<bool> _loadState(int slot) async {
    final bridge = _bridge;
    final service = _saveStateService;

    if (_disposed ||
        !_isRunning ||
        bridge == null ||
        service == null ||
        _persistenceOperationInProgress) {
      return false;
    }

    final String statePath = service.statePath(slot);

    if (!File(statePath).existsSync()) {
      return false;
    }

    _persistenceOperationInProgress = true;

    try {
      _releaseAllButtons();
      final bool loaded = bridge.loadState(statePath);

      if (loaded) {
        debugPrint('Estado cargado: $statePath');
      }

      return loaded;
    } catch (error) {
      debugPrint('Error cargando estado: $error');
      return false;
    } finally {
      _persistenceOperationInProgress = false;
    }
  }

  int _currentPlayTimeMinutes() {
    final int sessionMinutes = DateTime.now()
        .difference(_sessionStartedAt)
        .inMinutes;

    return widget.initialPlayTimeMinutes + sessionMinutes;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final buttonId = _buttonForKey(event.logicalKey);

    if (buttonId == null) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _setButtonPressed(buttonId, true);
    } else if (event is KeyUpEvent) {
      _setButtonPressed(buttonId, false);
    }

    return KeyEventResult.handled;
  }

  int? _buttonForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) return _buttonUp;
    if (key == LogicalKeyboardKey.arrowDown) return _buttonDown;
    if (key == LogicalKeyboardKey.arrowLeft) return _buttonLeft;
    if (key == LogicalKeyboardKey.arrowRight) return _buttonRight;
    if (key == LogicalKeyboardKey.keyZ) return _buttonA;
    if (key == LogicalKeyboardKey.keyX) return _buttonB;
    if (key == LogicalKeyboardKey.keyC) return _buttonX;
    if (key == LogicalKeyboardKey.keyV) return _buttonY;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return _buttonStart;
    }

    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      return _buttonSelect;
    }

    if (key == LogicalKeyboardKey.keyA) return _buttonL;
    if (key == LogicalKeyboardKey.keyS) return _buttonR;

    return null;
  }

  void _setButtonPressed(int buttonId, bool pressed) {
    final bridge = _bridge;

    if (bridge == null ||
        !_isRunning ||
        _disposed ||
        _persistenceOperationInProgress) {
      return;
    }

    if (pressed) {
      if (!_pressedButtons.add(buttonId)) return;
    } else {
      if (!_pressedButtons.remove(buttonId)) return;
    }

    bridge.setButtonState(buttonId, pressed);

    if (mounted) setState(() {});
  }

  void _releaseAllButtons() {
    final bridge = _bridge;

    for (final buttonId in _pressedButtons.toList()) {
      bridge?.setButtonState(buttonId, false);
    }

    _pressedButtons.clear();

    try {
      bridge?.resetInput();
    } catch (error) {
      debugPrint('Error reiniciando input: $error');
    }
  }

  void _stopEmulator({bool saveSram = true}) {
    _isRunning = false;

    _emulationTimer?.cancel();
    _emulationTimer = null;

    _sramTimer?.cancel();
    _sramTimer = null;

    _memoryDebugTimer?.cancel();
    _memoryDebugTimer = null;

    _releaseAllButtons();

    final audioPlayer = _audioPlayer;
    _audioPlayer = null;
    unawaited(audioPlayer?.dispose() ?? Future<void>.value());

    final bridge = _bridge;
    final paths = _persistencePaths;

    if (saveSram && bridge != null && paths != null) {
      try {
        Directory(paths.sramDirectory).createSync(recursive: true);
        bridge.saveSram(paths.sramFile);

        if (bridge.coreHasRtc()) {
          debugPrint('Guardando RTC...');
          final bool rtcSaved = bridge.saveRtc(_rtcFilePathFor(paths.sramFile));
          debugPrint(rtcSaved ? 'RTC OK' : 'Error guardando RTC');
        }
      } catch (error) {
        debugPrint('Error guardando SRAM al cerrar: $error');
      }
    }

    _pokemonEngine?.dispose();
    _pokemonEngine = null;
    _pokemonStatus = null;

    _bridge = null;

    try {
      bridge?.dispose();
    } catch (error) {
      debugPrint('Error liberando Libretro: $error');
    }
  }

  Future<void> _restartEmulator() async {
    _stopEmulator();

    final previousImage = _currentImage;
    _currentImage = null;
    previousImage?.dispose();

    setState(() {
      _framesRendered = 0;
      _errorMessage = null;
      _isStarting = true;
      _statusMessage = 'Reiniciando emulador...';
    });

    await _startEmulator();
  }

  @override
  void dispose() {
    _disposed = true;
    widget.controller?._detach();
    _stopEmulator();
    _currentImage?.dispose();
    _currentImage = null;
    _focusNode.dispose();
    _speedMultiplierNotifier.dispose();
    _linkStateSubscription.cancel();
    _linkPacketSubscription.cancel();
    _linkManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (hasFocus) {
        if (!hasFocus) _releaseAllButtons();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.requestFocus,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) return _buildErrorView();

    final image = _currentImage;

    if (image != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: image.width / image.height,
              child: RawImage(
                image: image,
                fit: widget.screenFit,
                filterQuality: widget.filterQuality,
              ),
            ),
          ),
          if (kDebugMode && !Platform.isAndroid)
            Positioned(top: 12, left: 12, child: _buildStatusBadge()),
          if (kDebugMode && !Platform.isAndroid)
            Positioned(top: 12, right: 12, child: _buildMemoryBadge()),
        ],
      );
    }

    return _buildLoadingView();
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 18),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          widget.romPath,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 44,
          ),
          const SizedBox(height: 12),
          const Text(
            'Error al ejecutar el juego',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isStarting ? null : _restartEmulator,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryBadge() {
    final GameEngineStatus<PokemonMemorySnapshot>? status = _pokemonStatus;
    final PokemonMemorySnapshot? snapshot = status?.snapshot;
    final bool decoderReady = status?.isReady ?? false;

    final String title = decoderReady ? 'POKÉMON ENGINE' : 'MEMORY ENGINE';

    final Color accent = decoderReady
        ? Colors.greenAccent
        : Colors.orangeAccent;

    final String content;

    if (snapshot != null) {
      final String playerName = snapshot.playerName.isEmpty
          ? 'Sin nombre'
          : snapshot.playerName;

      content = <String>[
        'Jugador: $playerName',
        'Mapa: ${PokemonDecoder.mapName(snapshot.profile, snapshot.currentMapId)} '
            '(0x${snapshot.currentMapId.toRadixString(16).padLeft(2, '0').toUpperCase()})',
        'Posición: ${snapshot.playerX}, ${snapshot.playerY}',
        'Dinero: ₽${snapshot.money}',
        'Medallas: ${snapshot.badgeCount}',
        'Pokédex: ${snapshot.pokedexSeen}/${snapshot.pokedexCaught}',
        'Equipo: ${snapshot.party.length} Pokémon',
        if (snapshot.party.isNotEmpty)
          snapshot.party.map((p) => '${p.name} Nv.${p.level}').join(', '),
      ].join('\n');
    } else {
      content = <String>[
        'Memoria: ${_systemRamSize > 0 ? 'conectada' : 'sin conexión'}',
        'RAM: $_systemRamSize bytes',
        'Juego: ${status?.gameName ?? 'detectando...'}',
        'Decoder: ${status?.state.name ?? 'iniciando'}',
        if (status?.message != null) status!.message!,
      ].join('\n');
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 230, maxWidth: 350),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    decoderReady
                        ? Icons.memory_rounded
                        : Icons.developer_board_rounded,
                    color: accent,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                content,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 10,
                  height: 1.35,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Frames: $_framesRendered',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
