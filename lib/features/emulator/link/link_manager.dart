import 'dart:async';
import 'dart:typed_data';

import 'link_session.dart';
import 'link_state.dart';
import 'link_transport.dart';

/// Cerebro del sistema Link.
///
/// Es la única pieza que la UI de RetroHub (y, más adelante,
/// `LibretroGameController`) necesita conocer: inicia y cierra sesiones,
/// envía y recibe paquetes, mantiene el estado, y expone todo como
/// `Stream`s. [LinkManager] depende únicamente de la interfaz abstracta
/// [LinkTransport] — nunca de Bluetooth ni de SameBoy directamente — para
/// poder cambiar de transporte en el futuro sin tocar esta clase.
class LinkManager {
  LinkManager({required LinkTransport transport})
      : _transport = transport {
    _transportStateSubscription =
        _transport.onStateChanged.listen(_handleTransportStateChanged);

    _transportPacketSubscription =
        _transport.onPacket.listen(_handleTransportPacket);
  }

  final LinkTransport _transport;

  late final StreamSubscription<LinkState> _transportStateSubscription;
  late final StreamSubscription<Uint8List> _transportPacketSubscription;

  final StreamController<LinkState> _stateController =
      StreamController<LinkState>.broadcast();

  final StreamController<Uint8List> _packetController =
      StreamController<Uint8List>.broadcast();

  final StreamController<LinkSession?> _sessionController =
      StreamController<LinkSession?>.broadcast();

  LinkState _state = LinkState.disconnected;
  LinkSession? _session;

  /// Estado actual.
  LinkState get state => _state;

  /// Sesión activa.
  LinkSession? get session => _session;

  /// Stream de estados.
  Stream<LinkState> get onStateChanged => _stateController.stream;

  /// Stream de paquetes.
  Stream<Uint8List> get onPacket => _packetController.stream;

  /// Stream de cambios de sesión.
  Stream<LinkSession?> get onSessionChanged => _sessionController.stream;

  /// Host.
  Future<void> host({
    required String localName,
  }) async {
    _session = LinkSession(
      id: _generateSessionId(),
      isHost: true,
      localName: localName,
      state: LinkState.hosting,
    );

    _emitSession();

    // Reflejar inmediatamente el estado en la UI.
    _handleTransportStateChanged(LinkState.hosting);

    await _transport.host();
  }

  /// Cliente.
  Future<void> join({
    required String localName,
    required String target,
  }) async {
    _session = LinkSession(
      id: _generateSessionId(),
      isHost: false,
      localName: localName,
      state: LinkState.connecting,
    );

    _emitSession();

    // Reflejar inmediatamente el estado en la UI.
    _handleTransportStateChanged(LinkState.connecting);

    await _transport.join(target);
  }

  /// Cierra la sesión.
  Future<void> close() async {
    await _transport.disconnect();

    // Forzar el estado aunque el transporte no lo notifique.
    _handleTransportStateChanged(LinkState.disconnected);

    _session = null;
    _emitSession();
  }

  /// Envía un paquete.
  Future<void> sendPacket(Uint8List packet) async {
    if (_state != LinkState.connected &&
        _state != LinkState.syncing) {
      return;
    }

    await _transport.send(packet);
  }

  void _handleTransportStateChanged(LinkState newState) {
    _state = newState;
    _stateController.add(_state);

    final LinkSession? currentSession = _session;

    if (currentSession != null) {
      _session = currentSession.copyWith(
        state: newState,
        connectedAt: newState == LinkState.connected
            ? DateTime.now()
            : currentSession.connectedAt,
      );

      _emitSession();
    }
  }

  void _handleTransportPacket(Uint8List packet) {
    _packetController.add(packet);
  }

  void _emitSession() {
    _sessionController.add(_session);
  }

  String _generateSessionId() {
    return DateTime.now()
        .microsecondsSinceEpoch
        .toRadixString(36);
  }

  Future<void> dispose() async {
    await _transportStateSubscription.cancel();
    await _transportPacketSubscription.cancel();

    await _stateController.close();
    await _packetController.close();
    await _sessionController.close();
  }
}