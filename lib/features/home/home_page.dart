import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/cover_helper.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../data/repositories/games_repository_provider.dart';
import '../game_detail/game_detail_page.dart';
import '../widgets/dynamic_game_banner.dart';

class HomeDashboardData {
  final List<Game> games;
  final Game? lastPlayed;
  final List<GameProgressEvent> events;

  const HomeDashboardData({
    required this.games,
    required this.lastPlayed,
    required this.events,
  });
}

final homeDashboardProvider = FutureProvider.autoDispose<HomeDashboardData>((ref) async {
  final repository = ref.watch(gamesRepositoryProvider);
  final database = ref.watch(databaseProvider);
  return HomeDashboardData(
    games: await repository.getGames(),
    lastPlayed: await repository.getLastPlayedGame(),
    events: await database.getRecentProgressEvents(limit: 6),
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
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade900, Colors.black],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RetroHub', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Preserva la historia de cada partida', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (data.lastPlayed != null)
                DynamicGameBanner(
                  game: data.lastPlayed!,
                  coverPath: CoverHelper.getCover(data.lastPlayed!.title, data.lastPlayed!.console),
                  onPlay: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => GameDetailPage(game: data.lastPlayed!)),
                    );
                    ref.invalidate(homeDashboardProvider);
                  },
                )
              else
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Aún no hay un juego reciente'),
                    subtitle: Text('Abre un juego para que aparezca aquí.'),
                  ),
                ),
              const SizedBox(height: 28),
              const Text('Consolas disponibles', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...byConsole.entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.memory),
                    title: Text(entry.key),
                    subtitle: Text('${entry.value.length} juego(s) • ${entry.value.take(3).map((game) => game.title).join(' • ')}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onConsoleSelected?.call(entry.key),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Actividad reciente', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              if (data.events.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.menu_book),
                    title: Text('La bitácora aún está vacía'),
                    subtitle: Text('Los cambios de ubicación, equipo y medallas aparecerán aquí.'),
                  ),
                )
              else
                ...data.events.map(
                  (event) => Card(
                    child: ListTile(
                      leading: Icon(_eventIcon(event.eventType)),
                      title: Text(event.title),
                      subtitle: Text(event.description ?? _formatDate(event.createdAt)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static IconData _eventIcon(String type) {
    if (type.contains('badge')) return Icons.workspace_premium;
    if (type.contains('location')) return Icons.place;
    if (type.contains('party')) return Icons.catching_pokemon;
    return Icons.menu_book;
  }

  static String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
