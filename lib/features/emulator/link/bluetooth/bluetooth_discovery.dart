import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

/// Nombre del servicio Bluetooth usado por RetroHub Link.
const String kRetroHubLinkDeviceName = 'RetroHub Link';

/// Envuelve permisos, activación y descubrimiento Bluetooth Classic.
///
/// En Android 12+ los permisos Bluetooth son runtime permissions.
/// Nunca debemos llamar a getBondedDevices/startDiscovery antes de
/// comprobarlos, porque Android puede lanzar SecurityException.
class BluetoothDiscovery {
  const BluetoothDiscovery();

  /// Solicita los permisos necesarios para Bluetooth Classic.
  ///
  /// Android 12+:
  /// - BLUETOOTH_CONNECT
  /// - BLUETOOTH_SCAN
  /// - BLUETOOTH_ADVERTISE
  ///
  /// Android <= 11:
  /// - ubicación para discovery
  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final Map<Permission, PermissionStatus> bluetoothStatuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
      ].request();

      final bool bluetoothGranted =
          bluetoothStatuses[Permission.bluetoothConnect]?.isGranted == true &&
          bluetoothStatuses[Permission.bluetoothScan]?.isGranted == true;

      if (bluetoothGranted) {
        debugPrint('[RetroHub BT] Permisos Bluetooth concedidos');
        return true;
      }

      // En Android antiguos permission_handler puede manejar Bluetooth
      // mediante los permisos legacy + ubicación.
      final PermissionStatus locationStatus = await Permission.locationWhenInUse
          .request();

      if (locationStatus.isGranted) {
        debugPrint(
          '[RetroHub BT] Permiso de ubicación concedido para Bluetooth legacy',
        );
        return true;
      }

      debugPrint(
        '[RetroHub BT] Permisos Bluetooth rechazados: $bluetoothStatuses',
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        '[RetroHub BT] Error solicitando permisos: $error\n$stackTrace',
      );
      return false;
    }
  }

  /// `true` si el adaptador Bluetooth está encendido.
  Future<bool> isEnabled() async {
    try {
      if (!await ensurePermissions()) {
        return false;
      }

      return await FlutterBluetoothSerial.instance.isEnabled ?? false;
    } catch (error, stackTrace) {
      debugPrint(
        '[RetroHub BT] Error comprobando Bluetooth: $error\n$stackTrace',
      );
      return false;
    }
  }

  /// Pide al usuario activar Bluetooth.
  Future<bool> requestEnable() async {
    try {
      if (!await ensurePermissions()) {
        return false;
      }

      return await FlutterBluetoothSerial.instance.requestEnable() ?? false;
    } catch (error, stackTrace) {
      debugPrint(
        '[RetroHub BT] Error activando Bluetooth: $error\n$stackTrace',
      );
      return false;
    }
  }

  /// Pone temporalmente el dispositivo en modo descubrible.
  Future<bool> requestDiscoverable({int durationInSeconds = 120}) async {
    try {
      if (!await ensurePermissions()) {
        return false;
      }

      final int? secondsAcquired = await FlutterBluetoothSerial.instance
          .requestDiscoverable(durationInSeconds);

      final bool acquired = (secondsAcquired ?? 0) > 0;

      debugPrint(
        '[RetroHub BT] requestDiscoverable($durationInSeconds) -> '
        'secondsAcquired=$secondsAcquired',
      );

      return acquired;
    } catch (error, stackTrace) {
      debugPrint(
        '[RetroHub BT] Error solicitando modo descubrible: '
        '$error\n$stackTrace',
      );

      return false;
    }
  }

  /// Busca dispositivos Bluetooth Classic.
  ///
  /// Si no existen permisos, devuelve un stream vacío en vez de permitir
  /// que Android cierre RetroHub con SecurityException.
  Stream<BluetoothDevice> discoverRetroHubDevices() async* {
    if (!await ensurePermissions()) {
      debugPrint('[RetroHub BT] DISCOVERY cancelado: permisos insuficientes');
      return;
    }

    debugPrint('[RetroHub BT] DISCOVERY iniciando…');

    try {
      final Stream<BluetoothDiscoveryResult> results = FlutterBluetoothSerial
          .instance
          .startDiscovery();

      await for (final BluetoothDiscoveryResult result in results) {
        debugPrint(
          '[RetroHub BT] DISCOVERY '
          'name=${result.device.name} '
          'address=${result.device.address} '
          'bondState=${result.device.bondState}',
        );

        yield result.device;
      }

      debugPrint('[RetroHub BT] DISCOVERY terminado');
    } catch (error, stackTrace) {
      debugPrint('[RetroHub BT] Error durante discovery: $error\n$stackTrace');
    }
  }

  /// Devuelve los dispositivos Bluetooth ya emparejados.
  ///
  /// Fundamentalmente, no ejecutamos getBondedDevices hasta tener
  /// BLUETOOTH_CONNECT.
  Future<List<BluetoothDevice>> bondedRetroHubDevices() async {
    if (!await ensurePermissions()) {
      debugPrint('[RetroHub BT] BONDED cancelado: permisos insuficientes');
      return <BluetoothDevice>[];
    }

    try {
      final List<BluetoothDevice> bonded = await FlutterBluetoothSerial.instance
          .getBondedDevices();

      debugPrint(
        '[RetroHub BT] BONDED encontrados=${bonded.length} '
        '(${bonded.map((d) => '${d.name}/${d.address}').join(', ')})',
      );

      return bonded;
    } catch (error, stackTrace) {
      debugPrint(
        '[RetroHub BT] Error obteniendo dispositivos emparejados: '
        '$error\n$stackTrace',
      );

      return <BluetoothDevice>[];
    }
  }
}
