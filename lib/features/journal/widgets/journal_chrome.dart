import 'package:flutter/material.dart';

class JournalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onRefresh;

  const JournalAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: kToolbarHeight + 8,
      automaticallyImplyLeading: false,
      leadingWidth: canPop ? 68 : 16,
      leading: canPop
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton.filledTonal(
                tooltip: 'Atrás',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            )
          : null,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 27),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      actions: [
        if (onRefresh != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: 'Actualizar',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
      ],
    );
  }
}

class JournalSection {
  final String id;
  final String label;
  final IconData icon;

  const JournalSection(this.id, this.label, this.icon);
}

class JournalSectionBar extends StatelessWidget {
  final List<JournalSection> sections;
  final String selected;
  final ValueChanged<String> onSelected;

  const JournalSectionBar({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: sections.map((section) {
              final active = section.id == selected;
              return Semantics(
                selected: active,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelected(section.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 92,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? scheme.primaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          section.icon,
                          size: 24,
                          color: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          section.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
