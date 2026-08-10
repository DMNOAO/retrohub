import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/play_time_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

class ProfileStats {
  final List<Game> games;
  final int events;
  final int entries;

  const ProfileStats(this.games, this.events, this.entries);
}

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final db = ref.watch(databaseProvider);
  return ProfileStats(
    await db.getAllGames(),
    await db.countProgressEvents(),
    await db.countJournalEntries(),
  );
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileStatsProvider);

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          final totalSeconds = stats.games.fold<int>(
            0,
            (sum, game) => sum + game.playTimeSeconds,
          );

          final consoles = <String, int>{};
          for (final game in stats.games) {
            consoles[game.console] =
                (consoles[game.console] ?? 0) + game.playTimeSeconds;
          }

          final favorite = consoles.entries.isEmpty
              ? null
              : (consoles.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .first;

          final last = stats.games.where((g) => g.lastPlayedAt != null).toList()
            ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 24),
              const _GoogleSignInCard(),
              const SizedBox(height: 28),
              const _SectionTitle('Estadísticas'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    'Juegos',
                    '${stats.games.length}',
                    Icons.videogame_asset,
                  ),
                  _StatCard(
                    'Tiempo total',
                    PlayTimeFormatter.fromSeconds(totalSeconds),
                    Icons.timer,
                  ),
                  _StatCard(
                    'Eventos',
                    '${stats.events}',
                    Icons.auto_stories,
                  ),
                  _StatCard(
                    'Entradas',
                    '${stats.entries}',
                    Icons.menu_book,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.stars),
                      title: const Text('Consola favorita'),
                      subtitle: Text(favorite?.key ?? 'Sin datos todavía'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Último juego abierto'),
                      subtitle: Text(
                        last.isEmpty ? 'Sin datos todavía' : last.first.title,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('RetroHub Cloud'),
              const SizedBox(height: 12),
              const _CloudCard(),
              const SizedBox(height: 28),
              const _SectionTitle('Tiempo por consola'),
              const SizedBox(height: 8),
              if (consoles.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text(
                      'Juega una partida para comenzar tus estadísticas.',
                    ),
                  ),
                )
              else
                ...consoles.entries.map(
                  (e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.memory),
                      title: Text(e.key),
                      trailing: Text(
                        PlayTimeFormatter.fromSeconds(e.value),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 48,
          child: Icon(Icons.person, size: 52),
        ),
        SizedBox(height: 12),
        Text(
          'Jugador RetroHub',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Tu perfil de juego',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _GoogleSignInCard extends StatelessWidget {
  const _GoogleSignInCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.account_circle_outlined, size: 42),
            const SizedBox(height: 10),
            const Text(
              'Conecta tu cuenta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inicia sesión para preparar la sincronización de tus partidas entre dispositivos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null,
                icon: Icon(Icons.login),
                label: Text('Iniciar sesión con Google'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Google Sign-In se habilitará en el siguiente paso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudCard extends StatelessWidget {
  const _CloudCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_outlined, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin sincronización',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tus partidas continúan guardándose localmente. Cuando conectemos Google, RetroHub Cloud permitirá respaldarlas y recuperarlas en otro dispositivo.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Los guardados locales no se modifican en esta etapa.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: Colors.white70,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
