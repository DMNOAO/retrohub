import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/emulation/core_loader.dart';
import '../../core/utils/play_time_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../shared/theme/app_appearance.dart';
import '../../shared/theme/appearance_provider.dart';
import 'auth/auth_provider.dart';
import 'auth/retrohub_user.dart';
import 'cloud/cloud_save_local_service.dart';
import 'cloud/cloud_save_coordinator.dart';
import 'cloud/google_drive_save_service.dart';

class ProfileStats {
  final List<Game> games;
  final int events;
  final int entries;

  const ProfileStats(this.games, this.events, this.entries);
}

// Perfil se desmonta al cambiar de pestaña. autoDispose evita conservar una
// lectura antigua (por ejemplo, la lista vacía anterior a importar una ROM) y
// vuelve a consultar la misma base de datos que usa Biblioteca al regresar.
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
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
              const _SectionTitle('Apariencia'),
              const SizedBox(height: 12),
              const _AppearanceCard(),
              const SizedBox(height: 28),
              const _SectionTitle('Estadísticas'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.22,
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
              _CloudCard(user: user, games: stats.games),
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

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appearanceProvider).value ?? AppAppearance.crystal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema de la aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Elige una paleta inspirada en un juego o personaje.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 680
                    ? 4
                    : constraints.maxWidth >= 430
                        ? 3
                        : 2;
                const spacing = 10.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final category in AppearanceCategory.values) ...[
                      Text(
                        category.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: AppAppearance.forCategory(category)
                            .map((appearance) {
                          return SizedBox(
                            width: width,
                            child: _AppearanceOption(
                              appearance: appearance,
                              selected: selected == appearance,
                              onTap: () => ref
                                  .read(appearanceProvider.notifier)
                                  .select(appearance),
                            ),
                          );
                        }).toList(),
                      ),
                      if (category != AppearanceCategory.values.last)
                        const SizedBox(height: 22),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final AppAppearance appearance;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.appearance,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileForeground =
        ThemeData.estimateBrightnessForColor(appearance.surface) ==
                Brightness.dark
            ? Colors.white
            : Colors.black;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema ${appearance.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appearance.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: appearance.primary.withValues(
                alpha: selected ? 1 : 0.72,
              ),
              width: selected ? 2.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: appearance.primary.withValues(
                  alpha: selected ? 0.34 : 0.12,
                ),
                blurRadius: selected ? 12 : 6,
              ),
              if (selected)
                BoxShadow(
                  color: appearance.secondary.withValues(alpha: 0.24),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: appearance.spriteAsset != null
                    ? Image.asset(
                        appearance.spriteAsset!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      )
                    : Icon(
                        appearance.fallbackIcon,
                        color: appearance.primary,
                        size: 38,
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                appearance.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tileForeground,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PaletteDot(color: appearance.background),
                  const SizedBox(width: 5),
                  _PaletteDot(color: appearance.primary),
                  const SizedBox(width: 5),
                  _PaletteDot(color: appearance.secondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteDot extends StatelessWidget {
  final Color color;

  const _PaletteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white54
              : Colors.black54,
        ),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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

class _CloudCard extends ConsumerStatefulWidget {
  final RetroHubUser? user;
  final List<Game> games;

  const _CloudCard({
    required this.user,
    required this.games,
  });

  @override
  ConsumerState<_CloudCard> createState() => _CloudCardState();
}

class _CloudCardState extends ConsumerState<_CloudCard> {
  final CloudSaveLocalService _cloudSaveService = CloudSaveLocalService();

  String? _selectedGameId;
  bool _busy = false;
  String? _lastBackupPath;

  Game? get _selectedGame {
    if (widget.games.isEmpty) return null;

    final selectedId = _selectedGameId;
    if (selectedId != null) {
      for (final game in widget.games) {
        if (game.id == selectedId) return game;
      }
    }

    return widget.games.first;
  }

  Future<void> _uploadCloudBackup() async {
    final game = _selectedGame;
    if (game == null || _busy) return;

    setState(() => _busy = true);
    try {
      final backup = await CloudSaveCoordinator(
        authService: ref.read(googleAuthServiceProvider),
        localService: _cloudSaveService,
      ).uploadGame(
        gameId: game.id,
        gameTitle: game.title,
        romPath: game.romPath,
      );

      if (!mounted) return;
      setState(() => _lastBackupPath = backup.directory.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${game.title} guardado en Google Drive.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar en la nube: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreCloudBackup() async {
    final game = _selectedGame;
    if (game == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar partida'),
        content: Text(
          'Se restaurará la copia de ${game.title} desde Google Drive. '
          'RetroHub guardará una copia local de tu partida actual antes de reemplazarla. '
          'Hazlo con el juego cerrado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final cloudGameId = await _cloudGameId(game);
      final drive = GoogleDriveSaveService(
        authService: ref.read(googleAuthServiceProvider),
      );
      final root = Directory(
        '${CoreLoader.documentsDirectory.path}${Platform.pathSeparator}'
        'RetroHub${Platform.pathSeparator}cloud_downloads',
      );
      final downloaded = await drive.downloadBackup(
        gameId: cloudGameId,
        destinationRoot: root,
      );
      if (downloaded == null) {
        throw StateError('No existe un respaldo en Google Drive para este juego.');
      }

      final result = await _cloudSaveService.restoreBackup(
        backupDirectory: downloaded,
        gameId: game.id,
        romPath: game.romPath,
        romHash: cloudGameId,
        preserveCurrentSave: true,
      );

      if (!mounted) return;
      final previous = result.previousSaveBackup?.path;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            previous == null
                ? '${game.title} restaurado desde Google Drive.'
                : '${game.title} restaurado. Copia anterior: $previous',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo restaurar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.user != null;
    final selectedGame = _selectedGame;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  connected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_outlined,
                  size: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connected
                            ? 'Cuenta lista para RetroHub Cloud'
                            : 'Sin sincronización',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        connected
                            ? 'Guarda SRAM y RTC en el espacio privado de RetroHub en Google Drive y restaura la misma partida en otro dispositivo.'
                            : 'Tus partidas continúan guardándose localmente. Conecta Google para preparar RetroHub Cloud.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (connected) ...[
              const SizedBox(height: 18),
              if (widget.games.isEmpty)
                Text(
                  'No hay juegos importados para respaldar.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedGame?.id,
                  decoration: const InputDecoration(
                    labelText: 'Partida',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.games
                      .map(
                        (game) => DropdownMenuItem<String>(
                          value: game.id,
                          child: Text(
                            '${game.title} · ${game.console}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() {
                            _selectedGameId = value;
                            _lastBackupPath = null;
                          });
                        },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _uploadCloudBackup,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Guardar en la nube'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _restoreCloudBackup,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Restaurar'),
                      ),
                    ),
                  ],
                ),
                if (_lastBackupPath != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Copia local preparada y subida correctamente.\n$_lastBackupPath',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
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
                    'RetroHub Cloud guarda SRAM y RTC. No sube ROMs ni save states.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
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
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
