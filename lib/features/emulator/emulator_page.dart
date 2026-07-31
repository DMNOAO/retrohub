import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/emulation/core_loader.dart';
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

  final LibretroGameController _gameController =
      LibretroGameController();

  late final AppDatabase _database;
  late final JournalEventService _journalEventService;
  late final PokemonJournalTracker _pokemonJournalTracker;
  late final DateTime _sessionStartedAt;
  bool _sessionClosedLogged = false;
  bool _sessionPersisted = false;

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

    _pokemonJournalTracker = PokemonJournalTracker(
      database: _database,
      gameId: game.id,
      romPath: game.romPath,
      controller: _gameController,
      playTimeMinutes: () => _currentPlayTimeMinutes,
    );
    _pokemonJournalTracker.start();

    unawaited(
      _journalEventService.logGameStarted(
        playTimeMinutes: game.playTimeSeconds ~/ 60,
      ),
    );
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
        await _gameController.saveSram();
        await _pokemonJournalTracker.stop();
        await _logSessionClosed();

        if (!context.mounted) return;

        Navigator.of(context).pop();
        break;
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
    _gameController.resetInput();
    unawaited(_pokemonJournalTracker.stop());
    unawaited(_logSessionClosed());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? sameBoyPath = CoreLoader.findSameBoyPath();

    return Scaffold(
      appBar: AppBar(
        title: Text(game.title),
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
      body: SafeArea(
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
                  color: sameBoyPath != null
                      ? Colors.greenAccent
                      : Theme.of(context).colorScheme.error,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: sameBoyPath != null
                    ? LibretroGameView(
                        gameId: game.id,
                        corePath: sameBoyPath,
                        romPath: game.romPath,
                        initialPlayTimeMinutes:
                            game.playTimeSeconds ~/ 60,
                        controller: _gameController,
                      )
                    : _CoreNotFoundView(
                        romPath: game.romPath,
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 10 / 9,
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
                        aspectRatio: 10 / 9,
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CoreNotFoundView extends StatelessWidget {
  final String romPath;

  const _CoreNotFoundView({
    required this.romPath,
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
              'No se encontró SameBoy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontró el archivo sameboy_libretro.dll.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rutas revisadas:\n${CoreLoader.debugSearchPaths}',
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

  const _LandscapeLeftControls({
    required this.controller,
    required this.buttonUp,
    required this.buttonDown,
    required this.buttonLeft,
    required this.buttonRight,
    required this.buttonSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  const _LandscapeRightControls({
    required this.controller,
    required this.buttonA,
    required this.buttonB,
    required this.buttonStart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

    return SizedBox(
      height: 184,
      child: Column(
        children: [
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
