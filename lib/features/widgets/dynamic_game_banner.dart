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

  const DynamicGameBanner({
    super.key,
    required this.game,
    required this.coverPath,
    required this.onPlay,
    this.height = 180,
  });

  @override
  State<DynamicGameBanner> createState() => _DynamicGameBannerState();
}

class _DynamicGameBannerState extends State<DynamicGameBanner> {
  static const Color _fallbackColor = Color(0xFF311B92);

  Color _dominant = _fallbackColor;

  @override
  void initState() {
    super.initState();
    _loadDominantColor();
  }

  @override
  void didUpdateWidget(covariant DynamicGameBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.coverPath != widget.coverPath) {
      _dominant = _fallbackColor;
      _loadDominantColor();
    }
  }

  Future<Uint8List?> _readCoverBytes(String path) async {
    try {
      final File file = File(path);

      if (await file.exists()) {
        return file.readAsBytes();
      }

      final ByteData data = await rootBundle.load(path);
      return data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDominantColor() async {
    final String? path = widget.coverPath;

    if (path == null || path.trim().isEmpty) {
      return;
    }

    ui.Codec? codec;
    ui.Image? image;

    try {
      final Uint8List? bytes = await _readCoverBytes(path);

      if (bytes == null || bytes.isEmpty) {
        return;
      }

      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 24,
        targetHeight: 24,
      );

      final ui.FrameInfo frame = await codec.getNextFrame();
      image = frame.image;

      final ByteData? rgba = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (rgba == null) {
        return;
      }

      final Uint8List values = rgba.buffer.asUint8List(
        rgba.offsetInBytes,
        rgba.lengthInBytes,
      );

      int red = 0;
      int green = 0;
      int blue = 0;
      int count = 0;

      for (int index = 0; index + 3 < values.length; index += 4) {
        final int alpha = values[index + 3];

        if (alpha < 80) {
          continue;
        }

        final int r = values[index];
        final int g = values[index + 1];
        final int b = values[index + 2];
        final int brightness = (r + g + b) ~/ 3;

        if (brightness < 18 || brightness > 242) {
          continue;
        }

        red += r;
        green += g;
        blue += b;
        count++;
      }

      if (count == 0 || !mounted) {
        return;
      }

      final Color averageColor = Color.fromARGB(
        255,
        red ~/ count,
        green ~/ count,
        blue ~/ count,
      );

      final HSLColor hsl = HSLColor.fromColor(averageColor);
      final double saturation = (hsl.saturation + 0.18)
          .clamp(0.0, 1.0)
          .toDouble();

      final Color adjustedColor = hsl
          .withSaturation(saturation)
          .withLightness(0.32)
          .toColor();

      if (!mounted) {
        return;
      }

      setState(() {
        _dominant = adjustedColor;
      });
    } catch (_) {
      // Mantiene el violeta de RetroHub si la carátula no puede analizarse.
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Widget _buildCover() {
    final String? path = widget.coverPath;

    if (path == null || path.trim().isEmpty) {
      return const Icon(
        Icons.videogame_asset,
        size: 42,
        color: Colors.white38,
      );
    }

    final File file = File(path);

    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.videogame_asset,
          size: 42,
          color: Colors.white38,
        ),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.videogame_asset,
        size: 42,
        color: Colors.white38,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            _dominant,
            Color.lerp(_dominant, Colors.black, 0.72)!,
            Colors.black,
          ],
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 100,
            height: 140,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildCover(),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Continúa tu aventura',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.game.console} • '
                  '${PlayTimeFormatter.fromSeconds(widget.game.playTimeSeconds)} jugadas',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: widget.onPlay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
