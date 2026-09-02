import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/link/link_flow_control.dart';

void main() {
  group('LinkFlowFrame', () {
    test('round-trips request and reply frames', () {
      for (final type in LinkFlowFrameType.values) {
        final encoded = LinkFlowFrame(
          type: type,
          sequence: 0x12345678,
          byte: 0xab,
        ).encode();
        final decoded = LinkFlowFrame.decode(encoded);

        expect(decoded?.type, type);
        expect(decoded?.sequence, 0x12345678);
        expect(decoded?.byte, 0xab);
      }
    });

    test('rejects legacy raw bytes and unknown versions', () {
      expect(LinkFlowFrame.decode(Uint8List.fromList(<int>[0x42])), isNull);

      final packet = LinkFlowFrame(
        type: LinkFlowFrameType.request,
        sequence: 0,
        byte: 0,
      ).encode();
      packet[2] = 99;
      expect(LinkFlowFrame.decode(packet), isNull);
    });
  });

  group('LinkFlowController', () {
    test('completes one balanced byte exchange', () {
      final a = LinkFlowController(isTransportHost: true);
      final b = LinkFlowController(isTransportHost: false);

      final request = a.acceptCoreByte(0x12);
      expect(a.canReadCoreByte, isFalse);
      expect(b.receive(request), LinkFlowReceiveResult.accepted);
      expect(b.byteWaitingForCore, 0x12);

      expect(b.confirmByteDeliveredToCore(), isNull);
      expect(b.canReadCoreByte, isTrue);
      final reply = b.acceptCoreByte(0x34);

      expect(a.receive(reply), LinkFlowReceiveResult.accepted);
      expect(a.byteWaitingForCore, 0x34);
      expect(a.confirmByteDeliveredToCore(), isNull);
      expect(a.hasPendingTransfer, isFalse);
      expect(b.hasPendingTransfer, isFalse);
      expect(a.canReadCoreByte, isTrue);
      expect(b.canReadCoreByte, isTrue);
    });

    test('does not read another core byte while waiting for a reply', () {
      final controller = LinkFlowController();

      controller.acceptCoreByte(0x55);

      expect(controller.canReadCoreByte, isFalse);
      expect(() => controller.acceptCoreByte(0x66), throwsStateError);
    });

    test('transport host wins a simultaneous request collision', () {
      final host = LinkFlowController(isTransportHost: true);
      final client = LinkFlowController(isTransportHost: false);

      final hostRequest = host.acceptCoreByte(0xa1);
      final clientRequest = client.acceptCoreByte(0xb2);

      expect(
        host.receive(clientRequest),
        LinkFlowReceiveResult.ignoredCollision,
      );
      expect(client.receive(hostRequest), LinkFlowReceiveResult.accepted);
      expect(client.byteWaitingForCore, 0xa1);

      final collisionReply = client.confirmByteDeliveredToCore();
      expect(collisionReply, isNotNull);
      expect(host.receive(collisionReply!), LinkFlowReceiveResult.accepted);
      expect(host.byteWaitingForCore, 0xb2);
      host.confirmByteDeliveredToCore();

      expect(host.hasPendingTransfer, isFalse);
      expect(client.hasPendingTransfer, isFalse);
    });

    test('ignores a duplicate completed reply', () {
      final a = LinkFlowController(isTransportHost: true);
      final b = LinkFlowController(isTransportHost: false);
      final request = a.acceptCoreByte(1);
      b.receive(request);
      b.confirmByteDeliveredToCore();
      final reply = b.acceptCoreByte(2);

      a.receive(reply);
      a.confirmByteDeliveredToCore();

      expect(a.receive(reply), LinkFlowReceiveResult.ignoredDuplicate);
      expect(a.byteWaitingForCore, isNull);
    });

    test('keeps thousands of exchanges balanced without queue growth', () {
      final a = LinkFlowController(isTransportHost: true);
      final b = LinkFlowController(isTransportHost: false);

      for (var index = 0; index < 2048; index++) {
        final byteA = index & 0xff;
        final byteB = (0xff - index) & 0xff;
        final request = a.acceptCoreByte(byteA);

        expect(b.receive(request), LinkFlowReceiveResult.accepted);
        expect(b.byteWaitingForCore, byteA);
        b.confirmByteDeliveredToCore();

        final reply = b.acceptCoreByte(byteB);
        expect(a.receive(reply), LinkFlowReceiveResult.accepted);
        expect(a.byteWaitingForCore, byteB);
        a.confirmByteDeliveredToCore();

        expect(a.hasPendingTransfer, isFalse);
        expect(b.hasPendingTransfer, isFalse);
      }
    });
  });
}
