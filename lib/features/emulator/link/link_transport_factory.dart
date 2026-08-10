import 'link_transport.dart';
import 'bluetooth/bluetooth_link_transport.dart';

/// Punto único donde se decide qué [LinkTransport] usa RetroHub en la
/// vida real.
///
/// Cambiar de transporte (Bluetooth hoy; WiFi, LAN o USB en el futuro)
/// es cuestión de editar esta función. `LibretroGameView` solo llama a
/// [createDefaultLinkTransport]; no necesita volver a tocarse cuando el
/// transporte cambie.
LinkTransport createDefaultLinkTransport() => BluetoothLinkTransport();
