import 'dart:async';

import 'package:flutter/material.dart';

/// Botón flotante tipo "chat head" para RetroHub.
///
/// Widget completamente independiente: administra su propia apertura,
/// cierre, animación y overlay. El único punto de contacto con quien lo
/// use es [onAction], que recibe exactamente los mismos valores que ya
/// procesa `_handleMenuAction` en `EmulatorPage`:
/// `open_journal`, `save_state`, `load_state`, `settings`, `exit`.
class RetroHubQuickMenu extends StatefulWidget {
  const RetroHubQuickMenu({
    super.key,
    required this.onAction,
  });

  final ValueChanged<String> onAction;

  @override
  State<RetroHubQuickMenu> createState() => _RetroHubQuickMenuState();
}

class _RetroHubQuickMenuState extends State<RetroHubQuickMenu>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 220);

  final GlobalKey _anchorKey = GlobalKey();

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    if (_isOpen) return;

    _insertOverlay();
    setState(() => _isOpen = true);
    _controller.forward(from: 0);
  }

  Future<void> _close() async {
    if (!_isOpen) return;

    await _controller.reverse();
    _removeOverlay();
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _handleSelect(String value) {
    unawaited(_close());
    widget.onAction(value);
  }

  void _insertOverlay() {
    final RenderBox? renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset anchorGlobal = renderBox.localToGlobal(Offset.zero);
    final Size anchorSize = renderBox.size;
    final Offset anchorCenter = anchorGlobal +
        Offset(anchorSize.width / 2, anchorSize.height / 2);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return _RetroHubQuickMenuOverlay(
          fade: _fade,
          scale: _scale,
          anchorCenter: anchorCenter,
          onBarrierTap: _close,
          onSelect: _handleSelect,
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return _RetroHubQuickMenuAnchorButton(
      key: _anchorKey,
      isOpen: _isOpen,
      onPressed: _toggle,
    );
  }
}

/// Botón circular visible siempre. Alterna entre círculo vacío (cerrado)
/// y una "X" (abierto). Esta es la única pieza que vive dentro del árbol
/// normal (colocada vía [Positioned] por quien use [RetroHubQuickMenu]);
/// el resto del menú se dibuja en un [OverlayEntry] aparte.
class _RetroHubQuickMenuAnchorButton extends StatelessWidget {
  const _RetroHubQuickMenuAnchorButton({
    super.key,
    required this.isOpen,
    required this.onPressed,
  });

  final bool isOpen;
  final VoidCallback onPressed;

  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isOpen
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: isOpen
                ? const Icon(
                    Icons.close,
                    key: ValueKey('quick_menu_open'),
                    color: Colors.white,
                    size: 22,
                  )
                : const SizedBox.shrink(key: ValueKey('quick_menu_closed')),
          ),
        ),
      ),
    );
  }
}

/// Contenido que se inserta en el [Overlay]: la barrera invisible para
/// cerrar al tocar fuera, y las cinco opciones distribuidas en arco hacia
/// abajo-izquierda del botón ancla.
///
/// El ancla vive fija en la esquina superior derecha (justo debajo del
/// AppBar, pegada al borde derecho), así que NO hay espacio real ni hacia
/// arriba ni hacia la derecha: cualquier ítem colocado ahí queda recortado
/// por el `Stack` (su `clipBehavior` por defecto es `Clip.hardEdge`), que
/// es exactamente lo que causaba que el menú pareciera "expandirse solo
/// hacia abajo". Por eso el abanico completo usa offsets con
/// `dx <= 0` y `dy >= 0`: un cuarto de círculo desde "recto hacia abajo"
/// hasta "recto hacia la izquierda", el único cuadrante garantizado libre
/// sin importar el tamaño de la ventana.
class _RetroHubQuickMenuOverlay extends StatelessWidget {
  const _RetroHubQuickMenuOverlay({
    required this.fade,
    required this.scale,
    required this.anchorCenter,
    required this.onBarrierTap,
    required this.onSelect,
  });

  final Animation<double> fade;
  final Animation<double> scale;
  final Offset anchorCenter;
  final VoidCallback onBarrierTap;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickMenuItemData>[
      _QuickMenuItemData(
        emoji: '📖',
        label: 'Bitácora',
        action: 'open_journal',
        offset: const Offset(-10, 145),
      ),
      _QuickMenuItemData(
        emoji: '💾',
        label: 'Guardar estado',
        action: 'save_state',
        offset: const Offset(-55, 118),
      ),
      _QuickMenuItemData(
        emoji: '📂',
        label: 'Cargar estado',
        action: 'load_state',
        offset: const Offset(-105, 82),
      ),
      _QuickMenuItemData(
        emoji: '⚙️',
        label: 'Configuración',
        action: 'settings',
        offset: const Offset(-145, 38),
      ),
      _QuickMenuItemData(
        emoji: '🚪',
        label: 'Salir',
        action: 'exit',
        offset: const Offset(-165, 0),
      ),
    ];

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBarrierTap,
              child: const SizedBox.expand(),
            ),
          ),
          for (final item in items)
            Positioned(
              left: anchorCenter.dx + item.offset.dx - (_itemSize / 2),
              top: anchorCenter.dy + item.offset.dy - (_itemSize / 2),
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  alignment: Alignment.center,
                  child: _QuickMenuItemButton(
                    data: item,
                    onSelect: onSelect,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const double _itemSize = 44;

class _QuickMenuItemData {
  const _QuickMenuItemData({
    required this.emoji,
    required this.label,
    required this.action,
    required this.offset,
  });

  final String emoji;
  final String label;
  final String action;
  final Offset offset;
}

class _QuickMenuItemButton extends StatelessWidget {
  const _QuickMenuItemButton({
    required this.data,
    required this.onSelect,
  });

  final _QuickMenuItemData data;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(data.action),
          customBorder: const CircleBorder(),
          child: Container(
            width: _itemSize,
            height: _itemSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              data.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}