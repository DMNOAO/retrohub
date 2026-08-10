import 'dart:async';
import 'dart:typed_data';

import '../link_packet.dart';
import '../link_state.dart';
import '../link_transport.dart';
import 'bluetooth_connection.dart';
import 'bluetooth_discovery.dart';
import 'bluetooth_packet_codec.dart';

/// Implementación real de [LinkTransport] sobre Bluetooth Classic
/// (RFCOMM/SPP). No BLE.
///
/// Reutiliza [BluetoothConnection] para el socket (host nativo o cliente
/// vía `flutter_bluetooth_serial`) y [BluetoothPacketCodec] para
/// reconstruir [LinkPacket] sobre el flujo de bytes crudo. No conoce
/// SameBoy ni el resto del emulador: solo mueve bytes.
class BluetoothLinkTransport implements LinkTransport {
  BluetoothLinkTransport({
    BluetoothDiscovery discovery = const BluetoothDiscovery(),
  }) : _discovery = discovery;

  final BluetoothDiscovery _discovery;
  final BluetoothConnection _connection = BluetoothConnection();

  final StreamController<LinkState> _stateController =
      StreamController<LinkState>.broadcast();
  final StreamController<Uint8List> _packetController =
      StreamController<Uint8List>.broadcast();

  StreamSubscription<BluetoothConnectionEvent>? _connectionSubscription;
  StreamSubscription<LinkPacket>? _packetSubscription;

  LinkState _state = LinkState.disconnected;
  int _sendSequence = 0;

  @override
  LinkState get state => _state;

  @override
  Stream<LinkState> get onStateChanged => _stateController.stream;

  @override
  Stream<Uint8List> get onPacket => _packetController.stream;

  @override
  Future<void> host() async {
    _emitState(LinkState.hosting);
    _listenToConnectionEvents();

    if (!await _ensureBluetoothEnabled()) return;

    try {
      await _connection.startHosting(kRetroHubLinkDeviceName);
    } catch (_) {
      _emitState(LinkState.error);
    }
  }

  @override
  Future<void> join(String target) async {
    _emitState(LinkState.connecting);
    _listenToConnectionEvents();

    if (!await _ensureBluetoothEnabled()) return;

    await _connection.joinByAddress(target);
  }

  @override
  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _packetSubscription?.cancel();
    _packetSubscription = null;

    await _connection.disconnect();
    _emitState(LinkState.disconnected);
  }

  @override
  Future<void> send(Uint8List packet) async {
    if (_state != LinkState.connected && _state != LinkState.syncing) {
      return;
    }

    final Uint8List framed = BluetoothPacketCodec.encode(
      LinkPacket(
        payload: packet,
        sequence: _sendSequence++,
        timestamp: DateTime.now(),
      ),
    );
    await _connection.send(framed);
  }

  Future<bool> _ensureBluetoothEnabled() async {
    if (await _discovery.isEnabled()) return true;

    final bool enabled = await _discovery.requestEnable();
    if (!enabled) {
      _emitState(LinkState.error);
    }
    return enabled;
  }

  void _listenToConnectionEvents() {
    _connectionSubscription ??= _connection.events.listen(
      _handleConnectionEvent,
    );

    _packetSubscription ??= BluetoothPacketCodec.decode(
      _connection.events
          .where((BluetoothConnectionEvent event) => event is BluetoothDataEvent)
          .map((BluetoothConnectionEvent event) => (event as BluetoothDataEvent).bytes),
    ).listen((LinkPacket packet) => _packetController.add(packet.payload));
  }

  void _handleConnectionEvent(BluetoothConnectionEvent event) {
    switch (event) {
      case BluetoothConnectedEvent():
        _emitState(LinkState.connected);
        break;
      case BluetoothDataEvent():
        break;
      case BluetoothDisconnectedEvent():
        _emitState(LinkState.disconnected);
        break;
      case BluetoothErrorEvent():
        _emitState(LinkState.error);
        break;
    }
  }

  void _emitState(LinkState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Libera streams y la conexión Bluetooth activa, si la hay.
  void dispose() {
    _connectionSubscription?.cancel();
    _packetSubscription?.cancel();
    _connection.dispose();
    _stateController.close();
    _packetController.close();
  }
}
