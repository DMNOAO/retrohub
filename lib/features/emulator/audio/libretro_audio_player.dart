import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../data/libretro_bridge.dart';

class LibretroAudioPlayer {
  static const Duration _prebufferDuration = Duration(milliseconds: 80);

  AudioSource? _source;
  SoundHandle? _handle;
  int _sampleRate = 48000;
  int _bufferedBytes = 0;
  bool _ready = false;
  bool _disposed = false;
  bool _isPumping = false;
  bool _recoveryNoticePrinted = false;

  int get _prebufferBytes =>
      (_sampleRate * 2 * 2 * _prebufferDuration.inMilliseconds) ~/ 1000;

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
      _handle = null;
      _bufferedBytes = 0;
      _ready = true;
    } catch (error) {
      debugPrint('No se pudo iniciar el audio del emulador: $error');
    }
  }

  AudioSource _createSource() {
    return SoLoud.instance.setBufferStream(
      sampleRate: _sampleRate,
      channels: Channels.stereo,
      format: BufferType.s16le,
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0.06,
      maxBufferSizeDuration: const Duration(milliseconds: 500),
    );
  }

  void pump(LibretroBridge bridge) {
    if (!_ready || _disposed || _source == null) return;

    // Always drain the native ring buffer. Dropping a block is preferable to
    // allowing audio backpressure to interrupt or delay emulation.
    final Uint8List bytes = bridge.readAudioBytes();
    if (bytes.isEmpty || _isPumping) return;

    _isPumping = true;
    try {
      final SoundHandle? handle = _handle;
      if (handle != null &&
          !SoLoud.instance.getIsValidVoiceHandle(handle)) {
        _replaceStream(bytes);
        return;
      }

      SoLoud.instance.addAudioDataStream(_source!, bytes);
      _bufferedBytes += bytes.length;
      _startPlaybackIfPrebuffered();
    } on SoLoudPcmBufferFullCppException {
      _replaceStream(bytes);
    } on SoLoudStreamEndedAlreadyCppException {
      _replaceStream(bytes);
    } catch (error) {
      if (!_disposed && !_recoveryNoticePrinted) {
        _recoveryNoticePrinted = true;
        debugPrint('El audio del emulador se recuperó tras un error: $error');
      }
      _replaceStream(bytes);
    } finally {
      _isPumping = false;
    }
  }

  void _startPlaybackIfPrebuffered() {
    if (_handle != null || _source == null) return;
    if (_bufferedBytes < _prebufferBytes) return;

    _handle = SoLoud.instance.play(_source!);
  }

  void _replaceStream(Uint8List firstBlock) {
    if (_disposed || !SoLoud.instance.isInitialized) return;

    final SoundHandle? oldHandle = _handle;
    final AudioSource? oldSource = _source;

    try {
      final AudioSource replacement = _createSource();
      _source = replacement;
      _handle = null;
      _bufferedBytes = 0;

      SoLoud.instance.addAudioDataStream(replacement, firstBlock);
      _bufferedBytes = firstBlock.length;
      _startPlaybackIfPrebuffered();

      if (!_recoveryNoticePrinted) {
        _recoveryNoticePrinted = true;
        debugPrint('Se reinició automáticamente el stream de audio.');
      }

      if (oldHandle != null) {
        unawaited(SoLoud.instance.stop(oldHandle));
      }
      if (oldSource != null) {
        unawaited(SoLoud.instance.disposeSource(oldSource));
      }
    } catch (error) {
      if (!_disposed && !_recoveryNoticePrinted) {
        _recoveryNoticePrinted = true;
        debugPrint('No se pudo recuperar el stream de audio: $error');
      }
    }
  }

  void setPaused(bool paused) {
    final SoundHandle? handle = _handle;
    if (!_ready || handle == null) return;

    try {
      if (SoLoud.instance.getIsValidVoiceHandle(handle)) {
        SoLoud.instance.setPause(handle, paused);
      }
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
    _bufferedBytes = 0;

    try {
      if (handle != null) await SoLoud.instance.stop(handle);
      if (source != null) await SoLoud.instance.disposeSource(source);
    } catch (error) {
      debugPrint('No se pudo cerrar limpiamente el audio: $error');
    }
  }
}
