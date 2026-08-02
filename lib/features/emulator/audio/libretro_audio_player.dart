import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../data/libretro_bridge.dart';

class LibretroAudioPlayer {
  AudioSource? _source;
  SoundHandle? _handle;
  bool _ready = false;
  bool _disposed = false;

  Future<void> start(LibretroBridge bridge) async {
    if (_disposed) return;

    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init(
          sampleRate: bridge.audioSampleRate,
          channels: Channels.stereo,
          lowLatency: true,
        );
      }

      final source = SoLoud.instance.setBufferStream(
        sampleRate: bridge.audioSampleRate,
        channels: Channels.stereo,
        format: BufferType.s16le,
        bufferingType: BufferingType.released,
        bufferingTimeNeeds: 0.06,
        maxBufferSizeDuration: const Duration(milliseconds: 250),
      );
      _source = source;
      _handle = SoLoud.instance.play(source);
      _ready = true;
    } catch (error) {
      debugPrint('No se pudo iniciar el audio del emulador: $error');
    }
  }

  void pump(LibretroBridge bridge) {
    final AudioSource? source = _source;
    if (!_ready || _disposed || source == null) return;

    final Uint8List bytes = bridge.readAudioBytes();
    if (bytes.isNotEmpty) {
      SoLoud.instance.addAudioDataStream(source, bytes);
    }
  }

  void setPaused(bool paused) {
    final SoundHandle? handle = _handle;
    if (!_ready || handle == null) return;
    SoLoud.instance.setPause(handle, paused);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _ready = false;

    final SoundHandle? handle = _handle;
    final AudioSource? source = _source;
    _handle = null;
    _source = null;

    if (handle != null) await SoLoud.instance.stop(handle);
    if (source != null) await SoLoud.instance.disposeSource(source);
  }
}
