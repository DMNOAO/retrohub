import 'package:flutter/material.dart';

import '../../data/database/app_database.dart';
import 'frame_catalog.dart';
import 'frame_preferences.dart';

class FramesPage extends StatefulWidget {
  final Game game;

  const FramesPage({super.key, required this.game});

  @override
  State<FramesPage> createState() => _FramesPageState();
}

class _FramesPageState extends State<FramesPage> {
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final selected = await FramePreferences.load(widget.game.id);
    if (!mounted) return;
    setState(() {
      _selectedId = selected;
      _loading = false;
    });
  }

  Future<void> _select(String? id) async {
    await FramePreferences.save(widget.game.id, id);
    if (!mounted) return;
    setState(() => _selectedId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(id == null ? 'Marco desactivado' : 'Marco guardado para ${widget.game.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frames = FrameCatalog.forGame(widget.game);
    final recommended = FrameCatalog.recommendedFor(widget.game);

    return Scaffold(
      appBar: AppBar(title: const Text('Marcos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.game.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'El marco se mostrará en modo horizontal y pantalla completa.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _FrameTile(
                  name: 'Sin marco',
                  selected: _selectedId == null,
                  onTap: () => _select(null),
                ),
                if (frames.isEmpty) ...[
                  const SizedBox(height: 18),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Todavía no hay marcos compatibles con la proporción de esta consola. Puedes jugar a pantalla completa sin marco.',
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: frames.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.55,
                    ),
                    itemBuilder: (context, index) {
                      final frame = frames[index];
                      return _FrameTile(
                        name: frame.name,
                        assetPath: frame.assetPath,
                        selected: _selectedId == frame.id,
                        recommended: frame.id == recommended?.id,
                        onTap: () => _select(frame.id),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }
}

class _FrameTile extends StatelessWidget {
  final String name;
  final String? assetPath;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  const _FrameTile({
    required this.name,
    this.assetPath,
    required this.selected,
    this.recommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 3 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (assetPath == null)
              ColoredBox(
                color: colors.surfaceContainerHighest,
                child: const Icon(Icons.hide_image_outlined, size: 42),
              )
            else
              Image.asset(
                assetPath!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                color: Colors.black.withValues(alpha: .78),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (recommended)
              const Positioned(
                top: 8,
                left: 8,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Recomendado'),
                ),
              ),
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: const Icon(Icons.check, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
