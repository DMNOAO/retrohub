import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'presentation/widget/retrohub_console_logo.dart';
import 'presentation/widget/retrohub_quick_menu.dart';
import 'presentation/widget/speed_button.dart';
import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_resolver.dart';
import '../../core/emulation/core_loader.dart';
import '../../core/utils/cover_helper.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../frames/frames_page.dart';
import '../frames/frame_catalog.dart';
import '../frames/frame_preferences.dart';
import '../frames/portrait_frame_catalog.dart';
import '../profile/auth/auth_provider.dart';
import '../profile/cloud/cloud_save_coordinator.dart';
import '../journal/journal_page.dart';
import '../journal/services/journal_event_service.dart';
import '../pokemon/services/pokemon_journal_tracker.dart';
import '../pokemon/models/pokemon_game_profile.dart';
import 'data/save_state_service.dart';
import 'presentation/widget/libretro_game_view.dart';
import 'memory_inspector/memory_inspector_page.dart';
import 'settings/emulator_preferences.dart';
import 'settings/emulator_settings_page.dart';
import 'special_events/special_events_page.dart';
import 'save_states/save_states_page.dart';
import 'link/link_state.dart';
import 'link/link_manager.dart';
import 'link/bluetooth/bluetooth_discovery.dart';

class EmulatorPage extends ConsumerStatefulWidget {
  final Game game;

  const EmulatorPage({super.key, required this.game});

  @override
  ConsumerState<EmulatorPage> createState() => _EmulatorPageState();
}

class _EmulatorPageState extends ConsumerState<EmulatorPage>
    with WidgetsBindingObserver {
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

  final LibretroGameController _gameController = LibretroGameController();
  final GlobalKey _gameViewKey = GlobalKey(debugLabel: 'libretro-game-view');

  late final AppDatabase _database;
  late final JournalEventService _journalEventService;
  PokemonJournalTracker? _pokemonJournalTracker;
  late final DateTime _sessionStartedAt;
  bool _sessionClosedLogged = false;
  bool _sessionPersisted = false;
  bool _isClosing = false;
  bool _allowPop = false;
  String _closingStatus = 'Guardando partida…';
  bool _exitDialogOpen = false;
  Timer? _headerRefreshTimer;
  int? _ndsTouchPointer;
  List<int> _partySpeciesIds = const <int>[];
  EmulatorPreferences _preferences = const EmulatorPreferences();
  GameFrame? _selectedFrame;
  PortraitGameFrame? _selectedPortraitFrame;

  Game get game => widget.game;

  bool get _isAndroidSnes =>
      defaultTargetPlatform == TargetPlatform.android &&
      CoreLoader.isSnesRom(game.romPath);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (_isAndroidSnes) {
      unawaited(
        SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
    }

    _sessionStartedAt = DateTime.now();
    unawaited(_loadEmulatorPreferences());
    _database = ref.read(databaseProvider);

    unawaited(_database.markGameOpened(game.id, _sessionStartedAt));

    _journalEventService = JournalEventService(
      database: _database,
      gameId: game.id,
    );

    final PokemonGameProfile pokemonProfile =
        PokemonGameProfile.fromGameIdentity(
          gameTitle: game.title,
          romPath: game.romPath,
        );
    final bool supportsPokemonJournal =
        pokemonProfile.isGen4 ||
        pokemonProfile.isGen5 ||
        CoreLoader.isGameBoyRom(game.romPath) ||
        (CoreLoader.isGbaRom(game.romPath) &&
            (pokemonProfile.version == PokemonGameVersion.emerald ||
                pokemonProfile.version == PokemonGameVersion.ruby ||
                pokemonProfile.version == PokemonGameVersion.sapphire ||
                pokemonProfile.version == PokemonGameVersion.fireRed ||
                pokemonProfile.version == PokemonGameVersion.leafGreen));

    if (supportsPokemonJournal) {
      _pokemonJournalTracker = PokemonJournalTracker(
        database: _database,
        gameId: game.id,
        gameTitle: game.title,
        romPath: game.romPath,
        controller: _gameController,
        playTimeMinutes: () => _currentPlayTimeMinutes,
      )..start();
      unawaited(_refreshHeaderParty());
      _headerRefreshTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_refreshHeaderParty()),
      );
    }

    unawaited(
      _journalEventService.logGameStarted(
        playTimeMinutes: game.playTimeSeconds ~/ 60,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (CoreLoader.isSnesRom(game.romPath) ||
        !_preferences.pauseInBackground) {
      return;
    }
    _gameController.setPaused(state != AppLifecycleState.resumed);
  }

  Future<void> _loadEmulatorPreferences() async {
    final preferences = await EmulatorPreferences.load();
    final frameId = await FramePreferences.load(game.id);
    final portraitFrameId = await FramePreferences.loadPortrait(game.id);
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _selectedFrame = FrameCatalog.byId(game, frameId);
      _selectedPortraitFrame = portraitFrameId == 'none'
          ? null
          : PortraitFrameCatalog.byId(game, portraitFrameId) ??
              PortraitFrameCatalog.recommendedFor(game);
    });
    await _applyDisplayPreferences(preferences);
  }

  Future<void> _reloadSelectedFrame() async {
    final frameId = await FramePreferences.load(game.id);
    final portraitFrameId = await FramePreferences.loadPortrait(game.id);
    if (!mounted) return;
    setState(() {
      _selectedFrame = FrameCatalog.byId(game, frameId);
      _selectedPortraitFrame = portraitFrameId == 'none'
          ? null
          : PortraitFrameCatalog.byId(game, portraitFrameId) ??
              PortraitFrameCatalog.recommendedFor(game);
    });
  }

  Future<void> _applyDisplayPreferences(EmulatorPreferences preferences) async {
    if (CoreLoader.isSnesRom(game.romPath)) {
      await WakelockPlus.toggle(enable: preferences.keepScreenAwake);
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(
        preferences.snesFullscreen
            ? SystemUiMode.immersiveSticky
            : SystemUiMode.edgeToEdge,
      );
      return;
    }
    if (CoreLoader.isNdsRom(game.romPath) && preferences.ndsFullscreen) {
      await WakelockPlus.toggle(enable: preferences.keepScreenAwake);
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }
    if ((CoreLoader.isGbaRom(game.romPath) && preferences.gbaFullscreen) ||
        (CoreLoader.isGameBoyRom(game.romPath) &&
            preferences.gameBoyFullscreen)) {
      await WakelockPlus.toggle(enable: preferences.keepScreenAwake);
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }
    await WakelockPlus.toggle(enable: preferences.keepScreenAwake);
    final orientations = switch (preferences.orientation) {
      EmulatorOrientation.automatic => const <DeviceOrientation>[],
      EmulatorOrientation.portrait => const <DeviceOrientation>[
          DeviceOrientation.portraitUp,
        ],
      EmulatorOrientation.landscape => const <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
    };
    await SystemChrome.setPreferredOrientations(orientations);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _refreshHeaderParty() async {
    final snapshot = await _database.getLatestProgressSnapshot(game.id);
    if (!mounted || snapshot?.partyJson == null) return;

    try {
      final decoded = jsonDecode(snapshot!.partyJson!);
      if (decoded is! List) return;

      final ids = decoded
          .whereType<Map>()
          .map((pokemon) {
            final bool isEgg =
                pokemon['isEgg'] == true ||
                pokemon['isEgg']?.toString() == 'true';
            if (isEgg) return 0;

            final dynamic rawId = pokemon['id'];
            if (rawId is num) return rawId.toInt();
            return int.tryParse(rawId?.toString() ?? '');
          })
          .whereType<int>()
          .where((id) => id >= 0)
          .take(6)
          .toList(growable: false);

      if (!_sameIds(ids, _partySpeciesIds)) {
        setState(() => _partySpeciesIds = ids);
      }
    } catch (_) {
      // A corrupt or older snapshot must not affect the emulator screen.
    }
  }

  bool _sameIds(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  int get _currentPlayTimeMinutes {
    final int controllerMinutes = _gameController.currentPlayTimeMinutes;

    if (controllerMinutes > 0) {
      return controllerMinutes;
    }

    final int sessionMinutes = DateTime.now()
        .difference(_sessionStartedAt)
        .inMinutes;

    return (game.playTimeSeconds ~/ 60) + sessionMinutes;
  }

  Future<void> _persistSession() async {
    if (_sessionPersisted) return;
    _sessionPersisted = true;
    final endedAt = DateTime.now();
    await _database.addGamePlayTime(
      gameId: game.id,
      sessionSeconds: endedAt.difference(_sessionStartedAt).inSeconds,
      closedAt: endedAt,
    );
  }

  Future<void> _logSessionClosed() async {
    if (_sessionClosedLogged) {
      return;
    }

    _sessionClosedLogged = true;

    await _persistSession();

    await _journalEventService.logGameClosed(
      playTimeMinutes: _currentPlayTimeMinutes,
      sessionDurationMinutes: DateTime.now()
          .difference(_sessionStartedAt)
          .inMinutes,
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String value) async {
    switch (value) {
      case 'save_state':
        await _openSaveStates(context, mode: SaveStatesMode.save);
        break;

      case 'load_state':
        await _openSaveStates(context, mode: SaveStatesMode.load);
        break;
      case 'screenshot':
        await _journalEventService.logScreenshot(
          playTimeMinutes: _currentPlayTimeMinutes,
        );

        if (!context.mounted) return;

        _showActionMessage(context, 'Captura registrada en la bitácora');
        break;
      case 'change_frame':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FramesPage(game: game)),
        );
        await _reloadSelectedFrame();
        break;
      case 'open_journal':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => JournalPage(game: game)));
        break;
      case 'open_stats':
        _showActionMessage(context, 'Abrir estadísticas');
        break;
      case 'memory_inspector':
        if (!_gameController.isAttached) {
          _showActionMessage(context, 'El emulador todavía no está listo.');
          break;
        }

        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => MemoryInspectorPage(controller: _gameController),
          ),
        );
        break;
      case 'settings':
        await _openEmulatorSettings(context);
        break;
      case 'exit':
        await _requestExit(context);
        break;
    }
  }

  Future<void> _openEmulatorSettings(BuildContext context) async {
    final PokemonGameProfile pokemonProfile =
        PokemonGameProfile.fromGameIdentity(
          gameTitle: game.title,
          romPath: game.romPath,
        );

    final preferences = await Navigator.of(context).push<EmulatorPreferences>(
      MaterialPageRoute(
        builder: (_) => EmulatorSettingsPage(
          gameTitle: game.title,
          supportsGameBoyOptions:
              CoreLoader.isGameBoyRom(game.romPath) ||
              CoreLoader.isGbaRom(game.romPath),
          supportsSnesOptions: CoreLoader.isSnesRom(game.romPath),
          supportsNdsOptions: CoreLoader.isNdsRom(game.romPath),
          supportsGbaFullscreen: CoreLoader.isGbaRom(game.romPath),
          supportsGameBoyFullscreen: CoreLoader.isGameBoyRom(game.romPath),
          initialPreferences: _preferences,
          saveStateService: SaveStateService(
            gameId: game.id,
            romPath: game.romPath,
          ),
          specialEventsSubtitle: switch (pokemonProfile.version) {
            PokemonGameVersion.crystal => 'GS Ball · Celebi',
            PokemonGameVersion.ruby || PokemonGameVersion.sapphire =>
              'Ticket Eón · Latias/Latios',
            PokemonGameVersion.emerald =>
              'Mew, Deoxys, Lugia, Ho-Oh y Pokémon Eón',
            PokemonGameVersion.fireRed || PokemonGameVersion.leafGreen =>
              'Deoxys, Lugia y Ho-Oh',
            _ => 'Eventos oficiales',
          },
          onOpenSpecialEvents:
              _supportsSpecialEvents(pokemonProfile.version)
              ? () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => SpecialEventsPage(
                        version: pokemonProfile.version,
                        inspectGsBall: _gameController.inspectGsBall,
                        activateGsBall: _gameController.activateGsBall,
                        inspectGen3Event: _gameController.inspectGen3Event,
                        activateGen3Event: _gameController.activateGen3Event,
                      ),
                    ),
                  );
                }
              : null,
          onRestart: _gameController.restart,
          onSaveState: (slot, title) async {
            final saved = await _gameController.saveState(
              slot: slot,
              title: title,
            );
            if (saved) {
              await _journalEventService.logSaveState(
                slot: slot,
                title: title,
                playTimeMinutes: _currentPlayTimeMinutes,
              );
            }
            return saved;
          },
          onLoadState: (slot) async {
            final loaded = await _gameController.loadState(slot);
            if (loaded) {
              await _journalEventService.logLoadState(
                slot: slot,
                playTimeMinutes: _currentPlayTimeMinutes,
              );
            }
            return loaded;
          },
        ),
      ),
    );
    if (preferences != null && mounted) {
      setState(() => _preferences = preferences);
      await _applyDisplayPreferences(preferences);
    }
  }

  bool _supportsSpecialEvents(PokemonGameVersion version) {
    return version == PokemonGameVersion.crystal ||
        version == PokemonGameVersion.ruby ||
        version == PokemonGameVersion.sapphire ||
        version == PokemonGameVersion.emerald ||
        version == PokemonGameVersion.fireRed ||
        version == PokemonGameVersion.leafGreen;
  }

  Future<void> _requestExit(BuildContext context) async {
    if (_isClosing || _exitDialogOpen) return;
    _exitDialogOpen = true;

    final visualTheme = _EmulatorVisualTheme.forGame(game);
    final cloudAvailable = ref.read(authUserProvider).value != null;
    final exitAction = await showDialog<_ExitGameAction>(
      context: context,
      builder: (dialogContext) => _ExitGameDialog(
        game: game,
        accent: visualTheme.accent,
        partySpeciesIds: _partySpeciesIds,
        cloudAvailable: cloudAvailable,
      ),
    );
    _exitDialogOpen = false;

    if (exitAction == null ||
        exitAction == _ExitGameAction.keepPlaying ||
        !context.mounted) {
      return;
    }
    await _closeAndPop(
      uploadCloud: exitAction == _ExitGameAction.cloudBackup,
    );
  }

  Future<void> _closeAndPop({required bool uploadCloud}) async {
    if (_isClosing) return;
    final navigator = Navigator.of(this.context);
    final emulatorRoute = ModalRoute.of(this.context);
    final messenger = ScaffoldMessenger.of(this.context);
    setState(() {
      _isClosing = true;
      _allowPop = false;
      _closingStatus = 'Guardando partida local…';
    });

    if (!CoreLoader.isSnesRom(game.romPath) &&
        _preferences.autoSaveOnExit) {
      await _gameController.saveState(
        slot: SaveStateService.autoSaveSlot,
        title: 'Guardado automático',
      );
    }
    await _gameController.saveSram();
    String? cloudError;
    final user = ref.read(authUserProvider).value;
    if (uploadCloud && user != null) {
      if (mounted) {
        setState(() => _closingStatus = 'Subiendo a RetroHub Cloud…');
      }
      try {
        await CloudSaveCoordinator(
          authService: ref.read(googleAuthServiceProvider),
        ).uploadGame(
          gameId: game.id,
          gameTitle: game.title,
          romPath: game.romPath,
          requestAuthorizationIfNeeded: false,
        );
      } catch (error) {
        cloudError = error.toString();
      }
    }
    if (mounted) setState(() => _closingStatus = 'Cerrando juego…');
    final tracker = _pokemonJournalTracker;
    if (tracker != null) await tracker.stop();
    await _logSessionClosed();

    if (!mounted) return;

    await _waitForAppToResume();
    if (!mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    if (emulatorRoute != null && emulatorRoute.isActive) {
      navigator.popUntil((route) => route == emulatorRoute);
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && emulatorRoute.isCurrent) navigator.pop();
    } else {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) navigator.pop();
    }

    if (cloudError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'La partida quedó guardada localmente, pero no se pudo subir a la nube: $cloudError',
          ),
        ),
      );
    }
  }

  Future<void> _waitForAppToResume() async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }

    final completer = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        if (!completer.isCompleted) completer.complete();
        listener.dispose();
      },
    );
    await completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => listener.dispose(),
    );
  }

  Future<void> _openSaveStates(
    BuildContext context, {
    required SaveStatesMode mode,
  }) async {
    final SaveStateService service = SaveStateService(
      gameId: game.id,
      romPath: game.romPath,
    );

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SaveStatesPage(
          gameTitle: game.title,
          mode: mode,
          service: service,
          onSave: (int slot, String title) async {
            final bool saved = await _gameController.saveState(
              slot: slot,
              title: title,
            );

            if (saved) {
              await _journalEventService.logSaveState(
                slot: slot,
                title: title,
                playTimeMinutes: _currentPlayTimeMinutes,
              );
            }

            return saved;
          },
          onLoad: (int slot) async {
            final bool loaded = await _gameController.loadState(slot);

            if (loaded) {
              await _journalEventService.logLoadState(
                slot: slot,
                playTimeMinutes: _currentPlayTimeMinutes,
              );
            }

            return loaded;
          },
          confirmBeforeOverwrite: _preferences.confirmBeforeOverwrite,
        ),
      ),
    );
  }

  void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headerRefreshTimer?.cancel();
    _gameController.resetInput();
    final tracker = _pokemonJournalTracker;
    if (tracker != null) unawaited(tracker.stop());
    unawaited(_logSessionClosed());
    if (_isAndroidSnes) {
      unawaited(
        SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
          DeviceOrientation.portraitUp,
        ]),
      );
    } else {
      unawaited(SystemChrome.setPreferredOrientations(const []));
    }
    unawaited(WakelockPlus.disable());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  Widget _ndsTouchSurface({
    required double width,
    required double height,
  }) {
    void updateTouch(PointerEvent event) {
      _gameController.setTouchState(
        x: ((event.localPosition.dx / width) * 255)
            .round()
            .clamp(0, 255)
            .toInt(),
        y: ((event.localPosition.dy / height) * 191)
            .round()
            .clamp(0, 191)
            .toInt(),
        pressed: true,
      );
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_ndsTouchPointer != null) return;
        _ndsTouchPointer = event.pointer;
        updateTouch(event);
      },
      onPointerMove: (event) {
        if (_ndsTouchPointer != event.pointer) return;
        updateTouch(event);
      },
      onPointerUp: (event) {
        if (_ndsTouchPointer != event.pointer) return;
        _gameController.releaseTouch();
        _ndsTouchPointer = null;
      },
      onPointerCancel: (event) {
        if (_ndsTouchPointer != event.pointer) return;
        _gameController.releaseTouch();
        _ndsTouchPointer = null;
      },
    );
  }

  Widget _buildPortraitCardLayout({
    required BoxConstraints constraints,
    required Widget gameView,
    required PortraitGameFrame frame,
    required bool isGba,
    required bool isGbc,
    required _EmulatorVisualTheme visualTheme,
  }) {
    final isExp = frame.family == PortraitCardFamily.exp;
    final isTrainer = frame.family == PortraitCardFamily.trainer;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final screenRect = Rect.fromLTWH(
      width * (isTrainer ? .075 : (isExp ? .055 : .09)),
      height * (isTrainer ? .135 : (isExp ? .13 : .145)),
      width * (isTrainer ? .85 : (isExp ? .91 : .82)),
      height * (isTrainer ? .315 : (isExp ? .35 : .31)),
    );
    final dpadSize = math.min(38 * _preferences.sizeScale, width * .11);
    final actionSize = math.min(52 * _preferences.sizeScale, width * .15);
    final controlsY = height * (isTrainer ? .55 : .57);
    final consoleLogo = isGba
        ? RetroHubConsoleType.gameBoyAdvance
        : isGbc
            ? RetroHubConsoleType.gameBoyColor
            : RetroHubConsoleType.gameBoy;

    return ColoredBox(
      color: visualTheme.background,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // La imagen del juego va debajo del PNG. El área transparente de la
          // carta actúa como ventana y el borde siempre queda por encima.
          Positioned(
            left: screenRect.left,
            top: screenRect.top,
            width: screenRect.width,
            height: screenRect.height,
            child: ColoredBox(color: Colors.black, child: gameView),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: width,
            height: height,
            child: IgnorePointer(
              child: Image.asset(
                frame.assetPath,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Positioned(
            left: width * .055,
            top: height * .025,
            width: width * .16,
            height: height * .09,
            child: ClipOval(
              child: _GameArtwork(
                coverPath: CoverHelper.getCover(game.title, game.console),
                accent: visualTheme.accent,
                width: width * .16,
                height: height * .09,
                iconSize: 18,
              ),
            ),
          ),
          Positioned(
            left: width * .21,
            width: width * .60,
            top: height * .035,
            height: height * .07,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: _PartySprites(
                game: game,
                speciesIds: _partySpeciesIds,
                accent: visualTheme.accent,
              ),
            ),
          ),
          Positioned(
            right: width * .035,
            top: height * .025,
            child: Transform.scale(
              scale: .82,
              child: RetroHubQuickMenu(
                onAction: (value) => _handleMenuAction(context, value),
              ),
            ),
          ),
          Positioned(
            left: width * .055,
            top: controlsY,
            child: Opacity(
              opacity: _preferences.controlOpacity,
              child: _DirectionalControl(
                type: _preferences.directionalControl,
                keySize: dpadSize,
                controller: _gameController,
                buttonUp: _buttonUp,
                buttonDown: _buttonDown,
                buttonLeft: _buttonLeft,
                buttonRight: _buttonRight,
              ),
            ),
          ),
          Positioned(
            right: width * .055,
            top: controlsY + dpadSize * .45,
            child: Opacity(
              opacity: _preferences.controlOpacity,
              child: Row(
                children: [
                  _GameBoyActionButton(
                    size: actionSize,
                    label: _preferences.swapAB ? 'A' : 'B',
                    buttonId: _preferences.swapAB ? _buttonA : _buttonB,
                    controller: _gameController,
                  ),
                  SizedBox(width: width * .025),
                  _GameBoyActionButton(
                    size: actionSize,
                    label: _preferences.swapAB ? 'B' : 'A',
                    buttonId: _preferences.swapAB ? _buttonB : _buttonA,
                    controller: _gameController,
                  ),
                ],
              ),
            ),
          ),
          if (isGba) ...[
            Positioned(
              left: width * .08,
              top: height * .50,
              child: _GameBoyShoulderButton(
                label: 'L',
                buttonId: _buttonL,
                controller: _gameController,
              ),
            ),
            Positioned(
              right: width * .08,
              top: height * .50,
              child: _GameBoyShoulderButton(
                label: 'R',
                buttonId: _buttonR,
                controller: _gameController,
              ),
            ),
          ],
          Positioned(
            left: width * .20,
            right: width * .20,
            top: height * .755,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GameBoySystemButton(
                  width: 68,
                  height: 27,
                  label: 'SELECT',
                  buttonId: _buttonSelect,
                  controller: _gameController,
                ),
                _GameBoySystemButton(
                  width: 68,
                  height: 27,
                  label: 'START',
                  buttonId: _buttonStart,
                  controller: _gameController,
                ),
              ],
            ),
          ),
          Positioned(
            left: width * .055,
            right: width * .055,
            top: height * .835,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (CoreLoader.isGameBoyRom(game.romPath))
                  _LinkStatusChip(linkManager: _gameController.linkManager)
                else
                  const SizedBox(width: 92),
                SizedBox(
                  width: 92,
                  height: 32,
                  child: SpeedButton(
                    speedMultiplier: _gameController.speedMultiplier,
                    onTap: _gameController.cycleSpeed,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: width * .25,
            right: width * .25,
            top: height * .47,
            height: height * .075,
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RetroHubConsoleLogo(console: consoleLogo),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EmulationCore core = CoreLoader.coreForRom(game.romPath);
    final String? corePath = CoreLoader.findCorePath(game.romPath);
    final bool isGba = CoreLoader.isGbaRom(game.romPath);
    final bool isSnes = CoreLoader.isSnesRom(game.romPath);
    final bool isNds = CoreLoader.isNdsRom(game.romPath);
    final bool isGbc =
        game.console.toLowerCase().contains('gbc') ||
        game.console.toLowerCase().contains('game boy color');
    final bool pageLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final bool portraitCardActive =
        !pageLandscape && _selectedPortraitFrame != null;
    final _EmulatorVisualTheme visualTheme = _EmulatorVisualTheme.forGame(game);
    final bool snesFullscreen = isSnes && _preferences.snesFullscreen;
    final bool gbaFullscreen = isGba && _preferences.gbaFullscreen;
    final bool gameBoyFullscreen =
        CoreLoader.isGameBoyRom(game.romPath) &&
        _preferences.gameBoyFullscreen;
    final bool ndsFullscreen = isNds && _preferences.ndsFullscreen;
    final bool consoleFullscreen =
        snesFullscreen || gbaFullscreen || gameBoyFullscreen || ndsFullscreen;
    final bool borderlessGameSurface =
        consoleFullscreen || portraitCardActive;
    _gameController.hapticsEnabled = !isSnes &&
        (isNds
            ? _preferences.ndsVibrationEnabled
            : _preferences.vibrationEnabled);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestExit(context));
      },
      child: Scaffold(
        backgroundColor: visualTheme.background,
        appBar: consoleFullscreen || portraitCardActive ? null : AppBar(
          toolbarHeight: 58,
          backgroundColor: visualTheme.appBar,
          foregroundColor: Colors.white,
          titleSpacing: 4,
          title: _EmulatorHeader(
            game: game,
            accent: visualTheme.accent,
            partySpeciesIds: _partySpeciesIds,
          ),
        ),
        body: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(gradient: visualTheme.gradient),
              child: SafeArea(
                top: portraitCardActive,
                left: !consoleFullscreen,
                right: !consoleFullscreen,
                bottom: !consoleFullscreen,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool landscape =
                        constraints.maxWidth > constraints.maxHeight;
                    final double padding = landscape ? 8 : 14;
                    final double ndsMiddleControlsHeight = math.max(
                      30 * _preferences.ndsShoulderScale,
                      25 * _preferences.ndsSystemScale,
                    );
                    const double ndsPortraitScreenGap = 4;

                    final Widget gameView = Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(
                          borderlessGameSurface ? 0 : 18,
                        ),
                        border: borderlessGameSurface ? null : Border.all(
                          color: corePath != null
                              ? visualTheme.accent
                              : Theme.of(context).colorScheme.error,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          borderlessGameSurface ? 0 : 15,
                        ),
                        child: corePath != null
                            ? LibretroGameView(
                                key: _gameViewKey,
                                gameId: game.id,
                                gameTitle: game.title,
                                corePath: corePath,
                                romPath: game.romPath,
                                initialPlayTimeMinutes:
                                    game.playTimeSeconds ~/ 60,
                                controller: _gameController,
                                screenFit: switch (_preferences.screenScale) {
                                  EmulatorScreenScale.aspectRatio =>
                                    BoxFit.contain,
                                  EmulatorScreenScale.fitWidth => BoxFit.fitWidth,
                                  EmulatorScreenScale.stretch => BoxFit.fill,
                                },
                                filterQuality: _preferences.screenFilter ==
                                        EmulatorScreenFilter.pixel
                                    ? FilterQuality.none
                                    : FilterQuality.medium,
                                autoLoadState:
                                    _preferences.autoLoadOnStart && !isSnes,
                                displayAspectRatio: isSnes ? 4 / 3 : null,
                                splitNdsScreens: isNds,
                                ndsTopScreenScale: isNds
                                    ? _ndsTopScreenScale(_preferences)
                                    : 1,
                                ndsBottomScreenScale: isNds
                                    ? _ndsBottomScreenScale(_preferences)
                                    : 1,
                                ndsSwapScreens: isNds && _preferences.ndsSwapScreens,
                                ndsScreensScale: isNds && landscape
                                    ? (ndsFullscreen
                                        ? 1
                                        : _preferences.ndsScreensScale)
                                    : 1,
                                ndsHorizontalLayout: isNds && landscape,
                                ndsScreenGap: isNds && !landscape
                                    ? ndsPortraitScreenGap
                                    : 4,
                              )
                            : _CoreNotFoundView(
                                romPath: game.romPath,
                                core: core,
                              ),
                      ),
                    );

                    final selectedFrame = _selectedFrame;
                    if (consoleFullscreen &&
                        landscape &&
                        selectedFrame != null) {
                      final scale = math.min(
                        constraints.maxWidth / 1280,
                        constraints.maxHeight / 720,
                      );
                      final frameWidth = 1280 * scale;
                      final frameHeight = 720 * scale;
                      final frameLeft = (constraints.maxWidth - frameWidth) / 2;
                      final frameTop = (constraints.maxHeight - frameHeight) / 2;
                      final viewportLeft = frameLeft +
                          frameWidth * selectedFrame.viewportLeft;
                      final viewportTop = frameTop +
                          frameHeight * selectedFrame.viewportTop;
                      final viewportWidth =
                          frameWidth * selectedFrame.viewportWidth;
                      final viewportHeight =
                          frameHeight * selectedFrame.viewportHeight;
                      final leftControlsWidth = math.max(132.0, viewportLeft);
                      final rightControlsWidth = math.max(
                        150.0,
                        constraints.maxWidth -
                            (viewportLeft + viewportWidth),
                      );
                      final showShoulders = isSnes || isGba;
                      final consoleLogo = isSnes
                          ? RetroHubConsoleType.superNintendo
                          : isGba
                              ? RetroHubConsoleType.gameBoyAdvance
                              : isGbc
                                  ? RetroHubConsoleType.gameBoyColor
                                  : RetroHubConsoleType.gameBoy;

                      return ColoredBox(
                        color: Color(selectedFrame.backgroundColorValue),
                        child: Stack(
                          children: [
                            Positioned(
                              left: viewportLeft,
                              top: viewportTop,
                              width: viewportWidth,
                              height: viewportHeight,
                              child: ColoredBox(
                                color: Colors.black,
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: selectedFrame.gameAspectRatio,
                                    child: gameView,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: frameLeft,
                              top: frameTop,
                              width: frameWidth,
                              height: frameHeight,
                              child: IgnorePointer(
                                child: Image.asset(
                                  selectedFrame.assetPath,
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.none,
                                ),
                              ),
                            ),
                            Positioned(
                              left: viewportLeft,
                              top: viewportTop,
                              width: viewportWidth,
                              height: viewportHeight,
                              child: _FullscreenPartyOverlay(
                                game: game,
                                speciesIds: _partySpeciesIds,
                                accent: visualTheme.accent,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: leftControlsWidth,
                              child: Opacity(
                                opacity: _preferences.controlOpacity,
                                child: _LandscapeLeftControls(
                                  controller: _gameController,
                                  directionalControl:
                                      _preferences.directionalControl,
                                  buttonUp: _buttonUp,
                                  buttonDown: _buttonDown,
                                  buttonLeft: _buttonLeft,
                                  buttonRight: _buttonRight,
                                  buttonSelect: _buttonSelect,
                                  buttonL: _buttonL,
                                  showShoulder: showShoulders,
                                  consoleLogo: consoleLogo,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: rightControlsWidth,
                              child: Opacity(
                                opacity: _preferences.controlOpacity,
                                child: _LandscapeRightControls(
                                  controller: _gameController,
                                  buttonA: _preferences.swapAB
                                      ? _buttonB
                                      : _buttonA,
                                  buttonB: _preferences.swapAB
                                      ? _buttonA
                                      : _buttonB,
                                  buttonX: _buttonX,
                                  buttonY: _buttonY,
                                  buttonStart: _buttonStart,
                                  buttonR: _buttonR,
                                  showShoulder: showShoulders,
                                  isSnes: isSnes,
                                  rotateActions: !isSnes,
                                  buttonAColor: isSnes
                                      ? Color(_preferences.snesButtonAColor)
                                      : const Color(0xFF5E4B8B),
                                  buttonBColor: isSnes
                                      ? Color(_preferences.snesButtonBColor)
                                      : const Color(0xFF8173AE),
                                  buttonXColor: isSnes
                                      ? Color(_preferences.snesButtonXColor)
                                      : const Color(0xFF8173AE),
                                  buttonYColor: isSnes
                                      ? Color(_preferences.snesButtonYColor)
                                      : const Color(0xFF5E4B8B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snesFullscreen && landscape) {
                      final gameWidth = (constraints.maxHeight * 4 / 3)
                          .clamp(0.0, constraints.maxWidth)
                          .toDouble();
                      final sideWidth =
                          ((constraints.maxWidth - gameWidth) / 2)
                              .clamp(0.0, constraints.maxWidth / 2)
                              .toDouble();
                      return ColoredBox(
                        color: const Color(0xFFC8C7CC),
                        child: Row(
                          children: [
                            SizedBox(
                              width: sideWidth,
                              child: _SnesSidePanel(
                                isLeft: true,
                                opacity: _preferences.controlOpacity,
                                child: _LandscapeLeftControls(
                                  controller: _gameController,
                                  directionalControl:
                                      _preferences.directionalControl,
                                  buttonUp: _buttonUp,
                                  buttonDown: _buttonDown,
                                  buttonLeft: _buttonLeft,
                                  buttonRight: _buttonRight,
                                  buttonSelect: _buttonSelect,
                                  buttonL: _buttonL,
                                  showShoulder: true,
                                  consoleLogo:
                                      RetroHubConsoleType.superNintendo,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: gameWidth,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: gameView),
                                  Positioned.fill(
                                    child: _FullscreenPartyOverlay(
                                      game: game,
                                      speciesIds: _partySpeciesIds,
                                      accent: visualTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: sideWidth,
                              child: _SnesSidePanel(
                                isLeft: false,
                                opacity: _preferences.controlOpacity,
                                child: _LandscapeRightControls(
                                  controller: _gameController,
                                  buttonA: _buttonA,
                                  buttonB: _buttonB,
                                  buttonX: _buttonX,
                                  buttonY: _buttonY,
                                  buttonStart: _buttonStart,
                                  buttonR: _buttonR,
                                  showShoulder: true,
                                  isSnes: true,
                                  buttonAColor:
                                      Color(_preferences.snesButtonAColor),
                                  buttonBColor:
                                      Color(_preferences.snesButtonBColor),
                                  buttonXColor:
                                      Color(_preferences.snesButtonXColor),
                                  buttonYColor:
                                      Color(_preferences.snesButtonYColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (gbaFullscreen && landscape) {
                      final gameWidth = (constraints.maxHeight * 3 / 2)
                          .clamp(0.0, constraints.maxWidth)
                          .toDouble();
                      final sideWidth =
                          ((constraints.maxWidth - gameWidth) / 2)
                              .clamp(0.0, constraints.maxWidth / 2)
                              .toDouble();
                      return ColoredBox(
                        color: visualTheme.background,
                        child: Row(
                          children: [
                            SizedBox(
                              width: sideWidth,
                              child: _SnesSidePanel(
                                isLeft: true,
                                opacity: _preferences.controlOpacity,
                                topColor: visualTheme.background,
                                bottomColor: visualTheme.gradient.colors[2],
                                borderColor: visualTheme.accent.withValues(
                                  alpha: .55,
                                ),
                                child: _LandscapeLeftControls(
                                  controller: _gameController,
                                  directionalControl:
                                      _preferences.directionalControl,
                                  buttonUp: _buttonUp,
                                  buttonDown: _buttonDown,
                                  buttonLeft: _buttonLeft,
                                  buttonRight: _buttonRight,
                                  buttonSelect: _buttonSelect,
                                  buttonL: _buttonL,
                                  showShoulder: true,
                                  consoleLogo:
                                      RetroHubConsoleType.gameBoyAdvance,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: gameWidth,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: gameView),
                                  Positioned.fill(
                                    child: _FullscreenPartyOverlay(
                                      game: game,
                                      speciesIds: _partySpeciesIds,
                                      accent: visualTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: sideWidth,
                              child: _SnesSidePanel(
                                isLeft: false,
                                opacity: _preferences.controlOpacity,
                                topColor: visualTheme.background,
                                bottomColor: visualTheme.gradient.colors[2],
                                borderColor: visualTheme.accent.withValues(
                                  alpha: .55,
                                ),
                                child: _LandscapeRightControls(
                                  controller: _gameController,
                                  buttonA: _preferences.swapAB
                                      ? _buttonB
                                      : _buttonA,
                                  buttonB: _preferences.swapAB
                                      ? _buttonA
                                      : _buttonB,
                                  buttonX: _buttonX,
                                  buttonY: _buttonY,
                                  buttonStart: _buttonStart,
                                  buttonR: _buttonR,
                                  showShoulder: true,
                                  isSnes: false,
                                  rotateActions: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (gameBoyFullscreen && landscape) {
                      final gameWidth = (constraints.maxHeight * 10 / 9)
                          .clamp(0.0, constraints.maxWidth)
                          .toDouble();
                      final sideWidth =
                          ((constraints.maxWidth - gameWidth) / 2)
                              .clamp(0.0, constraints.maxWidth / 2)
                              .toDouble();
                      final consoleLogo = isGbc
                          ? RetroHubConsoleType.gameBoyColor
                          : RetroHubConsoleType.gameBoy;
                      return ColoredBox(
                        color: visualTheme.background,
                        child: Row(
                          children: [
                            SizedBox(
                              width: sideWidth,
                              child: _SnesSidePanel(
                                isLeft: true,
                                opacity: _preferences.controlOpacity,
                                topColor: visualTheme.background,
                                bottomColor: visualTheme.gradient.colors[2],
                                borderColor: visualTheme.accent.withValues(
                                  alpha: .55,
                                ),
                                child: _LandscapeLeftControls(
                                  controller: _gameController,
                                  directionalControl:
                                      _preferences.directionalControl,
                                  buttonUp: _buttonUp,
                                  buttonDown: _buttonDown,
                                  buttonLeft: _buttonLeft,
                                  buttonRight: _buttonRight,
                                  buttonSelect: _buttonSelect,
                                  buttonL: _buttonL,
                                  showShoulder: false,
                                  consoleLogo: consoleLogo,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: gameWidth,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: gameView),
                                  Positioned.fill(
                                    child: _FullscreenPartyOverlay(
                                      game: game,
                                      speciesIds: _partySpeciesIds,
                                      accent: visualTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: sideWidth,
                              child: _SnesSidePanel(
                                isLeft: false,
                                opacity: _preferences.controlOpacity,
                                topColor: visualTheme.background,
                                bottomColor: visualTheme.gradient.colors[2],
                                borderColor: visualTheme.accent.withValues(
                                  alpha: .55,
                                ),
                                child: _LandscapeRightControls(
                                  controller: _gameController,
                                  buttonA: _preferences.swapAB
                                      ? _buttonB
                                      : _buttonA,
                                  buttonB: _preferences.swapAB
                                      ? _buttonA
                                      : _buttonB,
                                  buttonX: _buttonX,
                                  buttonY: _buttonY,
                                  buttonStart: _buttonStart,
                                  buttonR: _buttonR,
                                  showShoulder: false,
                                  isSnes: false,
                                  rotateActions: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (landscape && isNds) {
                      const double leftControlsWidth = 154;
                      const double rightControlsWidth = 174;
                      final double topFactor =
                          _ndsTopScreenScale(_preferences);
                      final double bottomFactor =
                          _ndsBottomScreenScale(_preferences);
                      final double controlOpacity =
                          _preferences.ndsControlOpacity;

                      return Padding(
                        padding: ndsFullscreen
                            ? EdgeInsets.zero
                            : EdgeInsets.symmetric(
                                horizontal: padding,
                                vertical: 4,
                              ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, stageConstraints) {
                                  final destinations =
                                      _ndsHorizontalDestinations(
                                    Size(
                                      stageConstraints.maxWidth,
                                      stageConstraints.maxHeight,
                                    ),
                                    topScreenScale: topFactor,
                                    bottomScreenScale: bottomFactor,
                                    screensScale: ndsFullscreen
                                        ? 1
                                        : _preferences.ndsScreensScale,
                                  );
                                  final touchRect =
                                      _preferences.ndsSwapScreens
                                          ? destinations.$1
                                          : destinations.$2;
                                  final overlayRect = destinations.$2;
                                  return Stack(
                                    children: [
                                      Positioned.fill(child: gameView),
                                      Positioned.fromRect(
                                        rect: touchRect,
                                        child: _ndsTouchSurface(
                                          width: touchRect.width,
                                          height: touchRect.height,
                                        ),
                                      ),
                                      if (ndsFullscreen)
                                        Positioned.fromRect(
                                          rect: overlayRect,
                                          child: _FullscreenPartyOverlay(
                                            game: game,
                                            speciesIds: _partySpeciesIds,
                                            accent: visualTheme.accent,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: leftControlsWidth,
                              child: Opacity(
                                opacity: controlOpacity,
                                child: _LandscapeLeftControls(
                                  controller: _gameController,
                                  directionalControl:
                                      _preferences.ndsDirectionalControl,
                                  buttonUp: _buttonUp,
                                  buttonDown: _buttonDown,
                                  buttonLeft: _buttonLeft,
                                  buttonRight: _buttonRight,
                                  buttonSelect: _buttonSelect,
                                  buttonL: _buttonL,
                                  showShoulder: true,
                                  consoleLogo:
                                      RetroHubConsoleType.nintendoDs,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: rightControlsWidth,
                              child: Opacity(
                                opacity: controlOpacity,
                                child: _LandscapeRightControls(
                                  controller: _gameController,
                                  buttonA: _preferences.ndsSwapAB
                                      ? _buttonB
                                      : _buttonA,
                                  buttonB: _preferences.ndsSwapAB
                                      ? _buttonA
                                      : _buttonB,
                                  buttonX: _buttonX,
                                  buttonY: _buttonY,
                                  buttonStart: _buttonStart,
                                  buttonR: _buttonR,
                                  showShoulder: true,
                                  isSnes: true,
                                  buttonAColor: visualTheme.accent,
                                  buttonBColor: Color.lerp(
                                    visualTheme.accent,
                                    visualTheme.background,
                                    .28,
                                  )!,
                                  buttonXColor: Color.lerp(
                                    visualTheme.accent,
                                    Colors.white,
                                    .22,
                                  )!,
                                  buttonYColor: Color.lerp(
                                    visualTheme.accent,
                                    visualTheme.gradient.colors[2],
                                    .48,
                                  )!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (landscape) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 138,
                              child: _LandscapeLeftControls(
                                controller: _gameController,
                                directionalControl: isNds
                                    ? _preferences.ndsDirectionalControl
                                    : _preferences.directionalControl,
                                buttonUp: _buttonUp,
                                buttonDown: _buttonDown,
                                buttonLeft: _buttonLeft,
                                buttonRight: _buttonRight,
                                buttonSelect: _buttonSelect,
                                buttonL: _buttonL,
                                showShoulder: isGba || isSnes || isNds,
                                consoleLogo: isNds
                                    ? RetroHubConsoleType.nintendoDs
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: isSnes
                                      ? 4 / 3
                                      : isGba
                                      ? 3 / 2
                                      : isNds
                                      ? 1 / 1.305
                                      : 10 / 9,
                                  child: gameView,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 166,
                              child: _LandscapeRightControls(
                                controller: _gameController,
                                buttonA: isNds && _preferences.ndsSwapAB
                                    ? _buttonB
                                    : _buttonA,
                                buttonB: isNds && _preferences.ndsSwapAB
                                    ? _buttonA
                                    : _buttonB,
                                buttonX: _buttonX,
                                buttonY: _buttonY,
                                buttonStart: _buttonStart,
                                buttonR: _buttonR,
                                showShoulder: isGba || isSnes || isNds,
                                isSnes: isSnes || isNds,
                                buttonAColor: isNds
                                    ? visualTheme.accent
                                    : Color(_preferences.snesButtonAColor),
                                buttonBColor: isNds
                                    ? Color.lerp(visualTheme.accent, visualTheme.background, .28)!
                                    : Color(_preferences.snesButtonBColor),
                                buttonXColor: isNds
                                    ? Color.lerp(visualTheme.accent, Colors.white, .22)!
                                    : Color(_preferences.snesButtonXColor),
                                buttonYColor: isNds
                                    ? Color.lerp(visualTheme.accent, visualTheme.gradient.colors[2], .48)!
                                    : Color(_preferences.snesButtonYColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (isNds) {
                      final double topFactor = _ndsTopScreenScale(_preferences);
                      final double bottomFactor = _ndsBottomScreenScale(_preferences);
                      final double layoutWidth =
                          constraints.maxWidth * _preferences.ndsScreensScale;
                      final double topWidth = layoutWidth * topFactor;
                      final double bottomWidth = layoutWidth * bottomFactor;
                      final double topHeight = topWidth / (4 / 3);
                      final double bottomHeight = bottomWidth / (4 / 3);
                      final double screenGap = ndsPortraitScreenGap;
                      final double screenHeight =
                          topHeight + bottomHeight + screenGap;
                      final double screenLeft =
                          (constraints.maxWidth - layoutWidth) / 2;
                      final bool touchIsTop = _preferences.ndsSwapScreens;
                      final double touchScreenTop = touchIsTop
                          ? 0
                          : topHeight + screenGap;
                      final double touchScreenWidth =
                          touchIsTop ? topWidth : bottomWidth;
                      final double touchScreenHeight =
                          touchIsTop ? topHeight : bottomHeight;
                      final double touchScreenLeft =
                          (constraints.maxWidth - touchScreenWidth) / 2;
                      final double shoulderRowTop = topHeight +
                          (screenGap - ndsMiddleControlsHeight) / 2;
                      final double logoTop = screenHeight + 6;
                      final double mainControlsTop = logoTop;
                      final double controlOpacity = _preferences.ndsControlOpacity;
                      final Color ndsA = visualTheme.accent;
                      final Color ndsB = Color.lerp(visualTheme.accent, visualTheme.background, .28)!;
                      final Color ndsX = Color.lerp(visualTheme.accent, Colors.white, .22)!;
                      final Color ndsY = Color.lerp(visualTheme.accent, visualTheme.gradient.colors[2], .48)!;

                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            top: 0,
                            left: screenLeft,
                            width: layoutWidth,
                            height: screenHeight,
                            child: gameView,
                          ),
                          Positioned(
                            top: touchScreenTop,
                            left: touchScreenLeft,
                            width: touchScreenWidth,
                            height: touchScreenHeight,
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (PointerDownEvent event) {
                                if (_ndsTouchPointer != null) return;
                                _ndsTouchPointer = event.pointer;
                                _gameController.setTouchState(
                                  x: ((event.localPosition.dx /
                                              touchScreenWidth) *
                                          255)
                                      .round()
                                      .clamp(0, 255)
                                      .toInt(),
                                  y: ((event.localPosition.dy /
                                              touchScreenHeight) *
                                          191)
                                      .round()
                                      .clamp(0, 191)
                                      .toInt(),
                                  pressed: true,
                                );
                              },
                              onPointerMove: (PointerMoveEvent event) {
                                if (_ndsTouchPointer != event.pointer) return;
                                _gameController.setTouchState(
                                  x: ((event.localPosition.dx /
                                              touchScreenWidth) *
                                          255)
                                      .round()
                                      .clamp(0, 255)
                                      .toInt(),
                                  y: ((event.localPosition.dy /
                                              touchScreenHeight) *
                                          191)
                                      .round()
                                      .clamp(0, 191)
                                      .toInt(),
                                  pressed: true,
                                );
                              },
                              onPointerUp: (PointerUpEvent event) {
                                if (_ndsTouchPointer != event.pointer) return;
                                _gameController.releaseTouch();
                                _ndsTouchPointer = null;
                              },
                              onPointerCancel: (PointerCancelEvent event) {
                                if (_ndsTouchPointer != event.pointer) return;
                                _gameController.releaseTouch();
                                _ndsTouchPointer = null;
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 10,
                            child: Opacity(
                              opacity: .72,
                              child: SizedBox(
                                width: 92,
                                height: 32,
                                child: SpeedButton(
                                  speedMultiplier:
                                      _gameController.speedMultiplier,
                                  onTap: _gameController.cycleSpeed,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 10,
                            child: Opacity(
                              opacity: .68,
                              child: RetroHubQuickMenu(
                                onAction: (String value) =>
                                    _handleMenuAction(context, value),
                              ),
                            ),
                          ),
                          Positioned(
                            top: shoulderRowTop,
                            left: 10,
                            right: 10,
                            child: Opacity(
                              opacity: controlOpacity,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Transform.scale(
                                    scale: _preferences.ndsShoulderScale,
                                    child: _GameBoyShoulderButton(label: 'L', buttonId: _buttonL, controller: _gameController),
                                  ),
                                  Transform.scale(
                                    scale: _preferences.ndsSystemScale,
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      _GameBoySystemButton(width: 64, height: 25, label: 'SELECT', buttonId: _buttonSelect, controller: _gameController),
                                      const SizedBox(width: 8),
                                      _GameBoySystemButton(width: 64, height: 25, label: 'START', buttonId: _buttonStart, controller: _gameController),
                                    ]),
                                  ),
                                  Transform.scale(
                                    scale: _preferences.ndsShoulderScale,
                                    child: _GameBoyShoulderButton(label: 'R', buttonId: _buttonR, controller: _gameController),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: mainControlsTop,
                            left: 12,
                            right: 12,
                            child: Opacity(
                              opacity: controlOpacity,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Transform.translate(
                                    offset: Offset(_preferences.ndsDpadX * 28, _preferences.ndsDpadY * 24),
                                    child: _DirectionalControl(
                                      type: _preferences.ndsDirectionalControl,
                                      keySize: 36 * _preferences.ndsDpadScale,
                                      controller: _gameController,
                                      buttonUp: _buttonUp,
                                      buttonDown: _buttonDown,
                                      buttonLeft: _buttonLeft,
                                      buttonRight: _buttonRight,
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(_preferences.ndsActionX * 28, _preferences.ndsActionY * 24),
                                    child: _SnesActionPad(
                                      size: 38 * _preferences.ndsActionScale,
                                      controller: _gameController,
                                      buttonA: _preferences.ndsSwapAB ? _buttonB : _buttonA,
                                      buttonB: _preferences.ndsSwapAB ? _buttonA : _buttonB,
                                      buttonX: _buttonX,
                                      buttonY: _buttonY,
                                      buttonAColor: ndsA,
                                      buttonBColor: ndsB,
                                      buttonXColor: ndsX,
                                      buttonYColor: ndsY,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: logoTop,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: RetroHubConsoleLogo(
                                    console: RetroHubConsoleType.nintendoDs,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final portraitFrame = _selectedPortraitFrame;
                    if (portraitFrame != null && !isSnes) {
                      return _buildPortraitCardLayout(
                        constraints: constraints,
                        gameView: gameView,
                        frame: portraitFrame,
                        isGba: isGba,
                        isGbc: isGbc,
                        visualTheme: visualTheme,
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        children: [
                          if (!isSnes) ...[
                            SizedBox(
                              height: 54,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 92,
                                      height: 32,
                                      child: SpeedButton(
                                        speedMultiplier:
                                            _gameController.speedMultiplier,
                                        onTap: _gameController.cycleSpeed,
                                      ),
                                    ),
                                  ),
                                  if (CoreLoader.isGameBoyRom(game.romPath))
                                    Align(
                                      alignment: Alignment.center,
                                      child: _LinkStatusChip(
                                        linkManager:
                                            _gameController.linkManager,
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: RetroHubQuickMenu(
                                      onAction: (String value) =>
                                          _handleMenuAction(context, value),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Flexible(
                            fit: FlexFit.loose,
                            child: AspectRatio(
                              aspectRatio: isSnes
                                  ? 4 / 3
                                  : isGba
                                  ? 3 / 2
                                  : isNds
                                  ? 1 / 1.305
                                  : 10 / 9,
                              child: gameView,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (!isSnes &&
                              isGba &&
                              _preferences.layout ==
                                  GameBoyControlLayout.classic)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _GameBoyShoulderButton(
                                  label: 'L',
                                  buttonId: _buttonL,
                                  controller: _gameController,
                                ),
                                if (_preferences.showConsoleIdentity)
                                  const RetroHubConsoleLogo(
                                    console: RetroHubConsoleType.gameBoyAdvance,
                                  )
                                else
                                  const Spacer(),
                                _GameBoyShoulderButton(
                                  label: 'R',
                                  buttonId: _buttonR,
                                  controller: _gameController,
                                ),
                              ],
                            )
                          else if (!isNds &&
                              (isSnes || _preferences.showConsoleIdentity))
                            RetroHubConsoleLogo(
                              console: isSnes
                                  ? RetroHubConsoleType.superNintendo
                                  : isNds
                                  ? RetroHubConsoleType.nintendoDs
                                  : isGba
                                  ? RetroHubConsoleType.gameBoyAdvance
                                  : isGbc
                                  ? RetroHubConsoleType.gameBoyColor
                                  : RetroHubConsoleType.gameBoy,
                            ),
                          SizedBox(
                            height: isNds ||
                                    (!isSnes &&
                                        !isGba &&
                                        !_preferences.showConsoleIdentity)
                                ? 2
                                : 10,
                          ),

                          _GameBoyControls(
                            compact: false,
                            classicLayout: !isSnes &&
                                _preferences.layout ==
                                    GameBoyControlLayout.classic,
                            sizeScale: isSnes ? 1 : _preferences.sizeScale,
                            opacity: _preferences.controlOpacity,
                            swapLabels:
                                !isSnes && !isNds && _preferences.swapAB,
                            controller: _gameController,
                            directionalControl:
                                _preferences.directionalControl,
                            buttonUp: _buttonUp,
                            buttonDown: _buttonDown,
                            buttonLeft: _buttonLeft,
                            buttonRight: _buttonRight,
                            buttonA: !isSnes &&
                                    !isNds &&
                                    _preferences.swapAB
                                ? _buttonB
                                : _buttonA,
                            buttonB: !isSnes &&
                                    !isNds &&
                                    _preferences.swapAB
                                ? _buttonA
                                : _buttonB,
                            buttonX: _buttonX,
                            buttonY: _buttonY,
                            buttonSelect: _buttonSelect,
                            buttonStart: _buttonStart,
                            buttonL: _buttonL,
                            buttonR: _buttonR,
                            showShoulder: isSnes ||
                                isNds ||
                                (isGba &&
                                    _preferences.layout !=
                                        GameBoyControlLayout.classic),
                            isSnes: isSnes || isNds,
                            buttonAColor:
                                Color(_preferences.snesButtonAColor),
                            buttonBColor:
                                Color(_preferences.snesButtonBColor),
                            buttonXColor:
                                Color(_preferences.snesButtonXColor),
                            buttonYColor:
                                Color(_preferences.snesButtonYColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (isSnes || pageLandscape)
              Positioned(
                top: 8,
                right: 14,
                child: RetroHubQuickMenu(
                  onAction: (String value) =>
                      _handleMenuAction(context, value),
                ),
              ),
            if (isSnes || pageLandscape)
              Positioned(
                top: 62,
                right: 14,
                child: SpeedButton(
                  speedMultiplier: _gameController.speedMultiplier,
                  onTap: _gameController.cycleSpeed,
                ),
              ),
            if ((isSnes || pageLandscape) &&
                CoreLoader.isGameBoyRom(game.romPath))
              Positioned(
                top: 100,
                right: 14,
                child: _LinkStatusChip(
                  linkManager: _gameController.linkManager,
                ),
              ),
            if (_isClosing)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: .72),
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 38),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 18),
                            Text(
                              _closingStatus,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No cierres RetroHub mientras termina el respaldo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmulatorHeader extends StatelessWidget {
  final Game game;
  final Color accent;
  final List<int> partySpeciesIds;

  const _EmulatorHeader({
    required this.game,
    required this.accent,
    required this.partySpeciesIds,
  });

  @override
  Widget build(BuildContext context) {
    final coverPath = CoverHelper.getCover(game.title, game.console);

    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Row(
      children: [
        _GameArtwork(
          coverPath: coverPath,
          accent: accent,
          width: 36,
          height: 44,
          iconSize: 20,
        ),
        const SizedBox(width: 9),
        if (isLandscape)
          Expanded(
            child: Text(
              _cleanGameTitle(game.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          )
        else
          const Spacer(),
        if (partySpeciesIds.isNotEmpty) ...[
          if (isLandscape) const SizedBox(width: 8),
          _PartySprites(
            game: game,
            speciesIds: partySpeciesIds,
            accent: accent,
          ),
        ],
      ],
    );
  }
}

class _FullscreenPartyOverlay extends StatelessWidget {
  final Game game;
  final List<int> speciesIds;
  final Color accent;

  const _FullscreenPartyOverlay({
    required this.game,
    required this.speciesIds,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (speciesIds.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: _PartySprites(
                game: game,
                speciesIds: speciesIds,
                accent: accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PartySprites extends StatelessWidget {
  final Game game;
  final List<int> speciesIds;
  final Color accent;

  const _PartySprites({
    required this.game,
    required this.speciesIds,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final visibleIds = speciesIds.take(6).toList(growable: false);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: visibleIds
          .map((speciesId) {
            return Padding(
              padding: const EdgeInsets.only(left: 2),
              child: _PokemonAvatar(
                spritePath: _pokemonSpritePath(game, speciesId),
                accent: accent,
                size: 30,
                fallback: const Icon(
                  Icons.catching_pokemon,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _PokemonAvatar extends StatelessWidget {
  final String spritePath;
  final Color accent;
  final double size;
  final double padding;
  final Widget fallback;

  const _PokemonAvatar({
    required this.spritePath,
    required this.accent,
    required this.size,
    required this.fallback,
    this.padding = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.9,
          colors: <Color>[
            accent.withValues(alpha: 0.22),
            Color.lerp(accent, Colors.black, 0.78)!,
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.58),
          width: size >= 60 ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: size >= 60 ? 10 : 4,
            offset: Offset(0, size >= 60 ? 4 : 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          spritePath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => Center(child: fallback),
        ),
      ),
    );
  }
}

enum _ExitGameAction { keepPlaying, localOnly, cloudBackup }

class _ExitGameDialog extends StatelessWidget {
  final Game game;
  final Color accent;
  final List<int> partySpeciesIds;
  final bool cloudAvailable;

  const _ExitGameDialog({
    required this.game,
    required this.accent,
    required this.partySpeciesIds,
    required this.cloudAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final coverPath = CoverHelper.getCover(game.title, game.console);
    final firstPokemon = partySpeciesIds.isEmpty ? null : partySpeciesIds.first;

    return AlertDialog(
      backgroundColor: Color.lerp(accent, Colors.black, 0.82),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: accent, width: 2),
      ),
      icon: SizedBox(
        width: 92,
        height: 92,
        child: firstPokemon == null
            ? _GameArtwork(
                coverPath: coverPath,
                accent: accent,
                width: 92,
                height: 92,
                iconSize: 46,
              )
            : _PokemonAvatar(
                spritePath: _pokemonSpritePath(game, firstPokemon),
                accent: accent,
                size: 92,
                padding: 5,
                fallback: _GameArtwork(
                  coverPath: coverPath,
                  accent: accent,
                  width: 92,
                  height: 92,
                  iconSize: 46,
                ),
              ),
      ),
      title: const Text(
        '¿Salir del juego?',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: Text(
        cloudAvailable
            ? 'El progreso de ${_cleanGameTitle(game.title)} siempre se guardará localmente. Elige si también quieres reemplazar su respaldo en la nube.'
            : 'El progreso de ${_cleanGameTitle(game.title)} se guardará localmente antes de salir. Inicia sesión con Google para respaldarlo en la nube.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_ExitGameAction.keepPlaying),
          child: const Text('Seguir jugando'),
        ),
        if (cloudAvailable)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () =>
                Navigator.of(context).pop(_ExitGameAction.cloudBackup),
            child: const Text('Respaldar y salir'),
          ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
          onPressed: () =>
              Navigator.of(context).pop(_ExitGameAction.localOnly),
          child: const Text('Salir sin respaldar'),
        ),
      ],
    );
  }
}

class _GameArtwork extends StatelessWidget {
  final String? coverPath;
  final Color accent;
  final double width;
  final double height;
  final double iconSize;

  const _GameArtwork({
    required this.coverPath,
    required this.accent,
    required this.width,
    required this.height,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
      ),
      child: coverPath == null
          ? Icon(Icons.sports_esports_rounded, color: accent, size: iconSize)
          : Image.asset(
              coverPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.sports_esports_rounded,
                color: accent,
                size: iconSize,
              ),
            ),
    );
  }
}

String _cleanGameTitle(String title) {
  final cleaned = title
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return 'Juego';

  return cleaned
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ')
      .replaceAll(RegExp(r'^Pokemon\b', caseSensitive: false), 'Pokémon');
}

double _ndsTopScreenScale(EmulatorPreferences preferences) {
  final emphasis = preferences.ndsScreenEmphasis;
  final relative = emphasis == NdsScreenEmphasis.bottom ? .82 : 1.0;
  return relative;
}

double _ndsBottomScreenScale(EmulatorPreferences preferences) {
  final emphasis = preferences.ndsScreenEmphasis;
  final relative = emphasis == NdsScreenEmphasis.top ? .82 : 1.0;
  return relative;
}

(Rect, Rect) _ndsHorizontalDestinations(
  Size size, {
  required double topScreenScale,
  required double bottomScreenScale,
  required double screensScale,
}) {
  const gap = 4.0;
  const aspectRatio = 4 / 3;
  final widthBase =
      (size.width - gap) / (topScreenScale + bottomScreenScale);
  final heightBase = size.height * aspectRatio /
      math.max(topScreenScale, bottomScreenScale);
  final layoutWidth = math.min(widthBase, heightBase) * screensScale;
  final topWidth = layoutWidth * topScreenScale;
  final bottomWidth = layoutWidth * bottomScreenScale;
  final topHeight = topWidth / aspectRatio;
  final bottomHeight = bottomWidth / aspectRatio;
  final contentWidth = topWidth + gap + bottomWidth;
  final left = (size.width - contentWidth) / 2;
  return (
    Rect.fromLTWH(
      left,
      (size.height - topHeight) / 2,
      topWidth,
      topHeight,
    ),
    Rect.fromLTWH(
      left + topWidth + gap,
      (size.height - bottomHeight) / 2,
      bottomWidth,
      bottomHeight,
    ),
  );
}

String _pokemonSpritePath(Game game, int speciesId) {
  final profile = GameAssetProfile.fromGame(game);

  if (speciesId == 0) {
    return SpriteResolver.eggForGame(profile: profile);
  }

  return SpriteResolver.pokemonForGame(profile: profile, pokemonId: speciesId);
}

class _EmulatorVisualTheme {
  final Color background;
  final Color appBar;
  final Color accent;
  final LinearGradient gradient;

  const _EmulatorVisualTheme({
    required this.background,
    required this.appBar,
    required this.accent,
    required this.gradient,
  });

  factory _EmulatorVisualTheme.forGame(Game game) {
    final String identity = '${game.title} ${game.console}'.toLowerCase();
    final PokemonGameVersion pokemonVersion =
        PokemonGameProfile.fromGameIdentity(
          gameTitle: game.title,
          romPath: game.romPath,
        ).version;

    Color primary;
    Color secondary;
    Color accent;

    if (identity.contains('platinum') ||
        identity.contains('platino')) {
      primary = const Color(0xFF241C24);
      secondary = const Color(0xFF4C2730);
      accent = const Color(0xFFE0B85A);
    } else if (identity.contains('diamond') ||
        identity.contains('diamante')) {
      primary = const Color(0xFF102A46);
      secondary = const Color(0xFF176B88);
      accent = const Color(0xFF7DE8FF);
    } else if (identity.contains('pearl') ||
        identity.contains('perla')) {
      primary = const Color(0xFF3D1839);
      secondary = const Color(0xFF7B3B71);
      accent = const Color(0xFFFFA7E3);
    } else if (identity.contains('heartgold') ||
        identity.contains('heart gold')) {
      primary = const Color(0xFF3A2A10);
      secondary = const Color(0xFF77551A);
      accent = const Color(0xFFFFD86A);
    } else if (identity.contains('soulsilver') ||
        identity.contains('soul silver')) {
      primary = const Color(0xFF17283A);
      secondary = const Color(0xFF49647A);
      accent = const Color(0xFFDCEBFA);
    } else if (identity.contains('black 2') ||
        identity.contains('negro 2') ||
        identity.contains('negra 2')) {
      primary = const Color(0xFF111318);
      secondary = const Color(0xFF263A54);
      accent = const Color(0xFF64B5F6);
    } else if (identity.contains('white 2') ||
        identity.contains('blanco 2') ||
        identity.contains('blanca 2')) {
      primary = const Color(0xFF334E63);
      secondary = const Color(0xFFB83243);
      accent = const Color(0xFFF7FCFF);
    } else if (identity.contains('black') ||
        identity.contains('negra') ||
        identity.contains('negro')) {
      primary = const Color(0xFF555B63);
      secondary = const Color(0xFFA94343);
      accent = const Color(0xFFFFF3DF);
    } else if (identity.contains('white') ||
        identity.contains('blanca') ||
        identity.contains('blanco')) {
      primary = const Color(0xFF070A10);
      secondary = const Color(0xFF183451);
      accent = const Color(0xFF43C7E8);
    } else if (pokemonVersion == PokemonGameVersion.fireRed) {
      primary = const Color(0xFFF05A24);
      secondary = const Color(0xFF7A260E);
      accent = const Color(0xFFFFC44F);
    } else if (pokemonVersion == PokemonGameVersion.leafGreen) {
      primary = const Color(0xFF62C947);
      secondary = const Color(0xFF286A22);
      accent = const Color(0xFFD0F58F);
    } else if (identity.contains('emerald') || identity.contains('esmeralda')) {
      primary = const Color(0xFF0E382D);
      secondary = const Color(0xFF176A4B);
      accent = const Color(0xFF66E6A4);
    } else if (identity.contains('sapphire') || identity.contains('zafiro')) {
      primary = const Color(0xFF102A4A);
      secondary = const Color(0xFF175A88);
      accent = const Color(0xFF6ED4FF);
    } else if (identity.contains('ruby') ||
        identity.contains('rubi') ||
        identity.contains('rubí')) {
      primary = const Color(0xFF42131C);
      secondary = const Color(0xFF7A2135);
      accent = const Color(0xFFFF6F86);
    } else if (identity.contains('crystal') || identity.contains('cristal')) {
      primary = const Color(0xFF102A43);
      secondary = const Color(0xFF39265F);
      accent = const Color(0xFF7DE3FF);
    } else if (identity.contains('gold') || identity.contains('oro')) {
      primary = const Color(0xFF3B2A10);
      secondary = const Color(0xFF6A4A16);
      accent = const Color(0xFFFFD56A);
    } else if (identity.contains('silver') || identity.contains('plata')) {
      primary = const Color(0xFF202938);
      secondary = const Color(0xFF465264);
      accent = const Color(0xFFD7E4F2);
    } else if (identity.contains('yellow') || identity.contains('amarillo')) {
      primary = const Color(0xFF3D3210);
      secondary = const Color(0xFF6A4A18);
      accent = const Color(0xFFFFE66D);
    } else if (identity.contains('red') || identity.contains('rojo')) {
      primary = const Color(0xFF3D151B);
      secondary = const Color(0xFF651E2A);
      accent = const Color(0xFFFF7188);
    } else if (identity.contains('blue') || identity.contains('azul')) {
      primary = const Color(0xFF102A4A);
      secondary = const Color(0xFF174B70);
      accent = const Color(0xFF72D5FF);
    } else if (identity.contains('snes')) {
      primary = const Color(0xFF26243B);
      secondary = const Color(0xFF514B72);
      accent = const Color(0xFFC9C2F2);
    } else if (identity.contains('nds') || identity.contains('nintendo ds')) {
      primary = const Color(0xFF24282E);
      secondary = const Color(0xFF4A515B);
      accent = const Color(0xFFE6EBF0);
    } else if (identity.contains('gba')) {
      primary = const Color(0xFF202842);
      secondary = const Color(0xFF35305F);
      accent = const Color(0xFFA7B8FF);
    } else if (identity.contains('gbc')) {
      primary = const Color(0xFF241B3D);
      secondary = const Color(0xFF3F2B5B);
      accent = const Color(0xFFC9A7FF);
    } else {
      primary = const Color(0xFF252D20);
      secondary = const Color(0xFF3E4934);
      accent = const Color(0xFFB8D47A);
    }

    return _EmulatorVisualTheme(
      background: primary,
      appBar: Color.lerp(primary, Colors.black, 0.28)!,
      accent: accent,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(primary, Colors.black, 0.18)!,
          primary,
          secondary,
          Color.lerp(secondary, Colors.black, 0.34)!,
        ],
        stops: const <double>[0, 0.35, 0.72, 1],
      ),
    );
  }
}

class _CoreNotFoundView extends StatelessWidget {
  final String romPath;
  final EmulationCore core;

  const _CoreNotFoundView({required this.romPath, required this.core});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontró ${core.displayName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontró el core necesario para esta ROM.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rutas revisadas:\n${CoreLoader.debugCoreSearchPathsForRom(romPath)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ROM:\n$romPath',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnesSidePanel extends StatelessWidget {
  final bool isLeft;
  final double opacity;
  final Widget child;
  final Color topColor;
  final Color bottomColor;
  final Color borderColor;

  const _SnesSidePanel({
    required this.isLeft,
    required this.opacity,
    required this.child,
    this.topColor = const Color(0xFFD9D8DC),
    this.bottomColor = const Color(0xFFB8B7BD),
    this.borderColor = const Color(0xFF77747F),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[topColor, bottomColor],
        ),
        border: Border(
          left: isLeft
              ? BorderSide.none
              : BorderSide(color: borderColor, width: 2),
          right: isLeft
              ? BorderSide(color: borderColor, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}

class _LandscapeLeftControls extends StatelessWidget {
  final LibretroGameController controller;
  final DirectionalControlType directionalControl;
  final int buttonUp;
  final int buttonDown;
  final int buttonLeft;
  final int buttonRight;
  final int buttonSelect;
  final int buttonL;
  final bool showShoulder;
  final RetroHubConsoleType? consoleLogo;

  const _LandscapeLeftControls({
    required this.controller,
    required this.directionalControl,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
    required this.buttonSelect,
    required this.buttonL,
    required this.showShoulder,
    this.consoleLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showShoulder) ...[
          _GameBoyShoulderButton(
            label: 'L',
            buttonId: buttonL,
            controller: controller,
          ),
          const SizedBox(height: 10),
        ],
        _GameBoySystemButton(
          width: 76,
          height: 26,
          label: 'SELECT',
          buttonId: buttonSelect,
          controller: controller,
        ),
        const SizedBox(height: 22),
        _DirectionalControl(
          type: directionalControl,
          keySize: 38,
          controller: controller,
          buttonUp: buttonUp,
          buttonDown: buttonDown,
          buttonLeft: buttonLeft,
          buttonRight: buttonRight,
        ),
        if (consoleLogo != null) ...[
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RetroHubConsoleLogo(console: consoleLogo!),
          ),
        ],
      ],
    );
  }
}

class _LandscapeRightControls extends StatelessWidget {
  final LibretroGameController controller;
  final int buttonA;
  final int buttonB;
  final int buttonX;
  final int buttonY;
  final int buttonStart;
  final int buttonR;
  final bool showShoulder;
  final bool isSnes;
  final bool rotateActions;
  final Color buttonAColor;
  final Color buttonBColor;
  final Color buttonXColor;
  final Color buttonYColor;

  const _LandscapeRightControls({
    required this.controller,
    required this.buttonA,
    required this.buttonB,
    required this.buttonX,
    required this.buttonY,
    required this.buttonStart,
    required this.buttonR,
    required this.showShoulder,
    required this.isSnes,
    this.rotateActions = true,
    this.buttonAColor = const Color(0xFF5E4B8B),
    this.buttonBColor = const Color(0xFF8173AE),
    this.buttonXColor = const Color(0xFF8173AE),
    this.buttonYColor = const Color(0xFF5E4B8B),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showShoulder) ...[
          _GameBoyShoulderButton(
            label: 'R',
            buttonId: buttonR,
            controller: controller,
          ),
          const SizedBox(height: 10),
        ],
        _GameBoySystemButton(
          width: 76,
          height: 26,
          label: 'START',
          buttonId: buttonStart,
          controller: controller,
        ),
        const SizedBox(height: 22),
        if (isSnes)
          _SnesActionPad(
            size: 42,
            controller: controller,
            buttonA: buttonA,
            buttonB: buttonB,
            buttonX: buttonX,
            buttonY: buttonY,
            buttonAColor: buttonAColor,
            buttonBColor: buttonBColor,
            buttonXColor: buttonXColor,
            buttonYColor: buttonYColor,
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Transform.rotate(
              angle: rotateActions ? -0.20 : 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GameBoyActionButton(
                    size: 58,
                    label: 'B',
                    buttonId: buttonB,
                    controller: controller,
                  ),
                  const SizedBox(width: 14),
                  _GameBoyActionButton(
                    size: 58,
                    label: 'A',
                    buttonId: buttonA,
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GameBoyControls extends StatelessWidget {
  final bool compact;
  final bool classicLayout;
  final double sizeScale;
  final double opacity;
  final bool swapLabels;
  final LibretroGameController controller;
  final DirectionalControlType directionalControl;
  final int buttonUp;
  final int buttonDown;
  final int buttonLeft;
  final int buttonRight;
  final int buttonA;
  final int buttonB;
  final int buttonX;
  final int buttonY;
  final int buttonSelect;
  final int buttonStart;
  final int buttonL;
  final int buttonR;
  final bool showShoulder;
  final bool isSnes;
  final Color buttonAColor;
  final Color buttonBColor;
  final Color buttonXColor;
  final Color buttonYColor;

  const _GameBoyControls({
    required this.compact,
    this.classicLayout = false,
    this.sizeScale = 1,
    this.opacity = 1,
    this.swapLabels = false,
    required this.controller,
    required this.directionalControl,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
    required this.buttonA,
    required this.buttonB,
    required this.buttonX,
    required this.buttonY,
    required this.buttonSelect,
    required this.buttonStart,
    required this.buttonL,
    required this.buttonR,
    required this.showShoulder,
    required this.isSnes,
    this.buttonAColor = const Color(0xFF5E4B8B),
    this.buttonBColor = const Color(0xFF8173AE),
    this.buttonXColor = const Color(0xFF8173AE),
    this.buttonYColor = const Color(0xFF5E4B8B),
  });

  @override
  Widget build(BuildContext context) {
    final double dPadKeySize = (compact ? 30 : 42) * sizeScale;
    final double actionSize = (compact ? 54 : 66) * sizeScale;
    final double systemWidth = (compact ? 68 : 82) * sizeScale;
    final double systemHeight = (compact ? 24 : 28) * sizeScale;

    final Widget dPad = _DirectionalControl(
      type: directionalControl,
      keySize: dPadKeySize,
      controller: controller,
      buttonUp: buttonUp,
      buttonDown: buttonDown,
      buttonLeft: buttonLeft,
      buttonRight: buttonRight,
    );

    final Widget actions = isSnes
        ? _SnesActionPad(
            size: compact ? 38 : 45,
            controller: controller,
            buttonA: buttonA,
            buttonB: buttonB,
            buttonX: buttonX,
            buttonY: buttonY,
            buttonAColor: buttonAColor,
            buttonBColor: buttonBColor,
            buttonXColor: buttonXColor,
            buttonYColor: buttonYColor,
          )
        : Transform.rotate(
            angle: -0.20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GameBoyActionButton(
                  size: actionSize,
                  label: swapLabels ? 'A' : 'B',
                  buttonId: buttonB,
                  controller: controller,
                ),
                SizedBox(width: compact ? 12 : 16),
                _GameBoyActionButton(
                  size: actionSize,
                  label: swapLabels ? 'B' : 'A',
                  buttonId: buttonA,
                  controller: controller,
                ),
              ],
            ),
          );

    final Widget systemButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GameBoySystemButton(
          width: systemWidth,
          height: systemHeight,
          label: 'SELECT',
          buttonId: buttonSelect,
          controller: controller,
        ),
        SizedBox(width: compact ? 10 : 14),
        _GameBoySystemButton(
          width: systemWidth,
          height: systemHeight,
          label: 'START',
          buttonId: buttonStart,
          controller: controller,
        ),
      ],
    );

    if (compact) {
      return const SizedBox.shrink();
    }

    final Widget shoulderButtons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _GameBoyShoulderButton(
          label: 'L',
          buttonId: buttonL,
          controller: controller,
        ),
        _GameBoyShoulderButton(
          label: 'R',
          buttonId: buttonR,
          controller: controller,
        ),
      ],
    );

    final controls = SizedBox(
      height: (showShoulder ? 224 : 184) * sizeScale,
      child: Column(
        children: [
          if (showShoulder) ...[shoulderButtons, const SizedBox(height: 10)],
          if (!classicLayout) ...[systemButtons, const SizedBox(height: 10)],
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [dPad, actions],
            ),
          ),
          if (classicLayout) ...[
            const SizedBox(height: 10),
            systemButtons,
          ],
        ],
      ),
    );
    return Opacity(opacity: opacity, child: controls);
  }
}

class _SnesActionPad extends StatelessWidget {
  final double size;
  final LibretroGameController controller;
  final int buttonA;
  final int buttonB;
  final int buttonX;
  final int buttonY;
  final Color buttonAColor;
  final Color buttonBColor;
  final Color buttonXColor;
  final Color buttonYColor;

  const _SnesActionPad({
    required this.size,
    required this.controller,
    required this.buttonA,
    required this.buttonB,
    required this.buttonX,
    required this.buttonY,
    required this.buttonAColor,
    required this.buttonBColor,
    required this.buttonXColor,
    required this.buttonYColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final double buttonStep = size * (isAndroid ? .94 : .78);

    return SizedBox(
      width: (buttonStep * 2) + size,
      height: (buttonStep * 2) + size,
      child: Stack(
        children: [
          Positioned(
            left: buttonStep,
            child: _GameBoyActionButton(size: size, label: 'X', buttonId: buttonX, controller: controller, color: buttonXColor),
          ),
          Positioned(
            top: buttonStep,
            child: _GameBoyActionButton(size: size, label: 'Y', buttonId: buttonY, controller: controller, color: buttonYColor),
          ),
          Positioned(
            top: buttonStep,
            right: 0,
            child: _GameBoyActionButton(size: size, label: 'A', buttonId: buttonA, controller: controller, color: buttonAColor),
          ),
          Positioned(
            left: buttonStep,
            bottom: 0,
            child: _GameBoyActionButton(size: size, label: 'B', buttonId: buttonB, controller: controller, color: buttonBColor),
          ),
        ],
      ),
    );
  }
}

class _DirectionalControl extends StatelessWidget {
  final DirectionalControlType type;
  final double keySize;
  final LibretroGameController controller;
  final int buttonUp;
  final int buttonDown;
  final int buttonLeft;
  final int buttonRight;

  const _DirectionalControl({
    required this.type,
    required this.keySize,
    required this.controller,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
  });

  @override
  Widget build(BuildContext context) {
    if (type == DirectionalControlType.joystick) {
      return _VirtualJoystick(
        size: keySize * 3,
        controller: controller,
        buttonUp: buttonUp,
        buttonDown: buttonDown,
        buttonLeft: buttonLeft,
        buttonRight: buttonRight,
      );
    }
    return _GameBoyDPad(
      keySize: keySize,
      controller: controller,
      buttonUp: buttonUp,
      buttonDown: buttonDown,
      buttonLeft: buttonLeft,
      buttonRight: buttonRight,
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  final double size;
  final LibretroGameController controller;
  final int buttonUp;
  final int buttonDown;
  final int buttonLeft;
  final int buttonRight;

  const _VirtualJoystick({
    required this.size,
    required this.controller,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
  });

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset _knobOffset = Offset.zero;
  final Set<int> _pressedButtons = <int>{};
  int? _activePointer;

  double get _travelRadius => widget.size * .27;

  void _updatePosition(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final rawOffset = localPosition - center;
    final distance = rawOffset.distance;
    final clampedOffset = distance <= _travelRadius || distance == 0
        ? rawOffset
        : rawOffset / distance * _travelRadius;
    final normalized = clampedOffset / _travelRadius;
    final desiredButtons = <int>{};

    // The threshold creates a central dead zone and still allows diagonals.
    if (normalized.dx < -.32) desiredButtons.add(widget.buttonLeft);
    if (normalized.dx > .32) desiredButtons.add(widget.buttonRight);
    if (normalized.dy < -.32) desiredButtons.add(widget.buttonUp);
    if (normalized.dy > .32) desiredButtons.add(widget.buttonDown);

    _setPressedButtons(desiredButtons);
    setState(() => _knobOffset = clampedOffset);
  }

  void _setPressedButtons(Set<int> desiredButtons) {
    for (final button in _pressedButtons.difference(desiredButtons)) {
      widget.controller.releaseButton(button);
    }
    for (final button in desiredButtons.difference(_pressedButtons)) {
      widget.controller.pressButton(button);
    }
    _pressedButtons
      ..clear()
      ..addAll(desiredButtons);
  }

  void _release() {
    _setPressedButtons(<int>{});
    if (mounted) setState(() => _knobOffset = Offset.zero);
  }

  @override
  void didUpdateWidget(covariant _VirtualJoystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.buttonUp != widget.buttonUp ||
        oldWidget.buttonDown != widget.buttonDown ||
        oldWidget.buttonLeft != widget.buttonLeft ||
        oldWidget.buttonRight != widget.buttonRight) {
      for (final button in _pressedButtons) {
        oldWidget.controller.releaseButton(button);
      }
      _pressedButtons.clear();
      _knobOffset = Offset.zero;
    }
  }

  @override
  void dispose() {
    for (final button in _pressedButtons) {
      widget.controller.releaseButton(button);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final knobSize = widget.size * .44;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_activePointer != null) return;
        _activePointer = event.pointer;
        _updatePosition(event.localPosition);
      },
      onPointerMove: (event) {
        if (_activePointer == event.pointer) {
          _updatePosition(event.localPosition);
        }
      },
      onPointerUp: (event) {
        if (_activePointer != event.pointer) return;
        _activePointer = null;
        _release();
      },
      onPointerCancel: (event) {
        if (_activePointer != event.pointer) return;
        _activePointer = null;
        _release();
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: <Color>[
                Color(0xFF34343B),
                Color(0xFF202026),
                Color(0xFF111116),
              ],
              stops: <double>[0, .72, 1],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .14),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .48),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: .06),
                blurRadius: 4,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Center(
            child: Transform.translate(
              offset: _knobOffset,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF77777F), Color(0xFF3D3D44)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .22),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .55),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameBoyDPad extends StatelessWidget {
  final double keySize;
  final LibretroGameController controller;
  final int buttonUp;
  final int buttonDown;
  final int buttonLeft;
  final int buttonRight;

  const _GameBoyDPad({
    required this.keySize,
    required this.controller,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: keySize * 3,
      height: keySize * 3,
      child: Stack(
        children: [
          Positioned(
            left: keySize,
            top: 0,
            child: _GameBoyDPadKey(
              size: keySize,
              buttonId: buttonUp,
              controller: controller,
              icon: Icons.keyboard_arrow_up_rounded,
              topLeft: true,
              topRight: true,
            ),
          ),
          Positioned(
            left: keySize,
            top: keySize * 2,
            child: _GameBoyDPadKey(
              size: keySize,
              buttonId: buttonDown,
              controller: controller,
              icon: Icons.keyboard_arrow_down_rounded,
              bottomLeft: true,
              bottomRight: true,
            ),
          ),
          Positioned(
            left: 0,
            top: keySize,
            child: _GameBoyDPadKey(
              size: keySize,
              buttonId: buttonLeft,
              controller: controller,
              icon: Icons.keyboard_arrow_left_rounded,
              topLeft: true,
              bottomLeft: true,
            ),
          ),
          Positioned(
            left: keySize * 2,
            top: keySize,
            child: _GameBoyDPadKey(
              size: keySize,
              buttonId: buttonRight,
              controller: controller,
              icon: Icons.keyboard_arrow_right_rounded,
              topRight: true,
              bottomRight: true,
            ),
          ),
          Positioned(
            left: keySize,
            top: keySize,
            child: Container(
              width: keySize,
              height: keySize,
              decoration: BoxDecoration(
                color: const Color(0xFF242328),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.38),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameBoyDPadKey extends StatelessWidget {
  final double size;
  final int buttonId;
  final LibretroGameController controller;
  final IconData icon;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _GameBoyDPadKey({
    required this.size,
    required this.buttonId,
    required this.controller,
    required this.icon,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableControl(
      buttonId: buttonId,
      controller: controller,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topLeft ? 10 : 0),
        topRight: Radius.circular(topRight ? 10 : 0),
        bottomLeft: Radius.circular(bottomLeft ? 10 : 0),
        bottomRight: Radius.circular(bottomRight ? 10 : 0),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2A30),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topLeft ? 10 : 0),
            topRight: Radius.circular(topRight ? 10 : 0),
            bottomLeft: Radius.circular(bottomLeft ? 10 : 0),
            bottomRight: Radius.circular(bottomRight ? 10 : 0),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: size * 0.60,
        ),
      ),
    );
  }
}

class _GameBoyActionButton extends StatelessWidget {
  final double size;
  final String label;
  final int buttonId;
  final LibretroGameController controller;
  final Color color;

  const _GameBoyActionButton({
    required this.size,
    required this.label,
    required this.buttonId,
    required this.controller,
    this.color = const Color(0xFF8B3E67),
  });

  @override
  Widget build(BuildContext context) {
    return _PressableControl(
      buttonId: buttonId,
      controller: controller,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.32),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.09),
              blurRadius: 3,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GameBoyShoulderButton extends StatelessWidget {
  final String label;
  final int buttonId;
  final LibretroGameController controller;

  const _GameBoyShoulderButton({
    required this.label,
    required this.buttonId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableControl(
      buttonId: buttonId,
      controller: controller,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 64,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF47464D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GameBoySystemButton extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final int buttonId;
  final LibretroGameController controller;

  const _GameBoySystemButton({
    required this.width,
    required this.height,
    required this.label,
    required this.buttonId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableControl(
      buttonId: buttonId,
      controller: controller,
      borderRadius: BorderRadius.circular(30),
      child: Transform.rotate(
        angle: -0.12,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF66636B),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableControl extends StatefulWidget {
  final int buttonId;
  final LibretroGameController controller;
  final BorderRadius borderRadius;
  final Widget child;

  const _PressableControl({
    required this.buttonId,
    required this.controller,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_PressableControl> createState() => _PressableControlState();
}

class _PressableControlState extends State<_PressableControl> {
  bool _pressed = false;

  void _press() {
    if (!mounted || _pressed) {
      return;
    }

    setState(() {
      _pressed = true;
    });

    widget.controller.pressButton(widget.buttonId);
  }

  void _release() {
    if (!mounted || !_pressed) {
      return;
    }

    setState(() {
      _pressed = false;
    });

    widget.controller.releaseButton(widget.buttonId);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1,
        duration: const Duration(milliseconds: 65),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.76 : 1,
          duration: const Duration(milliseconds: 65),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Control del Cable Link Bluetooth.
///
/// Muestra el estado actual y permite crear, buscar o cerrar
/// una sesión Link directamente desde el emulador.
class _LinkStatusChip extends StatelessWidget {
  const _LinkStatusChip({required this.linkManager});

  final LinkManager? linkManager;

  @override
  Widget build(BuildContext context) {
    final LinkManager? manager = linkManager;

    if (manager == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<LinkState>(
      stream: manager.onStateChanged,
      initialData: manager.state,
      builder: (context, snapshot) {
        final LinkState state = snapshot.data ?? LinkState.disconnected;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _handleTap(context, manager, state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cable, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    _labelFor(state),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    LinkManager manager,
    LinkState state,
  ) async {
    switch (state) {
      case LinkState.connected:
      case LinkState.syncing:
      case LinkState.hosting:
      case LinkState.connecting:
      case LinkState.searching:
        await _showActiveSessionDialog(context, manager);
        return;

      case LinkState.disconnected:
      case LinkState.error:
        await _showConnectionDialog(context, manager);
        return;
    }
  }

  Future<void> _showConnectionDialog(
    BuildContext context,
    LinkManager manager,
  ) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  leading: Icon(Icons.cable, color: Colors.white),
                  title: Text(
                    'Cable Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Conecta dos dispositivos por Bluetooth',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(
                    Icons.wifi_tethering,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Crear sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Este dispositivo esperará al otro jugador',
                    style: TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'host');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search, color: Colors.white70),
                  title: const Text(
                    'Buscar sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Busca otro dispositivo RetroHub',
                    style: TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'join');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    if (action == 'host') {
      await _createSession(context, manager);
    } else if (action == 'join') {
      await _searchSession(context, manager);
    }
  }

  Future<void> _createSession(BuildContext context, LinkManager manager) async {
    const BluetoothDiscovery discovery = BluetoothDiscovery();

    try {
      if (!await discovery.isEnabled()) {
        final bool enabled = await discovery.requestEnable();

        if (!enabled) {
          return;
        }
      }

      // Evitamos requestDiscoverable(): el plugin puede provocar un crash
      // al regresar de la Activity de Android en algunos dispositivos.
      await manager.host(localName: 'RetroHub');
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear la sesión: $error')),
      );
    }
  }

  Future<void> _searchSession(BuildContext context, LinkManager manager) async {
    const BluetoothDiscovery discovery = BluetoothDiscovery();

    try {
      if (!await discovery.isEnabled()) {
        final bool enabled = await discovery.requestEnable();

        if (!enabled || !context.mounted) {
          return;
        }
      }

      final List<BluetoothDevice> bonded = await discovery
          .bondedRetroHubDevices();

      if (!context.mounted) {
        return;
      }

      final BluetoothDevice?
      selected = await showModalBottomSheet<BluetoothDevice>(
        context: context,
        backgroundColor: const Color(0xFF181818),
        builder: (sheetContext) {
          if (bonded.isEmpty) {
            return const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay dispositivos Bluetooth emparejados.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  leading: Icon(Icons.bluetooth_searching, color: Colors.white),
                  title: Text(
                    'Buscar sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Selecciona el teléfono que creó la sesión',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const Divider(color: Colors.white12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: bonded.length,
                    itemBuilder: (context, index) {
                      final BluetoothDevice device = bonded[index];

                      final String name = device.name?.trim().isNotEmpty == true
                          ? device.name!
                          : 'Dispositivo Bluetooth';

                      return ListTile(
                        leading: const Icon(
                          Icons.phone_android,
                          color: Colors.white70,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          device.address,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext, device);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (selected == null) {
        return;
      }

      await manager.join(localName: 'RetroHub', target: selected.address);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo conectar: $error')));
    }
  }

  Future<void> _showActiveSessionDialog(
    BuildContext context,
    LinkManager manager,
  ) async {
    final bool? disconnect = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.cable, color: Colors.greenAccent),
                  title: Text(
                    _labelFor(manager.state),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Cable Link Bluetooth',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.link_off, color: Colors.redAccent),
                  title: const Text(
                    'Desconectar',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (disconnect == true) {
      await manager.close();
    }
  }

  String _labelFor(LinkState state) {
    switch (state) {
      case LinkState.disconnected:
        return 'Cable Link';
      case LinkState.searching:
        return 'Buscando';
      case LinkState.hosting:
        return 'Esperando';
      case LinkState.connecting:
        return 'Conectando';
      case LinkState.connected:
        return 'Conectado';
      case LinkState.syncing:
        return 'Sincronizando';
      case LinkState.error:
        return 'Sin conexión';
    }
  }
}
