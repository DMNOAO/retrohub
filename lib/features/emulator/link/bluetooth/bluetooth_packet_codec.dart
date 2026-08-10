import 'dart:async';
import 'dart:typed_data';

import '../link_packet.dart';

/// Empaqueta y desempaqueta [LinkPacket] sobre un stream de bytes crudo,
/// como el que expone una conexión RFCOMM.
///
/// RFCOMM entrega un flujo continuo de bytes, no mensajes ya separados:
/// un `Stream<Uint8List>` puede partir un paquete en varios chunks, o
/// juntar varios paquetes en un solo chunk. Este codec resuelve eso con
/// un framing simple de encabezado fijo + payload.
///
/// Formato de cada frame (16 bytes de encabezado + payload variable):
/// ```
/// [0..3]   longitud del payload   (uint32, big endian)
/// [4..7]   número de secuencia    (uint32, big endian)
/// [8..15]  timestamp en microsegundos desde epoch (int64, big endian)
/// [16..]   payload
/// ```
class BluetoothPacketCodec {
  static const int headerLength = 16;

  /// Codifica un [LinkPacket] a los bytes que se envían por el socket.
  static Uint8List encode(LinkPacket packet) {
    final ByteData header = ByteData(headerLength);
    header.setUint32(0, packet.payload.length, Endian.big);
    header.setUint32(4, packet.sequence, Endian.big);
    header.setInt64(8, packet.timestamp.microsecondsSinceEpoch, Endian.big);

    final Uint8List frame = Uint8List(headerLength + packet.payload.length);
    frame.setRange(0, headerLength, header.buffer.asUint8List());
    frame.setRange(headerLength, frame.length, packet.payload);
    return frame;
  }

  /// Convierte un stream de bytes crudos (chunks de cualquier tamaño) en
  /// un stream de [LinkPacket] ya reconstruidos, acumulando internamente
  /// hasta tener cada frame completo.
  static Stream<LinkPacket> decode(Stream<Uint8List> input) {
    final StreamController<LinkPacket> controller =
        StreamController<LinkPacket>();
    final BytesBuilder buffer = BytesBuilder();

    late final StreamSubscription<Uint8List> subscription;

    void drainCompleteFrames() {
      Uint8List bytes = buffer.toBytes();

      while (bytes.length >= headerLength) {
        final ByteData header = ByteData.sublistView(bytes, 0, headerLength);
        final int payloadLength = header.getUint32(0, Endian.big);
        final int totalLength = headerLength + payloadLength;

        if (bytes.length < totalLength) break;

        final int sequence = header.getUint32(4, Endian.big);
        final int micros = header.getInt64(8, Endian.big);
        final Uint8List payload = Uint8List.fromList(
          bytes.sublist(headerLength, totalLength),
        );

        controller.add(
          LinkPacket(
            payload: payload,
            sequence: sequence,
            timestamp: DateTime.fromMicrosecondsSinceEpoch(micros),
          ),
        );

        bytes = bytes.sublist(totalLength);
      }

      buffer.clear();
      buffer.add(bytes);
    }

    subscription = input.listen(
      (Uint8List chunk) {
        buffer.add(chunk);
        drainCompleteFrames();
      },
      onError: controller.addError,
      onDone: controller.close,
      cancelOnError: false,
    );

    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }
}
