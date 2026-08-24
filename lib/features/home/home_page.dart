import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/cover_helper.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/games_repository_provider.dart';
import '../game_detail/game_detail_page.dart';
import '../widgets/dynamic_game_banner.dart';
import '../widgets/retrohub_console_icon.dart';
import '../widgets/retrohub_identity_banner.dart';

class HomeDashboardData {
  final List<Game> games;
  final Game? lastPlayed;

  const HomeDashboardData({required this.games, required this.lastPlayed});
}

final homeDashboardProvider = FutureProvider.autoDispose<HomeDashboardData>((ref) async {
  final repository = ref.watch(gamesRepositoryProvider);
  return HomeDashboardData(
    games: await repository.getGames(),
    lastPlayed: await repository.getLastPlayedGame(),
  );
});

class HomePage extends ConsumerWidget {
  final ValueChanged<String>? onConsoleSelected;

  const HomePage({super.key, this.onConsoleSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (data) {
        final byConsole = <String, List<Game>>{};
        for (final game in data.games) {
          byConsole.putIfAbsent(game.console, () => <Game>[]).add(game);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(homeDashboardProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const RetroHubIdentityBanner(),
              const SizedBox(height: 24),
              if (data.lastPlayed != null)
                DynamicGameBanner(
                  game: data.lastPlayed!,
                  coverPath: CoverHelper.getCover(data.lastPlayed!.title, data.lastPlayed!.console),
                  onPlay: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameDetailPage(game: data.lastPlayed!)));
                    ref.invalidate(homeDashboardProvider);
                  },
                )
              else
                const Card(child: ListTile(leading: Icon(Icons.play_arrow), title: Text('Aún no hay un juego reciente'), subtitle: Text('Abre un juego para que aparezca aquí.'))),
              const SizedBox(height: 28),
              const Text('Consolas disponibles', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...byConsole.entries.map((entry) => Card(
                    child: ListTile(
                      leading: RetroHubConsoleIcon(console: entry.key),
                      title: Text(entry.key),
                      subtitle: Text('${entry.value.length} juego(s) • ${entry.value.take(3).map((game) => game.title).join(' • ')}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onConsoleSelected?.call(entry.key),
                    ),
                  )),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }
}
