import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'data/save_state_service.dart';
import 'presentation/widget/libretro_game_view.dart';
import 'memory_inspector/memory_inspector_page.dart';
import 'save_states/save_states_page.dart';

class EmulatorPage extends ConsumerStatefulWidget {
  final Game game;

  const EmulatorPage({
    super.key,
    required this.game,
  });

  @override
  ConsumerState<EmulatorPage> createState() => _EmulatorPageState();
}

class _EmulatorPageState extends ConsumerState<EmulatorPage> {
  static const int _buttonB = 0;
  static const int _buttonSelect = 2;
  static const int _buttonStart = 3;
  static const int _buttonUp = 4;
  static const int _buttonDown = 5;
  static const int _buttonLeft = 6;
  static const int _buttonRight = 7;
  static const int _buttonA = 8;
  static const int _buttonL = 10;
  static const int _buttonR = 11;

  final LibretroGameController _gameController =
      LibretroGameController();
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

  Game get game => widget.game;

  @override
  void initState() {
    super.initState();

    _sessionStartedAt = DateTime.now();
    _database = ref.read(databaseProvider);

    unawaited(_database.markGameOpened(game.id, _sessionStartedAt));

    _journalEventService = JournalEventService(
      database: _database,
      gameId: game.id,
    );

    if (!CoreLoader.isGbaRom(game.romPath)) {
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

  Future<void> _refreshHeaderParty() async {
    final snapshot = await _database.getLatestProgressSnapshot(game.id);
    if (!mounted || snapshot?.partyJson == null) return;

    try {
      final decoded = jsonDecode(snapshot!.partyJson!);
      if (decoded is! List) return;

      final ids = decoded
          .whereType<Map>()
          .map((pokemon) => pokemon['id'])
          .whereType<num>()
          .map((id) => id.toInt())
          .where((id) => id > 0)
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
    final int controllerMinutes =
        _gameController.currentPlayTimeMinutes;

    if (controllerMinutes > 0) {
      return controllerMinutes;
    }

    final int sessionMinutes =
        DateTime.now().difference(_sessionStartedAt).inMinutes;

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
      sessionDurationMinutes:
          DateTime.now().difference(_sessionStartedAt).inMinutes,
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String value,
  ) async {
    switch (value) {
      case 'save_state':
        await _openSaveStates(
          context,
          mode: SaveStatesMode.save,
        );
        break;

      case 'load_state':
        await _openSaveStates(
          context,
          mode: SaveStatesMode.load,
        );
        break;
      case 'screenshot':
        await _journalEventService.logScreenshot(
          playTimeMinutes: _currentPlayTimeMinutes,
        );

        if (!context.mounted) return;

        _showActionMessage(context, 'Captura registrada en la bitácora');
        break;
      case 'change_frame':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FramesPage(game: game),
          ),
        );
        break;
      case 'open_journal':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JournalPage(game: game),
          ),
        );
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
            builder: (_) => MemoryInspectorPage(
              controller: _gameController,
            ),
          ),
        );
        break;
      case 'settings':
        _showActionMessage(
          context,
          'Configuración del emulador',
        );
        break;
      case 'exit':
        await _requestExit(context);
        break;
    }
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
            final bool loaded =
                await _gameController.loadState(slot);

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
  }

  void _showActionMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _headerRefreshTimer?.cancel();
    _gameController.resetInput();
    final tracker = _pokemonJournalTracker;
    if (tracker != null) unawaited(tracker.stop());
    unawaited(_logSessionClosed());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmulationCore core = CoreLoader.coreForRom(game.romPath);
    final String? corePath = CoreLoader.findCorePath(game.romPath);
    final bool isGba = CoreLoader.isGbaRom(game.romPath);
    final _EmulatorVisualTheme visualTheme =
        _EmulatorVisualTheme.forGame(game);

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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              _handleMenuAction(context, value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'save_state',
                child: Text('Guardar estado'),
              ),
              PopupMenuItem(
                value: 'load_state',
                child: Text('Cargar estado'),
              ),
              PopupMenuItem(
                value: 'screenshot',
                child: Text('Tomar captura'),
              ),
              PopupMenuItem(
                value: 'change_frame',
                child: Text('Cambiar marco'),
              ),
              PopupMenuItem(
                value: 'open_journal',
                child: Text('Abrir bitácora'),
              ),
              PopupMenuItem(
                value: 'open_stats',
                child: Text('Ver estadísticas'),
              ),
              PopupMenuItem(
                value: 'memory_inspector',
                child: Text('Memory Inspector'),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text('Configuración'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'exit',
                child: Text('Salir del juego'),
              ),
            ],
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: visualTheme.gradient,
        ),
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
                        showShoulder: isGba,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: isGba ? 3 / 2 : 10 / 9,
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
                        buttonStart: _buttonStart,
                        buttonR: _buttonR,
                        showShoulder: isGba,
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
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: isGba ? 3 / 2 : 10 / 9,
                        child: gameView,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GameBoyControls(
                    compact: false,
                    controller: _gameController,
                    buttonUp: _buttonUp,
                    buttonDown: _buttonDown,
                    buttonLeft: _buttonLeft,
                    buttonRight: _buttonRight,
                    buttonA: _buttonA,
                    buttonB: _buttonB,
                    buttonSelect: _buttonSelect,
                    buttonStart: _buttonStart,
                    buttonL: _buttonL,
                    buttonR: _buttonR,
                    showShoulder: isGba,
                  ),
                ],
              ),
            );
          },
          ),
        ),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
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
      children: visibleIds.map((speciesId) {
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
      }).toList(growable: false),
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
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ')
      .replaceAll(RegExp(r'^Pokemon\b', caseSensitive: false), 'Pokémon');
}

String _pokemonSpritePath(Game game, int speciesId) {
  return SpriteResolver.pokemonForGame(
    profile: GameAssetProfile.fromGame(game),
    pokemonId: speciesId,
  );
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
    final String identity =
        '${game.title} ${game.console}'.toLowerCase();

    Color primary;
    Color secondary;
    Color accent;

    if (identity.contains('crystal') || identity.contains('cristal')) {
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
    } else if (identity.contains('yellow') ||
        identity.contains('amarillo')) {
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

  const _CoreNotFoundView({
    required this.romPath,
    required this.core,
  });

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
            const Text(
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
  final int buttonStart;
  final int buttonR;
  final bool showShoulder;

  const _LandscapeRightControls({
    required this.controller,
    required this.buttonA,
    required this.buttonB,
    required this.buttonStart,
    required this.buttonR,
    required this.showShoulder,
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
  final LibretroGameController controller;
  final int buttonUp;
  final int buttonDown;
  final int buttonLeft;
  final int buttonRight;
  final int buttonA;
  final int buttonB;
  final int buttonSelect;
  final int buttonStart;
  final int buttonL;
  final int buttonR;
  final bool showShoulder;

  const _GameBoyControls({
    required this.compact,
    required this.controller,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
    required this.buttonA,
    required this.buttonB,
    required this.buttonSelect,
    required this.buttonStart,
    required this.buttonL,
    required this.buttonR,
    required this.showShoulder,
  });

  @override
  Widget build(BuildContext context) {
    final double dPadKeySize = compact ? 30 : 42;
    final double actionSize = compact ? 54 : 66;
    final double systemWidth = compact ? 68 : 82;
    final double systemHeight = compact ? 24 : 28;

    final Widget dPad = _GameBoyDPad(
      keySize: dPadKeySize,
      controller: controller,
      buttonUp: buttonUp,
      buttonDown: buttonDown,
      buttonLeft: buttonLeft,
      buttonRight: buttonRight,
    );

    final Widget actions = Transform.rotate(
      angle: -0.20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GameBoyActionButton(
            size: actionSize,
            label: 'B',
            buttonId: buttonB,
            controller: controller,
          ),
          SizedBox(width: compact ? 12 : 16),
          _GameBoyActionButton(
            size: actionSize,
            label: 'A',
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

    return SizedBox(
      height: showShoulder ? 224 : 184,
      child: Column(
        children: [
          if (showShoulder) ...[
            shoulderButtons,
            const SizedBox(height: 10),
          ],
          systemButtons,
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                dPad,
                actions,
              ],
            ),
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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
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

  const _GameBoyActionButton({
    required this.size,
    required this.label,
    required this.buttonId,
    required this.controller,
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
          color: const Color(0xFF8B3E67),
          border: Border.all(
            color: const Color(0xFFB86F95),
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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
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
