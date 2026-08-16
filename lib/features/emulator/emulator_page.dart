import 'dart:async';
import 'dart:convert';

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
  bool _exitDialogOpen = false;
  Timer? _headerRefreshTimer;
  List<int> _partySpeciesIds = const <int>[];
  EmulatorPreferences _preferences = const EmulatorPreferences();

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
        CoreLoader.isGameBoyRom(game.romPath) ||
        (CoreLoader.isGbaRom(game.romPath) &&
            (pokemonProfile.version == PokemonGameVersion.emerald ||
                pokemonProfile.version == PokemonGameVersion.ruby ||
                pokemonProfile.version == PokemonGameVersion.sapphire));

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
    if (!mounted) return;
    setState(() => _preferences = preferences);
    await _applyDisplayPreferences(preferences);
  }

  Future<void> _applyDisplayPreferences(EmulatorPreferences preferences) async {
    if (_isAndroidSnes || CoreLoader.isSnesRom(game.romPath)) return;
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => FramesPage(game: game)));
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
          supportsGameBoyOptions: !CoreLoader.isSnesRom(game.romPath),
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
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ExitGameDialog(
        game: game,
        accent: visualTheme.accent,
        partySpeciesIds: _partySpeciesIds,
      ),
    );
    _exitDialogOpen = false;

    if (shouldExit != true || !context.mounted) return;
    await _closeAndPop(context);
  }

  Future<void> _closeAndPop(BuildContext context) async {
    if (_isClosing) return;
    setState(() => _isClosing = true);

    if (!CoreLoader.isSnesRom(game.romPath) &&
        _preferences.autoSaveOnExit) {
      await _gameController.saveState(
        slot: SaveStateService.autoSaveSlot,
        title: 'Guardado automático',
      );
    }
    await _gameController.saveSram();
    final tracker = _pokemonJournalTracker;
    if (tracker != null) await tracker.stop();
    await _logSessionClosed();

    if (context.mounted) {
      Navigator.of(context).pop();
    }
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
      unawaited(WakelockPlus.disable());
      unawaited(SystemChrome.setPreferredOrientations(const []));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmulationCore core = CoreLoader.coreForRom(game.romPath);
    final String? corePath = CoreLoader.findCorePath(game.romPath);
    final bool isGba = CoreLoader.isGbaRom(game.romPath);
    final bool isSnes = CoreLoader.isSnesRom(game.romPath);
    final bool isGbc =
        game.console.toLowerCase().contains('gbc') ||
        game.console.toLowerCase().contains('game boy color');
    final bool pageLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final _EmulatorVisualTheme visualTheme = _EmulatorVisualTheme.forGame(game);
    _gameController.hapticsEnabled = !isSnes && _preferences.vibrationEnabled;

    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestExit(context));
      },
      child: Scaffold(
        backgroundColor: visualTheme.background,
        appBar: AppBar(
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
                top: false,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool landscape =
                        constraints.maxWidth > constraints.maxHeight;
                    final double padding = landscape ? 8 : 14;

                    final Widget gameView = Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: corePath != null
                              ? visualTheme.accent
                              : Theme.of(context).colorScheme.error,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
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
                              )
                            : _CoreNotFoundView(
                                romPath: game.romPath,
                                core: core,
                              ),
                      ),
                    );

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
                                buttonUp: _buttonUp,
                                buttonDown: _buttonDown,
                                buttonLeft: _buttonLeft,
                                buttonRight: _buttonRight,
                                buttonSelect: _buttonSelect,
                                buttonL: _buttonL,
                                showShoulder: isGba || isSnes,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: isSnes
                                      ? 4 / 3
                                      : (isGba ? 3 / 2 : 10 / 9),
                                  child: gameView,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 166,
                              child: _LandscapeRightControls(
                                controller: _gameController,
                                buttonA: _buttonA,
                                buttonB: _buttonB,
                                buttonX: _buttonX,
                                buttonY: _buttonY,
                                buttonStart: _buttonStart,
                                buttonR: _buttonR,
                                showShoulder: isGba || isSnes,
                                isSnes: isSnes,
                              ),
                            ),
                          ],
                        ),
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
                                  : (isGba ? 3 / 2 : 10 / 9),
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
                          else if (isSnes || _preferences.showConsoleIdentity)
                            RetroHubConsoleLogo(
                              console: isSnes
                                  ? RetroHubConsoleType.superNintendo
                                  : isGba
                                  ? RetroHubConsoleType.gameBoyAdvance
                                  : isGbc
                                  ? RetroHubConsoleType.gameBoyColor
                                  : RetroHubConsoleType.gameBoy,
                            ),
                          SizedBox(
                            height: !isSnes &&
                                    !isGba &&
                                    !_preferences.showConsoleIdentity
                                ? 2
                                : 10,
                          ),

                          _GameBoyControls(
                            compact: false,
                            classicLayout: !isSnes &&
                                _preferences.layout ==
                                    GameBoyControlLayout.classic,
                            sizeScale: isSnes ? 1 : _preferences.sizeScale,
                            opacity: isSnes ? 1 : _preferences.controlOpacity,
                            swapLabels: !isSnes && _preferences.swapAB,
                            controller: _gameController,
                            buttonUp: _buttonUp,
                            buttonDown: _buttonDown,
                            buttonLeft: _buttonLeft,
                            buttonRight: _buttonRight,
                            buttonA: !isSnes && _preferences.swapAB
                                ? _buttonB
                                : _buttonA,
                            buttonB: !isSnes && _preferences.swapAB
                                ? _buttonA
                                : _buttonB,
                            buttonX: _buttonX,
                            buttonY: _buttonY,
                            buttonSelect: _buttonSelect,
                            buttonStart: _buttonStart,
                            buttonL: _buttonL,
                            buttonR: _buttonR,
                            showShoulder: isSnes ||
                                (isGba &&
                                    _preferences.layout !=
                                        GameBoyControlLayout.classic),
                            isSnes: isSnes,
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
        Expanded(
          child: Text(
            _cleanGameTitle(game.title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        if (partySpeciesIds.isNotEmpty) ...[
          const SizedBox(width: 8),
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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final visibleIds = speciesIds
        .take(isLandscape ? 6 : 3)
        .toList(growable: false);
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

class _ExitGameDialog extends StatelessWidget {
  final Game game;
  final Color accent;
  final List<int> partySpeciesIds;

  const _ExitGameDialog({
    required this.game,
    required this.accent,
    required this.partySpeciesIds,
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
        'Se guardará el progreso de ${_cleanGameTitle(game.title)} antes de salir.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Seguir jugando'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Guardar y salir'),
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

    Color primary;
    Color secondary;
    Color accent;

    if (identity.contains('firered') ||
        identity.contains('fire red') ||
        identity.contains('rojo fuego')) {
      primary = const Color(0xFF45151A);
      secondary = const Color(0xFF7A281E);
      accent = const Color(0xFFFF805C);
    } else if (identity.contains('leafgreen') ||
        identity.contains('leaf green') ||
        identity.contains('verde hoja')) {
      primary = const Color(0xFF123D2A);
      secondary = const Color(0xFF277044);
      accent = const Color(0xFF78E58F);
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

class _LandscapeLeftControls extends StatelessWidget {
  final LibretroGameController controller;
  final int buttonUp;
  final int buttonDown;
  final int buttonLeft;
  final int buttonRight;
  final int buttonSelect;
  final int buttonL;
  final bool showShoulder;

  const _LandscapeLeftControls({
    required this.controller,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
    required this.buttonSelect,
    required this.buttonL,
    required this.showShoulder,
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
        _GameBoyDPad(
          keySize: 38,
          controller: controller,
          buttonUp: buttonUp,
          buttonDown: buttonDown,
          buttonLeft: buttonLeft,
          buttonRight: buttonRight,
        ),
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
          )
        else
          Transform.rotate(
            angle: -0.20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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

  const _GameBoyControls({
    required this.compact,
    this.classicLayout = false,
    this.sizeScale = 1,
    this.opacity = 1,
    this.swapLabels = false,
    required this.controller,
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
  });

  @override
  Widget build(BuildContext context) {
    final double dPadKeySize = (compact ? 30 : 42) * sizeScale;
    final double actionSize = (compact ? 54 : 66) * sizeScale;
    final double systemWidth = (compact ? 68 : 82) * sizeScale;
    final double systemHeight = (compact ? 24 : 28) * sizeScale;

    final Widget dPad = _GameBoyDPad(
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

  const _SnesActionPad({
    required this.size,
    required this.controller,
    required this.buttonA,
    required this.buttonB,
    required this.buttonX,
    required this.buttonY,
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
            child: _GameBoyActionButton(size: size, label: 'X', buttonId: buttonX, controller: controller, color: const Color(0xFF4D75C8)),
          ),
          Positioned(
            top: buttonStep,
            child: _GameBoyActionButton(size: size, label: 'Y', buttonId: buttonY, controller: controller, color: const Color(0xFF58A66C)),
          ),
          Positioned(
            top: buttonStep,
            right: 0,
            child: _GameBoyActionButton(size: size, label: 'A', buttonId: buttonA, controller: controller, color: const Color(0xFFC84D58)),
          ),
          Positioned(
            left: buttonStep,
            bottom: 0,
            child: _GameBoyActionButton(size: size, label: 'B', buttonId: buttonB, controller: controller, color: const Color(0xFFD3B84A)),
          ),
        ],
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
