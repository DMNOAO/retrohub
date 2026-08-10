import 'dart:async';
import 'dart:typed_data';

import 'link_state.dart';

/// Contrato mínimo que debe cumplir cualquier medio físico de transporte
/// para el Cable Link: Bluetooth hoy, potencialmente WiFi, LAN, USB o QR
/// más adelante.
///
/// Un [LinkTransport] NO conoce Flutter, ni el emulador, ni SameBoy.
/// Su único trabajo es abrir/cerrar una conexión punto a punto y mover
/// paquetes de bytes crudos en ambas direcciones. Toda la interpretación
/// de esos bytes (protocolo del puerto serie del Cable Link) vive en
/// capas superiores ([LinkManager] y, eventualmente, el bridge nativo).
abstract class LinkTransport {
  /// Estado actual del transporte.
  LinkState get state;

  /// Emite cada vez que [state] cambia.
  Stream<LinkState> get onStateChanged;

  /// Emite cada paquete de bytes recibido del otro extremo, en el orden
  /// en que llegó.
  Stream<Uint8List> get onPacket;

  /// Comienza a esperar una conexión entrante (rol host).
  Future<void> host();

  /// Intenta conectarse a un host ya localizado.
  ///
  /// [target] es un identificador opaco específico del transporte (por
  /// ejemplo, la dirección MAC de un dispositivo Bluetooth, o una IP para
  /// un transporte WiFi/LAN futuro).
  Future<void> join(String target);

  /// Cierra la conexión activa, si la hay. Siempre seguro de llamar
  /// aunque no haya conexión en curso.
  Future<void> disconnect();

  /// Envía un paquete de bytes al otro extremo.
  ///
  /// No debe lanzar si no hay conexión activa: en ese caso el paquete se
  /// descarta silenciosamente y el estado permanece sin cambios (la
  /// responsabilidad de decidir si eso es un error le corresponde a quien
  /// use el transporte, no al transporte mismo).
  Future<void> send(Uint8List packet);
}
