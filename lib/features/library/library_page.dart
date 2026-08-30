import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/cover_helper.dart';
import '../widgets/dynamic_game_banner.dart';
import '../../data/repositories/games_repository_provider.dart';
import '../game_detail/game_detail_page.dart';
import 'services/rom_service.dart';
import 'services/rom_storage_service.dart';
import 'widgets/game_cover_card.dart';

final gamesProvider = FutureProvider((ref) {
  final repository = ref.watch(gamesRepositoryProvider);
  return repository.getGames();
});

enum LibrarySortOption {
  recent,
  nameAsc,
  nameDesc,
  console,
  playTime,
}

class LibraryPage extends ConsumerStatefulWidget {
  final String? initialConsoleFilter;

  const LibraryPage({super.key, this.initialConsoleFilter});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _searchText = '';
  String? _consoleFilter;

  @override
  void initState() {
    super.initState();
    _consoleFilter = widget.initialConsoleFilter;
  }
  LibrarySortOption _sortOption = LibrarySortOption.recent;
  bool _refreshingLibrary = false;
  final ScrollController _gridScrollController = ScrollController();

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  Future<void> _importRom(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gb', 'gbc', 'gba', 'smc', 'sfc', 'nds'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final romInfo = RomService.parseRom(file.path!, file.name);

    if (romInfo == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato no compatible')),
      );
      return;
    }

    final repository = ref.read(gamesRepositoryProvider);

    // Nunca se juega desde la ruta que entrega file_picker: es una copia
    // en caché que Android puede borrar en cualquier momento. Se copia
    // primero a una carpeta permanente de RetroHub.
    final String extension = file.name.split('.').last.toLowerCase();
    final ImportedRom imported = await RomStorageService.importRom(
      sourcePath: file.path!,
      console: romInfo.console,
      extension: extension,
    );

    final bool existedBefore = await repository.gameExists(imported.hash);

    await repository.addGame(
      id: imported.hash,
      title: romInfo.title,
      console: romInfo.console,
      romPath: imported.path,
    );

    ref.invalidate(gamesProvider);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existedBefore
              ? '${romInfo.title} ya estaba en tu biblioteca — se conservó tu partida'
              : '${romInfo.title} importado correctamente',
        ),
      ),
    );
  }

  Future<void> _deleteGameFromLibrary(dynamic game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quitar de la biblioteca'),
          content: Text(
            '¿Quieres quitar "${game.title}" de RetroHub?\n\n'
            'Esto no eliminará el archivo ROM de tu equipo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Quitar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final repository = ref.read(gamesRepositoryProvider);
    await repository.deleteGame(game.id);

    ref.invalidate(gamesProvider);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${game.title} quitado de la biblioteca')),
    );
  }

  Future<void> _refreshLibrary() async {
    setState(() {
      _refreshingLibrary = true;
    });

    try {
      final repository = ref.read(gamesRepositoryProvider);
      final games = await repository.getGames();

      int removed = 0;

      for (final game in games) {
        final exists = await File(game.romPath).exists();

        if (!exists) {
          await repository.deleteGame(game.id);
          removed++;
        }
      }

      ref.invalidate(gamesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removed == 0
                ? 'Biblioteca actualizada. No se encontraron ROMs faltantes.'
                : 'Biblioteca actualizada. Se quitaron $removed ROMs faltantes.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshingLibrary = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: gamesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
              data: (games) {
                final bool isCompact = MediaQuery.sizeOf(context).width < 700;

                if (games.isEmpty) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _importRom(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Importar ROM'),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Aún no has importado juegos',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final playedGames = games.where((game) => game.lastPlayedAt != null).toList();
                playedGames.sort((a, b) =>
                    (b.lastPlayedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
                      a.lastPlayedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                    ));
                final recentGame = playedGames.isEmpty ? null : playedGames.first;

                final filteredGames = games.where((game) {
                  if (game.id == recentGame?.id) return false;
                  final query = _searchText.toLowerCase();
                  final matchesText = game.title.toLowerCase().contains(query) ||
                      game.console.toLowerCase().contains(query);
                  final matchesConsole = _consoleFilter == null ||
                      game.console.toLowerCase() == _consoleFilter!.toLowerCase();
                  return matchesText && matchesConsole;
                }).toList();

                switch (_sortOption) {
                  case LibrarySortOption.recent:
                    filteredGames.sort((a, b) {
                      final aDate = a.lastPlayedAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final bDate = b.lastPlayedAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final byRecent = bDate.compareTo(aDate);
                      return byRecent != 0
                          ? byRecent
                          : a.title.compareTo(b.title);
                    });
                    break;
                  case LibrarySortOption.nameAsc:
                    filteredGames.sort((a, b) => a.title.compareTo(b.title));
                    break;
                  case LibrarySortOption.nameDesc:
                    filteredGames.sort((a, b) => b.title.compareTo(a.title));
                    break;
                  case LibrarySortOption.console:
                    filteredGames.sort(
                      (a, b) => a.console.compareTo(b.console),
                    );
                    break;
                  case LibrarySortOption.playTime:
                    filteredGames.sort(
                      (a, b) => b.playTimeSeconds.compareTo(a.playTimeSeconds),
                    );
                    break;
                }

                return Scrollbar(
                  controller: _gridScrollController,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _gridScrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                    if (recentGame != null) DynamicGameBanner(
                      game: recentGame,
                      coverPath: CoverHelper.getCover(recentGame.title, recentGame.console),
                      height: isCompact ? 140 : 180,
                      onPlay: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameDetailPage(game: recentGame),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_consoleFilter != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          label: Text('Consola: ${_consoleFilter!}'),
                          onDeleted: () => setState(() => _consoleFilter = null),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (isCompact) ...[
                      SizedBox(
                        height: 46,
                        child: TextField(
                          onChanged: (value) => setState(() => _searchText = value),
                          decoration: InputDecoration(
                            hintText: 'Buscar juego...',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: FilledButton.icon(
                                onPressed: () => _importRom(context, ref),
                                icon: const Icon(Icons.add),
                                label: const Text('Importar'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Actualizar biblioteca',
                            onPressed: _refreshingLibrary ? null : _refreshLibrary,
                            icon: _refreshingLibrary
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<LibrarySortOption>(
                            tooltip: 'Ordenar y filtrar',
                            initialValue: _sortOption,
                            onSelected: (value) => setState(() => _sortOption = value),
                            icon: const Icon(Icons.filter_list),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: LibrarySortOption.recent,
                                child: Text('Jugados recientemente'),
                              ),
                              PopupMenuItem(
                                value: LibrarySortOption.nameAsc,
                                child: Text('Nombre A-Z'),
                              ),
                              PopupMenuItem(
                                value: LibrarySortOption.nameDesc,
                                child: Text('Nombre Z-A'),
                              ),
                              PopupMenuItem(
                                value: LibrarySortOption.console,
                                child: Text('Consola'),
                              ),
                              PopupMenuItem(
                                value: LibrarySortOption.playTime,
                                child: Text('Horas jugadas'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchText = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar juego...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: () => _importRom(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Importar ROM'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed:
                                _refreshingLibrary ? null : _refreshLibrary,
                            icon: _refreshingLibrary
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: const Text('Actualizar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<LibrarySortOption>(
                          value: _sortOption,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _sortOption = value;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: LibrarySortOption.recent,
                              child: Text('Jugados recientemente'),
                            ),
                            DropdownMenuItem(
                              value: LibrarySortOption.nameAsc,
                              child: Text('Nombre A-Z'),
                            ),
                            DropdownMenuItem(
                              value: LibrarySortOption.nameDesc,
                              child: Text('Nombre Z-A'),
                            ),
                            DropdownMenuItem(
                              value: LibrarySortOption.console,
                              child: Text('Consola'),
                            ),
                            DropdownMenuItem(
                              value: LibrarySortOption.playTime,
                              child: Text('Horas jugadas'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredGames.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: Text('No se encontraron juegos')),
                      )
                    else
                      GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredGames.length,
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: isCompact ? 180 : 230,
                                mainAxisSpacing: isCompact ? 12 : 20,
                                crossAxisSpacing: isCompact ? 12 : 20,
                                // Sin el bloque de título, la tarjeta ya no
                                // necesita reservar su antigua altura total.
                                // En Android conserva el tamaño que tenía la
                                // imagen antes, evitando ampliarla y recortarla.
                                childAspectRatio: isCompact ? 1.02 : 0.78,
                              ),
                              itemBuilder: (context, index) {
                                final game = filteredGames[index];
                                final cover = CoverHelper.getCover(
                                  game.title,
                                  game.console,
                                );

                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: GameCoverCard(
                                        title: game.title,
                                        console: '',
                                        coverPath: cover,
                                        coverOnly: true,
                                        onTap: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  GameDetailPage(game: game),
                                            ),
                                          );
                                          ref.invalidate(gamesProvider);
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: PopupMenuButton<String>(
                                        tooltip: 'Opciones',
                                        icon: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.55),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Icon(
                                            Icons.more_vert,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            _deleteGameFromLibrary(game);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline),
                                                SizedBox(width: 10),
                                                Text('Quitar de biblioteca'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                  ],
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}
