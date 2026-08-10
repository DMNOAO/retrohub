import 'dart:async';
import 'dart:typed_data';

import 'link_state.dart';
import 'link_transport.dart';

/// Implementación de [LinkTransport] que no usa ningún medio real.
///
/// Existe únicamente para validar que toda la arquitectura de arriba
/// (`LinkManager`, y más adelante la UI y el bridge nativo) funciona de
/// punta a punta sin depender todavía de Bluetooth. Cualquier intento de
/// [host] o [join] termina siempre en [LinkState.error] ("No conectado");
/// [send] no hace nada.
class DummyLinkTransport implements LinkTransport {
  final StreamController<LinkState> _stateController =
      StreamController<LinkState>.broadcast();
  final StreamController<Uint8List> _packetController =
      StreamController<Uint8List>.broadcast();

  LinkState _state = LinkState.disconnected;

  @override
  LinkState get state => _state;

  @override
  Stream<LinkState> get onStateChanged => _stateController.stream;

  @override
  Stream<Uint8List> get onPacket => _packetController.stream;

  @override
  Future<void> host() async {
    _emitState(LinkState.hosting);
    await _failToConnect();
  }

  @override
  Future<void> join(String target) async {
    _emitState(LinkState.connecting);
    await _failToConnect();
  }

  @override
  Future<void> disconnect() async {
    _emitState(LinkState.disconnected);
  }

  @override
  Future<void> send(Uint8List packet) async {
    // No hay conexión real: el paquete se descarta silenciosamente.
  }

  /// Simula el intento de conexión y siempre termina en error
  /// ("No conectado"), ya que este transporte no habla con ningún
  /// dispositivo real.
  Future<void> _failToConnect() async {
    _emitState(LinkState.error);
  }

  void _emitState(LinkState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Libera los `StreamController`. Debe llamarse cuando ya no se vaya a
  /// usar esta instancia.
  void dispose() {
    _stateController.close();
    _packetController.close();
  }
}
