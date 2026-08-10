import 'dart:typed_data';

/// Representa un paquete de datos del Cable Link.
///
/// Es un contenedor puro: no valida, no transmite, no decide nada. Su
/// única función es darle forma a los bytes crudos que viajan entre
/// [LinkManager] y el bridge nativo (y, más adelante, el transporte
/// real) junto con metadatos mínimos para ordenarlos y auditarlos.
class LinkPacket {
  const LinkPacket({
    required this.payload,
    required this.sequence,
    required this.timestamp,
  });

  /// Bytes crudos del paquete.
  final Uint8List payload;

  /// Número de secuencia del paquete, para poder detectar pérdidas u
  /// orden incorrecto en capas superiores.
  final int sequence;

  /// Momento en que se generó el paquete.
  final DateTime timestamp;
}
