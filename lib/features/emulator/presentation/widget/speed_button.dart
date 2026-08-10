import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Botón de velocidad de emulación, siempre visible, independiente del
/// Quick Menu. No define lógica de velocidad propia: se limita a mostrar
/// [speedMultiplier] (el mismo `ValueNotifier` que ya maneja
/// `LibretroGameView` internamente, expuesto vía `LibretroGameController`)
/// y a invocar [onTap] (que reutiliza `LibretroGameController.cycleSpeed`,
/// es decir, el `_cycleSpeed` real ya existente: x1→x2→x4→x8→x1).
class SpeedButton extends StatelessWidget {
  const SpeedButton({
    super.key,
    required this.speedMultiplier,
    required this.onTap,
  });

  final ValueListenable<int> speedMultiplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: speedMultiplier,
      builder: (context, multiplier, _) {
        final bool boosted = multiplier != 1;

        return Tooltip(
          message: 'Cambiar velocidad de emulación',
          child: Material(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(minWidth: 46, minHeight: 30),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: boosted
                        ? Colors.amberAccent.withValues(alpha: 0.70)
                        : Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      boosted ? Icons.fast_forward_rounded : Icons.speed_rounded,
                      color: boosted ? Colors.amberAccent : Colors.white70,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'x$multiplier',
                      style: TextStyle(
                        color: boosted ? Colors.amberAccent : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
