import 'dart:typed_data';

/// Protocolo transaccional usado entre dos cores SameBoy.
///
/// El puerto serie de Game Boy intercambia un byte en cada transferencia:
/// un extremo inicia con [LinkFlowFrameType.request] y el otro devuelve
/// exactamente un [LinkFlowFrameType.reply]. Esto evita tratar el outbox de
/// SameBoy como un stream libre y,
/// por tanto, impide llenar su inbox cuando los dos cores avanzan a ritmos
/// distintos.
enum LinkFlowFrameType {
  request(1),
  reply(2);

  const LinkFlowFrameType(this.wireValue);

  final int wireValue;

  static LinkFlowFrameType? fromWire(int value) {
    for (final type in values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

class LinkFlowFrame {
  const LinkFlowFrame({
    required this.type,
    required this.sequence,
    required this.byte,
  });

  static const int wireLength = 9;
  static const int _magicR = 0x52;
  static const int _magicH = 0x48;
  static const int _version = 2;

  final LinkFlowFrameType type;
  final int sequence;
  final int byte;

  Uint8List encode() {
    final data = ByteData(wireLength);
    data.setUint8(0, _magicR);
    data.setUint8(1, _magicH);
    data.setUint8(2, _version);
    data.setUint8(3, type.wireValue);
    data.setUint32(4, sequence, Endian.big);
    data.setUint8(8, byte);
    return data.buffer.asUint8List();
  }

  static LinkFlowFrame? decode(Uint8List bytes) {
    if (bytes.length != wireLength) return null;
    if (bytes[0] != _magicR ||
        bytes[1] != _magicH ||
        bytes[2] != _version) {
      return null;
    }

    final type = LinkFlowFrameType.fromWire(bytes[3]);
    if (type == null) return null;

    final data = ByteData.sublistView(bytes);
    return LinkFlowFrame(
      type: type,
      sequence: data.getUint32(4, Endian.big),
      byte: data.getUint8(8),
    );
  }
}

enum LinkFlowReceiveResult {
  accepted,
  ignoredDuplicate,
  ignoredCollision,
  invalid,
  busy,
}

/// Coordina transferencias de un byte con una sola operación pendiente.
///
/// El rol host se usa únicamente para desempatar el caso excepcional en que
/// ambos cores inician una transferencia a la vez. No convierte al host
/// Bluetooth en maestro permanente del puerto serie.
class LinkFlowController {
  LinkFlowController({bool isTransportHost = false})
      : _isTransportHost = isTransportHost;

  bool _isTransportHost;
  int _nextSequence = 0;
  _LocalRequest? _localRequest;
  _RemoteRequest? _remoteRequest;
  _InboundDelivery? _inboundDelivery;
  int? _lastCompletedRemoteSequence;
  int? _lastCompletedLocalSequence;

  bool get canReadCoreByte =>
      _inboundDelivery == null &&
      (_remoteRequest?.deliveredToCore == true ||
          (_remoteRequest == null && _localRequest == null));

  bool get hasPendingTransfer =>
      _localRequest != null ||
      _remoteRequest != null ||
      _inboundDelivery != null;

  int? get byteWaitingForCore => _inboundDelivery?.byte;

  void reset({required bool isTransportHost}) {
    _isTransportHost = isTransportHost;
    _nextSequence = 0;
    _localRequest = null;
    _remoteRequest = null;
    _inboundDelivery = null;
    _lastCompletedRemoteSequence = null;
    _lastCompletedLocalSequence = null;
  }

  /// Recibe una trama remota. El byte no se confirma ni se responde hasta
  /// que [confirmByteDeliveredToCore] indique que SameBoy lo aceptó.
  LinkFlowReceiveResult receive(Uint8List packet) {
    final frame = LinkFlowFrame.decode(packet);
    if (frame == null) return LinkFlowReceiveResult.invalid;

    switch (frame.type) {
      case LinkFlowFrameType.request:
        return _receiveRequest(frame);
      case LinkFlowFrameType.reply:
        return _receiveReply(frame);
    }
  }

  LinkFlowReceiveResult _receiveRequest(LinkFlowFrame frame) {
    if (frame.sequence == _lastCompletedRemoteSequence) {
      return LinkFlowReceiveResult.ignoredDuplicate;
    }
    if (_inboundDelivery != null || _remoteRequest != null) {
      return LinkFlowReceiveResult.busy;
    }

    final local = _localRequest;
    if (local != null) {
      if (_isTransportHost) {
        // En una colisión ambos bytes representan la misma transferencia.
        // El host conserva su request; el cliente lo convertirá en reply.
        return LinkFlowReceiveResult.ignoredCollision;
      }

      _remoteRequest = _RemoteRequest(
        sequence: frame.sequence,
        byte: frame.byte,
        collisionReplyByte: local.byte,
      );
      _inboundDelivery = _InboundDelivery(
        kind: _InboundKind.request,
        sequence: frame.sequence,
        byte: frame.byte,
      );
      _localRequest = null;
      return LinkFlowReceiveResult.accepted;
    }

    _remoteRequest = _RemoteRequest(
      sequence: frame.sequence,
      byte: frame.byte,
    );
    _inboundDelivery = _InboundDelivery(
      kind: _InboundKind.request,
      sequence: frame.sequence,
      byte: frame.byte,
    );
    return LinkFlowReceiveResult.accepted;
  }

  LinkFlowReceiveResult _receiveReply(LinkFlowFrame frame) {
    if (frame.sequence == _lastCompletedLocalSequence) {
      return LinkFlowReceiveResult.ignoredDuplicate;
    }
    final local = _localRequest;
    if (local == null || local.sequence != frame.sequence) {
      return LinkFlowReceiveResult.busy;
    }
    if (_inboundDelivery != null) return LinkFlowReceiveResult.busy;

    _inboundDelivery = _InboundDelivery(
      kind: _InboundKind.reply,
      sequence: frame.sequence,
      byte: frame.byte,
    );
    return LinkFlowReceiveResult.accepted;
  }

  /// Confirma que [byteWaitingForCore] fue aceptado por `rh_link_send`.
  /// Puede devolver un reply inmediato al resolver una colisión.
  Uint8List? confirmByteDeliveredToCore() {
    final delivery = _inboundDelivery;
    if (delivery == null) return null;
    _inboundDelivery = null;

    switch (delivery.kind) {
      case _InboundKind.reply:
        _lastCompletedLocalSequence = delivery.sequence;
        _localRequest = null;
        return null;
      case _InboundKind.request:
        final remote = _remoteRequest;
        if (remote == null || remote.sequence != delivery.sequence) {
          return null;
        }
        remote.deliveredToCore = true;

        final collisionReply = remote.collisionReplyByte;
        if (collisionReply == null) return null;
        return _finishRemoteRequest(collisionReply);
    }
  }

  /// Consume exactamente un byte del outbox de SameBoy.
  ///
  /// Si existe un request remoto, el byte se convierte en su reply. Si el
  /// enlace está libre, inicia una transferencia local nueva.
  Uint8List acceptCoreByte(int byte) {
    if (byte < 0 || byte > 0xff) {
      throw RangeError.range(byte, 0, 0xff, 'byte');
    }
    if (!canReadCoreByte) {
      throw StateError('Hay una transferencia Link pendiente');
    }

    final remote = _remoteRequest;
    if (remote?.deliveredToCore == true) {
      return _finishRemoteRequest(byte);
    }

    final sequence = _nextSequence;
    _nextSequence = (_nextSequence + 1) & 0xffffffff;
    _localRequest = _LocalRequest(sequence: sequence, byte: byte);
    return LinkFlowFrame(
      type: LinkFlowFrameType.request,
      sequence: sequence,
      byte: byte,
    ).encode();
  }

  Uint8List _finishRemoteRequest(int replyByte) {
    final remote = _remoteRequest!;
    _lastCompletedRemoteSequence = remote.sequence;
    _remoteRequest = null;
    return LinkFlowFrame(
      type: LinkFlowFrameType.reply,
      sequence: remote.sequence,
      byte: replyByte,
    ).encode();
  }
}

class _LocalRequest {
  const _LocalRequest({required this.sequence, required this.byte});

  final int sequence;
  final int byte;
}

class _RemoteRequest {
  _RemoteRequest({
    required this.sequence,
    required this.byte,
    this.collisionReplyByte,
  });

  final int sequence;
  final int byte;
  final int? collisionReplyByte;
  bool deliveredToCore = false;
}

enum _InboundKind { request, reply }

class _InboundDelivery {
  const _InboundDelivery({
    required this.kind,
    required this.sequence,
    required this.byte,
  });

  final _InboundKind kind;
  final int sequence;
  final int byte;
}
