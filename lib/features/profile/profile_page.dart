import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/play_time_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

class ProfileStats {
  final List<Game> games; final int events; final int entries;
  const ProfileStats(this.games, this.events, this.entries);
}
final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final db = ref.watch(databaseProvider);
  return ProfileStats(await db.getAllGames(), await db.countProgressEvents(), await db.countJournalEntries());
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileStatsProvider);
    return Scaffold(appBar: AppBar(title: const Text('Perfil')), body: async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        final totalSeconds = stats.games.fold<int>(0, (sum, game) => sum + game.playTimeSeconds);
        final consoles = <String, int>{};
        for (final game in stats.games) { consoles[game.console] = (consoles[game.console] ?? 0) + game.playTimeSeconds; }
        final favorite = consoles.entries.isEmpty ? null : (consoles.entries.toList()..sort((a,b)=>b.value.compareTo(a.value))).first;
        final last = stats.games.where((g)=>g.lastPlayedAt != null).toList()..sort((a,b)=>b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
        return ListView(padding: const EdgeInsets.all(24), children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 52)), const SizedBox(height: 12),
          const Center(child: Text('Jugador RetroHub', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _StatCard('Juegos', '${stats.games.length}', Icons.videogame_asset),
            _StatCard('Tiempo total', PlayTimeFormatter.fromSeconds(totalSeconds), Icons.timer),
            _StatCard('Eventos', '${stats.events}', Icons.auto_stories),
            _StatCard('Entradas', '${stats.entries}', Icons.menu_book),
          ]),
          const SizedBox(height: 24),
          Card(child: Column(children: [
            ListTile(leading: const Icon(Icons.stars), title: const Text('Consola favorita'), subtitle: Text(favorite?.key ?? 'Sin datos todavía')),
            ListTile(leading: const Icon(Icons.history), title: const Text('Último juego abierto'), subtitle: Text(last.isEmpty ? 'Sin datos todavía' : last.first.title)),
          ])),
          const SizedBox(height: 18), const Text('Tiempo por consola', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (consoles.isEmpty) const Card(child: ListTile(title: Text('Juega una partida para comenzar tus estadísticas.')))
          else ...consoles.entries.map((e)=>Card(child: ListTile(leading: const Icon(Icons.memory), title: Text(e.key), trailing: Text(PlayTimeFormatter.fromSeconds(e.value))))),
        ]);
      },
    ));
  }
}
class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon;
  const _StatCard(this.label, this.value, this.icon);
  @override Widget build(BuildContext context) => SizedBox(width: 190, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Icon(icon, size: 30), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white70))]))));
}
