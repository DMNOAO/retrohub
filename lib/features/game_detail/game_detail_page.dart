import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/cover_helper.dart';
import '../../core/emulation/core_loader.dart';
import '../../core/assets/game_asset_profile.dart';
import '../../core/utils/play_time_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/games_repository_provider.dart';
import '../emulator/emulator_page.dart';
import '../frames/frames_page.dart';
import '../journal/journal_page.dart';

class GameDetailPage extends ConsumerStatefulWidget {
  final Game game;
  const GameDetailPage({super.key, required this.game});
  @override
  ConsumerState<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends ConsumerState<GameDetailPage> {
  late Game _game = widget.game;

  Future<void> _reload() async {
    final fresh = await ref.read(gamesRepositoryProvider).getGameById(_game.id);
    if (fresh != null && mounted) setState(() => _game = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final supportsJournal =
        GameAssetProfile.fromGame(game).supportsPokemonJournal;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _displayGameTitle(game.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          _DetailCover(coverPath: CoverHelper.getCover(game.title, game.console)),
          const SizedBox(height: 16),
          Text(game.console), const SizedBox(height: 16),
          Text('⏱ ${PlayTimeFormatter.fromSeconds(game.playTimeSeconds)} jugadas'),
        ]))),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmulatorPage(game: game)));
          await _reload();
        }, icon: const Icon(Icons.play_arrow), label: const Text('JUGAR')),
        const SizedBox(height: 16),
        if (supportsJournal)
          _DetailOption(icon: Icons.menu_book, title: 'Bitácora', subtitle: 'Ver estado actual e historia de la partida', onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => JournalPage(game: game)));
            await _reload();
          }),
        if (CoreLoader.isGameBoyRom(game.romPath) ||
            CoreLoader.isGbaRom(game.romPath) ||
            CoreLoader.isSnesRom(game.romPath))
          _DetailOption(icon: Icons.image, title: 'Marcos', subtitle: 'Personalizar marco del juego', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FramesPage(game: game)))),
      ]),
    );
  }
}

String _displayGameTitle(String title) =>
    title.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

class _DetailCover extends StatelessWidget {
  final String? coverPath;
  const _DetailCover({required this.coverPath});
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Container(width: 220, height: 300, color: Colors.black26, alignment: Alignment.center,
      child: coverPath == null ? const Icon(Icons.videogame_asset, size: 56, color: Colors.white38)
        : Image.asset(coverPath!, width: 220, height: 300, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, size: 56, color: Colors.white38))),
  );
}

class _DetailOption extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _DetailOption({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
    leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}
