import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/play_time_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import 'auth/auth_provider.dart';
import 'auth/retrohub_user.dart';

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
    final auth = ref.watch(authUserProvider);
    final user = auth.value;

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
              _ProfileHeader(user: user),
              const SizedBox(height: 24),
              _GoogleSignInCard(auth: auth, user: user),
              const SizedBox(height: 28),
              const _SectionTitle('Estadísticas'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard('Juegos', '${stats.games.length}', Icons.videogame_asset),
                  _StatCard(
                    'Tiempo total',
                    PlayTimeFormatter.fromSeconds(totalSeconds),
                    Icons.timer,
                  ),
                  _StatCard('Eventos', '${stats.events}', Icons.auto_stories),
                  _StatCard('Entradas', '${stats.entries}', Icons.menu_book),
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
                      subtitle: Text(last.isEmpty ? 'Sin datos todavía' : last.first.title),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('RetroHub Cloud'),
              const SizedBox(height: 12),
              _CloudCard(user: user),
              const SizedBox(height: 28),
              const _SectionTitle('Tiempo por consola'),
              const SizedBox(height: 8),
              if (consoles.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Juega una partida para comenzar tus estadísticas.'),
                  ),
                )
              else
                ...consoles.entries.map(
                  (e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.memory),
                      title: Text(e.key),
                      trailing: Text(PlayTimeFormatter.fromSeconds(e.value)),
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
  final RetroHubUser? user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final photo = user?.photoUrl;

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: photo == null ? null : NetworkImage(photo),
          child: photo == null ? const Icon(Icons.person, size: 52) : null,
        ),
        const SizedBox(height: 12),
        Text(
          user?.displayName ?? 'Jugador RetroHub',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'Tu perfil de juego',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _GoogleSignInCard extends ConsumerWidget {
  final AsyncValue<RetroHubUser?> auth;
  final RetroHubUser? user;

  const _GoogleSignInCard({required this.auth, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = auth.isLoading;

    Future<void> signIn() async {
      try {
        await ref.read(googleAuthServiceProvider).signIn();
        ref.invalidate(authUserProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar sesión: $e')),
        );
      }
    }

    Future<void> signOut() async {
      try {
        await ref.read(googleAuthServiceProvider).signOut();
        ref.invalidate(authUserProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cerrar sesión: $e')),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(user == null ? Icons.account_circle_outlined : Icons.verified_user_outlined, size: 42),
            const SizedBox(height: 10),
            Text(
              user == null ? 'Conecta tu cuenta' : 'Cuenta conectada',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              user == null
                  ? 'Inicia sesión para preparar la sincronización de tus partidas entre dispositivos.'
                  : 'Tu cuenta de Google está conectada a este perfil de RetroHub.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : (user == null ? signIn : signOut),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(user == null ? Icons.login : Icons.logout),
                label: Text(user == null ? 'Iniciar sesión con Google' : 'Cerrar sesión'),
              ),
            ),
            if (auth.hasError) ...[
              const SizedBox(height: 8),
              Text(
                'No se pudo restaurar la sesión anterior.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloudCard extends StatelessWidget {
  final RetroHubUser? user;

  const _CloudCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final connected = user != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(connected ? Icons.cloud_done_outlined : Icons.cloud_outlined, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected ? 'Cuenta lista para RetroHub Cloud' : 'Sin sincronización',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    connected
                        ? 'Google está conectado. En la siguiente etapa habilitaremos respaldo y restauración de partidas entre dispositivos.'
                        : 'Tus partidas continúan guardándose localmente. Conecta Google para preparar RetroHub Cloud.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Los guardados locales todavía no se modifican ni se suben a la nube.',
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
