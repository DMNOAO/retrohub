import 'package:flutter/material.dart';

/// Identidad visual compacta para cada consola soportada por RetroHub.
/// Se dibuja con Flutter para escalar bien en Android/Windows sin assets.
class RetroHubConsoleIcon extends StatelessWidget {
  final String console;
  final double size;
  final Color? color;

  const RetroHubConsoleIcon({
    super.key,
    required this.console,
    this.size = 34,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ConsoleIconPainter(
          console: console.toUpperCase(),
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ConsoleIconPainter extends CustomPainter {
  final String console;
  final Color color;

  const _ConsoleIconPainter({required this.console, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (console.contains('NDS') || console.contains('NINTENDO DS')) {
      _paintNintendoDs(canvas, size, paint);
    } else if (console.contains('SNES') || console.contains('SUPER')) {
      _paintSnesPad(canvas, size, paint);
    } else if (console.contains('GBA') || console.contains('ADVANCE')) {
      _paintGba(canvas, size, paint);
    } else if (console.contains('GBC') || console.contains('COLOR')) {
      _paintGameBoy(canvas, size, paint, colorModel: true);
    } else {
      _paintGameBoy(canvas, size, paint, colorModel: false);
    }
  }

  void _paintNintendoDs(Canvas canvas, Size s, Paint p) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * .20, s.height * .04, s.width * .60, s.height * .92),
      Radius.circular(s.width * .08),
    );
    canvas.drawRRect(outer, p);
    canvas.drawLine(
      Offset(s.width * .20, s.height * .50),
      Offset(s.width * .80, s.height * .50),
      p,
    );
    canvas.drawRect(
      Rect.fromLTWH(s.width * .29, s.height * .13, s.width * .42, s.height * .27),
      p,
    );
    canvas.drawRect(
      Rect.fromLTWH(s.width * .29, s.height * .60, s.width * .42, s.height * .27),
      p,
    );
  }

  void _paintGameBoy(Canvas canvas, Size s, Paint p, {required bool colorModel}) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * .22, s.height * .05, s.width * .56, s.height * .90),
      Radius.circular(s.width * (colorModel ? .12 : .07)),
    );
    canvas.drawRRect(body, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * .30, s.height * .16, s.width * .40, s.height * .32),
        Radius.circular(s.width * .035),
      ),
      p,
    );
    canvas.drawLine(Offset(s.width * .34, s.height * .66), Offset(s.width * .50, s.height * .66), p);
    canvas.drawLine(Offset(s.width * .42, s.height * .58), Offset(s.width * .42, s.height * .74), p);
    canvas.drawCircle(Offset(s.width * .62, s.height * .62), s.width * .045, p);
    canvas.drawCircle(Offset(s.width * .69, s.height * .70), s.width * .045, p);
  }

  void _paintGba(Canvas canvas, Size s, Paint p) {
    final path = Path()
      ..moveTo(s.width * .12, s.height * .30)
      ..quadraticBezierTo(s.width * .05, s.height * .50, s.width * .14, s.height * .72)
      ..quadraticBezierTo(s.width * .20, s.height * .83, s.width * .31, s.height * .72)
      ..lineTo(s.width * .69, s.height * .72)
      ..quadraticBezierTo(s.width * .80, s.height * .83, s.width * .86, s.height * .72)
      ..quadraticBezierTo(s.width * .95, s.height * .50, s.width * .88, s.height * .30)
      ..quadraticBezierTo(s.width * .84, s.height * .20, s.width * .70, s.height * .22)
      ..lineTo(s.width * .30, s.height * .22)
      ..quadraticBezierTo(s.width * .16, s.height * .20, s.width * .12, s.height * .30)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawRect(Rect.fromLTWH(s.width * .34, s.height * .31, s.width * .32, s.height * .28), p);
    canvas.drawLine(Offset(s.width * .19, s.height * .48), Offset(s.width * .31, s.height * .48), p);
    canvas.drawLine(Offset(s.width * .25, s.height * .42), Offset(s.width * .25, s.height * .54), p);
    canvas.drawCircle(Offset(s.width * .76, s.height * .43), s.width * .035, p);
    canvas.drawCircle(Offset(s.width * .82, s.height * .51), s.width * .035, p);
  }

  void _paintSnesPad(Canvas canvas, Size s, Paint p) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * .08, s.height * .25, s.width * .84, s.height * .50),
      Radius.circular(s.width * .22),
    );
    canvas.drawRRect(body, p);
    canvas.drawLine(Offset(s.width * .20, s.height * .50), Offset(s.width * .38, s.height * .50), p);
    canvas.drawLine(Offset(s.width * .29, s.height * .41), Offset(s.width * .29, s.height * .59), p);
    canvas.drawCircle(Offset(s.width * .72, s.height * .43), s.width * .04, p);
    canvas.drawCircle(Offset(s.width * .81, s.height * .50), s.width * .04, p);
    canvas.drawCircle(Offset(s.width * .72, s.height * .57), s.width * .04, p);
    canvas.drawCircle(Offset(s.width * .63, s.height * .50), s.width * .04, p);
    canvas.drawLine(Offset(s.width * .44, s.height * .58), Offset(s.width * .49, s.height * .58), p);
    canvas.drawLine(Offset(s.width * .52, s.height * .58), Offset(s.width * .57, s.height * .58), p);
  }

  @override
  bool shouldRepaint(covariant _ConsoleIconPainter oldDelegate) =>
      oldDelegate.console != console || oldDelegate.color != color;
}
