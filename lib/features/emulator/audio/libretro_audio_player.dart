import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../data/libretro_bridge.dart';

class LibretroAudioPlayer {
  AudioSource? _source;
  SoundHandle? _handle;
  bool _ready = false;
  bool _disposed = false;
  bool _isPumping = false;

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

  Future<void> pump(LibretroBridge bridge) async {
    if (!_ready || _disposed || _source == null) return;

    // Always drain the native ring buffer. When the previous asynchronous
    // write is still running, this block is intentionally dropped so audio
    // can never build up and delay or stop emulation.
    final Uint8List bytes = bridge.readAudioBytes();
    if (bytes.isEmpty || _isPumping) return;

    final AudioSource source = _source!;
    _isPumping = true;
    try {
      await SoLoud.instance.addAudioDataStream(source, bytes);
    } on SoLoudPcmBufferFullCppException {
      // A full streaming buffer is recoverable. Dropping this block keeps
      // latency bounded and, most importantly, isolates audio from gameplay.
    } catch (error) {
      if (!_disposed) {
        debugPrint('Se descartó un bloque de audio del emulador: $error');
      }
    } finally {
      _isPumping = false;
    }
  }

  void setPaused(bool paused) {
    final SoundHandle? handle = _handle;
    if (!_ready || handle == null) return;

    try {
      SoLoud.instance.setPause(handle, paused);
    } catch (error) {
      debugPrint('No se pudo cambiar la pausa del audio: $error');
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _ready = false;

    final SoundHandle? handle = _handle;
    final AudioSource? source = _source;
    _handle = null;
    _source = null;

    try {
      if (handle != null) await SoLoud.instance.stop(handle);
      if (source != null) await SoLoud.instance.disposeSource(source);
    } catch (error) {
      debugPrint('No se pudo cerrar limpiamente el audio: $error');
    }
  }
}
