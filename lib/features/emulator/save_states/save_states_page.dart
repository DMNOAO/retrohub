import 'dart:io';

import 'package:flutter/material.dart';

import '../data/models/save_slot.dart';
import '../data/save_state_service.dart';

enum SaveStatesMode {
  save,
  load,
}

class SaveStatesPage extends StatefulWidget {
  final String gameTitle;
  final SaveStatesMode mode;
  final SaveStateService service;
  final Future<bool> Function(int slot, String title) onSave;
  final Future<bool> Function(int slot) onLoad;
  final bool confirmBeforeOverwrite;

  const SaveStatesPage({
    super.key,
    required this.gameTitle,
    required this.mode,
    required this.service,
    required this.onSave,
    required this.onLoad,
    this.confirmBeforeOverwrite = true,
  });

  @override
  State<SaveStatesPage> createState() => _SaveStatesPageState();
}

class _SaveStatesPageState extends State<SaveStatesPage> {
  late Future<List<SaveSlot>> _slotsFuture;
  int? _busySlot;

  bool get _isSaveMode => widget.mode == SaveStatesMode.save;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _slotsFuture = widget.service.loadSlots();
  }

  Future<void> _handleSlot(SaveSlot slot) async {
    if (_busySlot != null) return;

    if (!_isSaveMode && !slot.exists) {
      _showMessage('Este slot está vacío');
      return;
    }

    if (_isSaveMode) {
      final String? title = await _askForTitle(slot);

      if (title == null || !mounted) return;

      if (slot.exists && widget.confirmBeforeOverwrite) {
        final bool overwrite = await _confirmOverwrite(slot);
        if (!overwrite || !mounted) return;
      }

      setState(() {
        _busySlot = slot.slot;
      });

      final bool saved = await widget.onSave(slot.slot, title);

      if (saved) {
        await widget.service.markLastUsed(slot.slot);
      }

      if (!mounted) return;

      setState(() {
        _busySlot = null;
        _reload();
      });

      _showMessage(
        saved
            ? 'Slot ${slot.slot} guardado correctamente'
            : 'No se pudo guardar el slot ${slot.slot}',
      );

      return;
    }

    setState(() {
      _busySlot = slot.slot;
    });

    final bool loaded = await widget.onLoad(slot.slot);

    if (loaded) {
      await widget.service.markLastUsed(slot.slot);
    }

    if (!mounted) return;

    setState(() {
      _busySlot = null;
    });

    if (loaded) {
      Navigator.of(context).pop(true);
    } else {
      _showMessage('No se pudo cargar el slot ${slot.slot}');
    }
  }

  Future<String?> _askForTitle(SaveSlot slot) async {
    String draft = slot.exists ? slot.title : 'Slot ${slot.slot}';

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            slot.exists
                ? 'Sobrescribir Slot ${slot.slot}'
                : 'Guardar en Slot ${slot.slot}',
          ),
          content: TextFormField(
            initialValue: draft,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Nombre del estado',
              hintText: 'Ejemplo: Antes del gimnasio',
            ),
            onChanged: (String value) => draft = value,
            onFieldSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(draft.trim());
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmOverwrite(SaveSlot slot) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('¿Sobrescribir estado?'),
              content: Text(
                'El contenido actual del Slot ${slot.slot} será reemplazado.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(true),
                  child: const Text('Sobrescribir'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _renameSlot(SaveSlot slot) async {
    String draft = slot.title;

    final String? title = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Renombrar Slot ${slot.slot}'),
          content: TextFormField(
            initialValue: draft,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Nuevo nombre',
            ),
            onChanged: (String value) => draft = value,
            onFieldSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(draft.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (title == null || title.trim().isEmpty) return;

    await widget.service.renameSlot(
      slot: slot.slot,
      title: title,
    );

    if (!mounted) return;

    setState(_reload);
    _showMessage('Slot ${slot.slot} renombrado');
  }

  Future<void> _toggleFavorite(SaveSlot slot) async {
    await widget.service.toggleFavorite(slot.slot);

    if (!mounted) return;

    setState(_reload);

    _showMessage(
      slot.isFavorite
          ? 'Slot ${slot.slot} quitado de favoritos'
          : 'Slot ${slot.slot} marcado como favorito',
    );
  }

  Future<void> _deleteSlot(SaveSlot slot) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Eliminar Slot ${slot.slot}'),
              content: const Text(
                'Esta acción eliminará el estado, su miniatura '
                'y sus datos. No se puede deshacer.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await widget.service.deleteSlot(slot.slot);

    if (!mounted) return;

    setState(_reload);
    _showMessage('Slot ${slot.slot} eliminado');
  }

  Future<void> _showActions(SaveSlot slot) async {
    if (!slot.exists || _busySlot != null) return;

    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Renombrar'),
                onTap: () =>
                    Navigator.of(sheetContext).pop('rename'),
              ),
              ListTile(
                leading: Icon(
                  slot.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                ),
                title: Text(
                  slot.isFavorite
                      ? 'Quitar de favoritos'
                      : 'Marcar como favorito',
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop('favorite'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Eliminar'),
                onTap: () =>
                    Navigator.of(sheetContext).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    switch (action) {
      case 'rename':
        await _renameSlot(slot);
        break;
      case 'favorite':
        await _toggleFavorite(slot);
        break;
      case 'delete':
        await _deleteSlot(slot);
        break;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSaveMode ? 'Guardar estado' : 'Cargar estado',
        ),
      ),
      body: FutureBuilder<List<SaveSlot>>(
        future: _slotsFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<SaveSlot>> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron leer los slots:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<SaveSlot> slots =
              snapshot.data ?? <SaveSlot>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _HeaderCard(
                gameTitle: widget.gameTitle,
                isSaveMode: _isSaveMode,
              ),
              const SizedBox(height: 20),
              for (int index = 0; index < slots.length; index++) ...[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds: 260 + (index * 70),
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (
                    BuildContext context,
                    double value,
                    Widget? child,
                  ) {
                    return Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _SaveSlotCard(
                    slot: slots[index],
                    busy: _busySlot == slots[index].slot,
                    onTap: () => _handleSlot(slots[index]),
                    onMore: slots[index].exists
                        ? () => _showActions(slots[index])
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String gameTitle;
  final bool isSaveMode;

  const _HeaderCard({
    required this.gameTitle,
    required this.isSaveMode,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer,
            colors.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSaveMode
                  ? Icons.save_rounded
                  : Icons.restore_rounded,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  isSaveMode
                      ? 'Elige dónde guardar este momento.'
                      : 'Regresa a uno de tus momentos guardados.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveSlotCard extends StatelessWidget {
  final SaveSlot slot;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  const _SaveSlotCard({
    required this.slot,
    required this.busy,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final String? thumbnailPath = slot.thumbnailPath;
    final bool hasThumbnail =
        thumbnailPath != null && File(thumbnailPath).existsSync();
    final ColorScheme colors = Theme.of(context).colorScheme;

    Widget thumbnail({required double width, required double height}) {
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasThumbnail
                ? Image.file(
                    File(thumbnailPath),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) =>
                        const _EmptyThumbnail(),
                  )
                : const _EmptyThumbnail(),
            if (slot.isFavorite)
              const Positioned(
                top: 12,
                left: 12,
                child: _FavoriteBadge(),
              ),
          ],
        ),
      );
    }

    Widget details() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: busy
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SLOT ${slot.slot}',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const Spacer(),
                      if (onMore != null)
                        IconButton(
                          tooltip: 'Más opciones',
                          onPressed: onMore,
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.exists ? slot.title : 'Vacío',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  if (slot.exists) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: slot.formattedPlayTime,
                        ),
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: slot.formattedDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Último uso: ${slot.formattedLastUsed}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else
                    Text(
                      'Disponible para guardar',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                ],
              ),
      );
    }

    return Card(
      elevation: slot.isFavorite ? 5 : 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: slot.isFavorite
              ? colors.primary
              : colors.outlineVariant.withValues(alpha: 0.6),
          width: slot.isFavorite ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: busy ? null : onTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 620;

            if (compact) {
              return SizedBox(
                height: 330,
                child: Column(
                  children: [
                    thumbnail(
                      width: double.infinity,
                      height: 150,
                    ),
                    Expanded(child: details()),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 190,
              child: Row(
                children: [
                  thumbnail(width: 260, height: double.infinity),
                  Expanded(child: details()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _FavoriteBadge extends StatelessWidget {
  const _FavoriteBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 16,
              color: Colors.amber,
            ),
            SizedBox(width: 5),
            Text(
              'Favorito',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyThumbnail extends StatelessWidget {
  const _EmptyThumbnail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          size: 58,
          color: Colors.white.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}
