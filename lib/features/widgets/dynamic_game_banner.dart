import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/play_time_formatter.dart';
import '../../data/database/app_database.dart';

class DynamicGameBanner extends StatefulWidget {
  final Game game;
  final String? coverPath;
  final VoidCallback onPlay;
  final double height;

  const DynamicGameBanner({super.key, required this.game, required this.coverPath, required this.onPlay, this.height = 180});

  @override
  State<DynamicGameBanner> createState() => _DynamicGameBannerState();
}

class _DynamicGameBannerState extends State<DynamicGameBanner> {
  static const Color _fallbackColor = Color(0xFF311B92);
  Color _dominant = _fallbackColor;

  @override
  void initState() { super.initState(); _loadDominantColor(); }

  @override
  void didUpdateWidget(covariant DynamicGameBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverPath != widget.coverPath) { _dominant = _fallbackColor; _loadDominantColor(); }
  }

  Future<Uint8List?> _readCoverBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) return file.readAsBytes();
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) { return null; }
  }

  Future<void> _loadDominantColor() async {
    final path = widget.coverPath;
    if (path == null || path.trim().isEmpty) return;
    ui.Codec? codec; ui.Image? image;
    try {
      final bytes = await _readCoverBytes(path);
      if (bytes == null || bytes.isEmpty) return;
      codec = await ui.instantiateImageCodec(bytes, targetWidth: 24, targetHeight: 24);
      final frame = await codec.getNextFrame(); image = frame.image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) return;
      final values = rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes);
      int red = 0, green = 0, blue = 0, count = 0;
      for (int i = 0; i + 3 < values.length; i += 4) {
        if (values[i + 3] < 80) continue;
        final r = values[i], g = values[i + 1], b = values[i + 2];
        final brightness = (r + g + b) ~/ 3;
        if (brightness < 18 || brightness > 242) continue;
        red += r; green += g; blue += b; count++;
      }
      if (count == 0 || !mounted) return;
      final hsl = HSLColor.fromColor(Color.fromARGB(255, red ~/ count, green ~/ count, blue ~/ count));
      final adjusted = hsl.withSaturation((hsl.saturation + .18).clamp(0.0, 1.0)).withLightness(.32).toColor();
      if (mounted) setState(() => _dominant = adjusted);
    } catch (_) {} finally { image?.dispose(); codec?.dispose(); }
  }

  Widget _buildCover() {
    final path = widget.coverPath;
    const fallback = Icon(Icons.videogame_asset, size: 42, color: Colors.white38);
    if (path == null || path.trim().isEmpty) return fallback;
    final file = File(path);
    if (file.existsSync()) return Image.file(file, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback);
    return Image.asset(path, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback);
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.height <= 150;
    return Container(
      constraints: BoxConstraints(minHeight: widget.height),
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [_dominant, Color.lerp(_dominant, Colors.black, .72)!, Colors.black])),
      child: Row(children: [
        Container(
          width: compact ? 82 : 100,
          height: compact ? 116 : 140,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .30), borderRadius: BorderRadius.circular(14)),
          child: _buildCover(),
        ),
        SizedBox(width: compact ? 14 : 24),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Continúa tu aventura', style: TextStyle(color: Colors.white70, fontSize: compact ? 12 : 14)),
            SizedBox(height: compact ? 2 : 6),
            Text(widget.game.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 20 : 26, fontWeight: FontWeight.bold)),
            SizedBox(height: compact ? 2 : 6),
            Text('${widget.game.console} • ${PlayTimeFormatter.fromSeconds(widget.game.playTimeSeconds)} jugadas', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: compact ? 12 : 14)),
            SizedBox(height: compact ? 6 : 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: FilledButton.icon(
                onPressed: widget.onPlay,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Continuar', maxLines: 1, overflow: TextOverflow.fade),
              ),
            ),
          ],
        )),
      ]),
    );
  }
}
