import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// UUID propio de RetroHub para el servicio Link Cable.
///
/// IMPORTANTE: NO es el UUID estándar de Serial Port Profile
/// (`00001101-0000-1000-8000-00805F9B34FB`). Ese UUID es público y
/// genérico — lo usan miles de apps ajenas (lectores OBD2, impresoras
/// térmicas, transferencia de archivos, etc.), así que un
/// `BluetoothServerSocket` escuchando ahí puede aceptar conexiones de
/// cualquier dispositivo Bluetooth cercano que intente una conexión SPP
/// genérica mientras el teléfono está en modo descubrible — no
/// necesariamente el otro RetroHub. Este UUID (generado una sola vez
/// para este proyecto) reduce drásticamente esa chance. La defensa
/// definitiva contra eso es el handshake de aplicación más abajo.
const String kRetroHubLinkServiceUuid =
    'b2554007-ebb3-4359-9483-4d49f79d8246';

sealed class BluetoothConnectionEvent {
  const BluetoothConnectionEvent();
}

class BluetoothConnectedEvent extends BluetoothConnectionEvent {
  const BluetoothConnectedEvent({
    required this.remoteAddress,
    required this.remoteName,
  });

  final String remoteAddress;
  final String remoteName;
}

class BluetoothDataEvent extends BluetoothConnectionEvent {
  const BluetoothDataEvent(this.bytes);

  final Uint8List bytes;
}

class BluetoothDisconnectedEvent extends BluetoothConnectionEvent {
  const BluetoothDisconnectedEvent();
}

class BluetoothErrorEvent extends BluetoothConnectionEvent {
  const BluetoothErrorEvent(this.reason);

  final String reason;
}

/// Conexión Bluetooth Classic/RFCOMM de RetroHub.
///
/// Tanto el rol host como el rol cliente pasan por `MainActivity.kt`.
/// De esta forma ambos extremos usan exactamente el mismo UUID y el mismo
/// tipo de socket RFCOMM.
///
/// Además del socket RFCOMM en sí, esta clase exige un pequeño
/// **handshake de aplicación** antes de considerar la conexión como
/// [BluetoothConnectedEvent]: apenas el socket nativo se conecta, ambos
/// lados se mandan un saludo fijo ([_handshakeBytes]) y esperan
/// recibir el mismo saludo del otro lado. Si en [_handshakeTimeout] no
/// se completa (o llega algo que no coincide), se corta la conexión y
/// se emite un error — así, aunque algo ajeno a RetroHub se conecte al
/// UUID (accidental o no), nunca se lo trata como un jugador real ni
/// llega a ver datos de la partida.
class BluetoothConnection {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.retrohub.beta/bluetooth_link',
  );

  static const EventChannel _eventChannel = EventChannel(
    'com.retrohub.beta/bluetooth_link/events',
  );

  static const String _handshakeMagic = 'RETROHUB_LINK_V1';
  static final Uint8List _handshakeBytes = Uint8List.fromList(
    _handshakeMagic.codeUnits,
  );
  static const Duration _handshakeTimeout = Duration(seconds: 5);

  StreamSubscription<dynamic>? _nativeEventSubscription;

  final StreamController<BluetoothConnectionEvent> _events =
      StreamController<BluetoothConnectionEvent>.broadcast();

  bool _isConnected = false;

  bool _handshakeSent = false;
  bool _handshakeReceived = false;
  final BytesBuilder _handshakeBuffer = BytesBuilder();
  Timer? _handshakeTimeoutTimer;
  String? _pendingRemoteAddress;
  String? _pendingRemoteName;

  Stream<BluetoothConnectionEvent> get events => _events.stream;

  bool get isConnected => _isConnected;

  void _ensureNativeEvents() {
    _nativeEventSubscription ??= _eventChannel
        .receiveBroadcastStream()
        .listen(_handleNativeEvent, onError: _handleNativeChannelError);
  }

  /// Rol host: abre el servidor RFCOMM nativo y espera `accept()`.
  Future<void> startHosting(String localName) async {
    _ensureNativeEvents();

    try {
      await _methodChannel.invokeMethod<void>('startHosting', {
        'name': localName,
        'uuid': kRetroHubLinkServiceUuid,
      });
    } on PlatformException catch (error) {
      _isConnected = false;
      _events.add(
        BluetoothErrorEvent(error.message ?? 'platform_error'),
      );
    }
  }

  /// Rol cliente: conecta por dirección MAC usando el mismo UUID RFCOMM
  /// que el host.
  Future<void> joinByAddress(String address) async {
    _ensureNativeEvents();

    try {
      await _methodChannel.invokeMethod<void>('connect', {
        'address': address,
        'uuid': kRetroHubLinkServiceUuid,
      });
    } on PlatformException catch (error) {
      _isConnected = false;
      _events.add(
        BluetoothErrorEvent(error.message ?? 'platform_error'),
      );
    }
  }

  void _handleNativeChannelError(Object error) {
    _isConnected = false;
    _events.add(BluetoothErrorEvent(error.toString()));
  }

  void _handleNativeEvent(dynamic raw) {
    if (raw is! Map) {
      _events.add(
        BluetoothErrorEvent('Evento Bluetooth nativo inválido: $raw'),
      );
      return;
    }

    final Map<Object?, Object?> event = Map<Object?, Object?>.from(raw);

    switch (event['type']) {
      case 'connected':
        _pendingRemoteAddress = event['address'] as String? ?? '';
        _pendingRemoteName = event['name'] as String? ?? '';
        _beginHandshake();
        break;

      case 'data':
        final Object? rawBytes = event['bytes'];
        final Uint8List? bytes = rawBytes is Uint8List
            ? rawBytes
            : rawBytes is List
                ? Uint8List.fromList(rawBytes.cast<int>())
                : null;

        if (bytes == null) break;

        if (!_isConnected) {
          // Todavía no terminamos el handshake: estos bytes son parte
          // del saludo (o de un dispositivo ajeno que no lo manda
          // bien), nunca se reenvían como datos de juego.
          _consumeHandshakeBytes(bytes);
          break;
        }

        _events.add(BluetoothDataEvent(bytes));
        break;

      case 'disconnected':
        _isConnected = false;
        _resetHandshakeState();
        _events.add(const BluetoothDisconnectedEvent());
        break;

      case 'error':
        _isConnected = false;
        _resetHandshakeState();
        _events.add(
          BluetoothErrorEvent(
            event['reason'] as String? ?? 'unknown',
          ),
        );
        break;
    }
  }

  /// Apenas el socket nativo confirma conexión, mandamos nuestro saludo
  /// y arrancamos el timeout. Todavía NO se emite
  /// [BluetoothConnectedEvent] — eso espera a [_completeHandshakeIfReady].
  void _beginHandshake() {
    _handshakeSent = false;
    _handshakeReceived = false;
    _handshakeBuffer.clear();

    _handshakeTimeoutTimer?.cancel();
    _handshakeTimeoutTimer = Timer(_handshakeTimeout, _handleHandshakeTimeout);

    unawaited(_sendRaw(_handshakeBytes));
    _handshakeSent = true;
  }

  void _consumeHandshakeBytes(Uint8List bytes) {
    _handshakeBuffer.add(bytes);
    final Uint8List buffered = _handshakeBuffer.toBytes();

    if (buffered.length < _handshakeBytes.length) {
      return; // Todavía no llegó el saludo completo.
    }

    final Uint8List candidate = buffered.sublist(0, _handshakeBytes.length);

    if (!_bytesEqual(candidate, _handshakeBytes)) {
      _failHandshake('handshake_mismatch');
      return;
    }

    _handshakeReceived = true;

    // No debería sobrar nada en la práctica (el otro lado manda el
    // saludo como primer y único mensaje antes de que la app arranque
    // a mandar datos de juego), pero por robustez lo reinyectamos una
    // vez confirmada la conexión en vez de perderlo.
    final Uint8List leftover = buffered.sublist(_handshakeBytes.length);
    _completeHandshakeIfReady(leftoverAfterHandshake: leftover);
  }

  void _completeHandshakeIfReady({Uint8List? leftoverAfterHandshake}) {
    if (!_handshakeSent || !_handshakeReceived) return;

    _handshakeTimeoutTimer?.cancel();
    _handshakeTimeoutTimer = null;
    _handshakeBuffer.clear();

    _isConnected = true;
    _events.add(
      BluetoothConnectedEvent(
        remoteAddress: _pendingRemoteAddress ?? '',
        remoteName: _pendingRemoteName ?? '',
      ),
    );

    if (leftoverAfterHandshake != null && leftoverAfterHandshake.isNotEmpty) {
      _events.add(BluetoothDataEvent(leftoverAfterHandshake));
    }
  }

  void _handleHandshakeTimeout() {
    if (_isConnected) return; // Ya se completó justo antes de disparar.
    _failHandshake('handshake_timeout');
  }

  void _failHandshake(String reason) {
    _resetHandshakeState();
    _isConnected = false;
    _events.add(BluetoothErrorEvent('handshake_failed: $reason'));
    unawaited(disconnect());
  }

  void _resetHandshakeState() {
    _handshakeTimeoutTimer?.cancel();
    _handshakeTimeoutTimer = null;
    _handshakeSent = false;
    _handshakeReceived = false;
    _handshakeBuffer.clear();
    _pendingRemoteAddress = null;
    _pendingRemoteName = null;
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Envía bytes por el socket nativo activo, independientemente de si
  /// este teléfono inició la sesión o se unió a ella. Solo funciona una
  /// vez que el handshake de aplicación ya terminó (ver [isConnected]).
  Future<void> send(Uint8List bytes) async {
    if (!_isConnected) {
      return;
    }

    await _sendRaw(bytes);
  }

  /// Envío de bajo nivel, sin exigir [_isConnected] — lo usa el
  /// handshake, que necesita mandar su saludo ANTES de que la conexión
  /// se considere establecida a nivel de aplicación.
  Future<void> _sendRaw(Uint8List bytes) async {
    try {
      final bool? sent = await _methodChannel.invokeMethod<bool>(
        'send',
        {'bytes': bytes},
      );

      if (sent == false) {
        _events.add(
          const BluetoothErrorEvent('No se pudieron enviar los datos'),
        );
      }
    } on PlatformException catch (error) {
      _events.add(
        BluetoothErrorEvent(error.message ?? 'send_platform_error'),
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod<void>('disconnect');
    } on PlatformException {
      // Limpiamos igualmente el estado Dart.
    }

    _isConnected = false;
    _resetHandshakeState();

    await _nativeEventSubscription?.cancel();
    _nativeEventSubscription = null;
  }

  void dispose() {
    unawaited(disconnect());
    _events.close();
  }
}