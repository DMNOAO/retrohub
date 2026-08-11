import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../data/libretro_bridge.dart';

/// Reproduce el PCM estéreo generado por cualquier core libretro.
class LibretroAudioPlayer {
  static const Duration _prebufferDuration = Duration(milliseconds: 80);

  AudioSource? _source;
  SoundHandle? _handle;
  int _sampleRate = 48000;
  int _bufferedBytes = 0;
  bool _ready = false;
  bool _disposed = false;

  int get _prebufferBytes =>
      (_sampleRate * 4 * _prebufferDuration.inMilliseconds) ~/ 1000;

  Future<void> start(LibretroBridge bridge) async {
    if (_disposed) return;
    try {
      _sampleRate = bridge.audioSampleRate;
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init(
          sampleRate: _sampleRate,
          channels: Channels.stereo,
          lowLatency: true,
        );
      }
      _source = _createSource();
      _ready = true;
    } catch (error) {
      debugPrint('No se pudo iniciar el audio del emulador: $error');
    }
  }

  AudioSource _createSource() => SoLoud.instance.setBufferStream(
        sampleRate: _sampleRate,
        channels: Channels.stereo,
        format: BufferType.s16le,
        bufferingType: BufferingType.preserved,
        bufferingTimeNeeds: 0.08,
        maxBufferSizeDuration: const Duration(milliseconds: 250),
      );

  void pump(LibretroBridge bridge) {
    if (!_ready || _disposed || _source == null) return;
    final Uint8List bytes = bridge.readAudioBytes();
    if (bytes.isEmpty) return;
    try {
      SoLoud.instance.addAudioDataStream(_source!, bytes);
      _bufferedBytes += bytes.length;
      if (_handle == null && _bufferedBytes >= _prebufferBytes) {
        _handle = SoLoud.instance.play(_source!);
      }
    } on SoLoudPcmBufferFullCppException {
      // Se descarta el bloque tardío para conservar baja latencia.
    } catch (error) {
      debugPrint('Audio libretro: $error');
    }
  }

  void setPaused(bool paused) {
    final handle = _handle;
    if (handle == null || !_ready) return;
    if (SoLoud.instance.getIsValidVoiceHandle(handle)) {
      SoLoud.instance.setPause(handle, paused);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final handle = _handle;
    final source = _source;
    _handle = null;
    _source = null;
    if (handle != null) await SoLoud.instance.stop(handle);
    if (source != null) await SoLoud.instance.disposeSource(source);
  }
}
