import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/cover_helper.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../journal/journal_page.dart';

class JournalGameSummary {
  final Game game;
  final GameProgressSnapshot? snapshot;
  final int eventCount;
  final int manualEntryCount;

  const JournalGameSummary({
    required this.game,
    required this.snapshot,
    required this.eventCount,
    required this.manualEntryCount,
  });

  bool get hasJournal => snapshot != null || eventCount > 0 || manualEntryCount > 0;
}

final journalDashboardProvider = FutureProvider.autoDispose<List<JournalGameSummary>>((ref) async {
  final database = ref.watch(databaseProvider);
  final games = await database.getAllGames();
  final summaries = <JournalGameSummary>[];

  for (final game in games) {
    final snapshot = await database.getLatestProgressSnapshot(game.id);
    final events = await database.getProgressEventsByGame(game.id);
    final entries = await database.getJournalEntriesByGame(game.id);
    final summary = JournalGameSummary(
      game: game,
      snapshot: snapshot,
      eventCount: events.length,
      manualEntryCount: entries.length,
    );
    if (summary.hasJournal) summaries.add(summary);
  }

  summaries.sort((a, b) {
    final aDate = a.snapshot?.savedAt ?? a.game.lastPlayedAt ?? a.game.createdAt;
    final bDate = b.snapshot?.savedAt ?? b.game.lastPlayedAt ?? b.game.createdAt;
    return bDate.compareTo(aDate);
  });
  return summaries;
});

class JournalDashboardPage extends ConsumerWidget {
  const JournalDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(journalDashboardProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Todavía no hay juegos con progreso o eventos registrados.\nAbre una partida compatible y RetroHub creará su bitácora.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(journalDashboardProvider.future),
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              mainAxisExtent: 190,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final snapshot = item.snapshot;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => JournalPage(game: item.game)),
                    );
                    ref.invalidate(journalDashboardProvider);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 95,
                          child: _Cover(path: CoverHelper.getCover(item.game.title, item.game.console)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.game.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                item.game.console,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(snapshot?.currentLocation ?? 'Bitácora disponible',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text(
                                snapshot == null
                                    ? '${item.eventCount} eventos • ${item.manualEntryCount} entradas'
                                    : '${snapshot.badgesCount} medallas • ${snapshot.pokedexCaught} capturados • ${item.eventCount} eventos',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  final String? path;
  const _Cover({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null) return const Icon(Icons.videogame_asset, size: 48);
    return Image.asset(path!, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, size: 48));
  }
}
