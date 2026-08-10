import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Nombre del servicio Bluetooth usado por RetroHub Link.
///
/// IMPORTANTE:
/// El nombre del servicio RFCOMM no necesariamente coincide con el nombre
/// Bluetooth visible del teléfono durante el discovery. Por eso, durante
/// esta etapa de diagnóstico no filtramos dispositivos por nombre.
const String kRetroHubLinkDeviceName = 'RetroHub Link';

/// Envuelve el descubrimiento de dispositivos Bluetooth Classic.
///
/// Por ahora devuelve todos los dispositivos encontrados y todos los
/// dispositivos emparejados. Esto permite comprobar que el cliente puede
/// localizar al teléfono que está actuando como host y obtener su dirección
/// Bluetooth para intentar la conexión RFCOMM.
class BluetoothDiscovery {
  const BluetoothDiscovery();

  /// `true` si el adaptador Bluetooth del dispositivo está encendido.
  Future<bool> isEnabled() async {
    return await FlutterBluetoothSerial.instance.isEnabled ?? false;
  }

  /// Pide al usuario activar Bluetooth (diálogo del sistema).
  Future<bool> requestEnable() async {
    return await FlutterBluetoothSerial.instance.requestEnable() ?? false;
  }

  /// Pide al usuario poner el teléfono en modo Bluetooth *descubrible*
  /// durante [durationInSeconds] segundos.
  ///
  /// Crear un `BluetoothServerSocket` y quedar en `accept()` NO implica
  /// que el teléfono sea visible durante el discovery de otro
  /// dispositivo — son dos estados distintos de Android. Este método
  /// pide explícitamente el segundo. Devuelve `true` si el usuario
  /// aceptó (o el sistema ya lo concedió); `false` si lo canceló o
  /// falló.
  Future<bool> requestDiscoverable({int durationInSeconds = 120}) async {
    final int? secondsAcquired = await FlutterBluetoothSerial.instance
        .requestDiscoverable(durationInSeconds);
    final bool acquired = (secondsAcquired ?? 0) > 0;

    debugPrint(
      '[RetroHub BT] requestDiscoverable($durationInSeconds) -> '
      'secondsAcquired=$secondsAcquired',
    );

    return acquired;
  }

  /// Emite todos los dispositivos Bluetooth Classic encontrados durante
  /// el discovery.
  ///
  /// No filtramos por `device.name == "RetroHub Link"` porque el host puede
  /// conservar el nombre Bluetooth normal del teléfono aunque RetroHub haya
  /// abierto un servicio RFCOMM llamado "RetroHub Link".
  Stream<BluetoothDevice> discoverRetroHubDevices() {
    debugPrint('[RetroHub BT] DISCOVERY iniciando…');

    final Stream<BluetoothDiscoveryResult> results =
        FlutterBluetoothSerial.instance.startDiscovery();

    return results
        .map((BluetoothDiscoveryResult result) {
          debugPrint(
            '[RetroHub BT] DISCOVERY '
            'name=${result.device.name} '
            'address=${result.device.address} '
            'bondState=${result.device.bondState}',
          );
          return result.device;
        })
        .transform<BluetoothDevice>(
          StreamTransformer<BluetoothDevice, BluetoothDevice>.fromHandlers(
            handleDone: (sink) {
              debugPrint('[RetroHub BT] DISCOVERY terminado');
              sink.close();
            },
          ),
        );
  }

  /// Devuelve todos los dispositivos Bluetooth ya emparejados.
  ///
  /// Esto es especialmente útil para la prueba de Cable Link: si ambos
  /// teléfonos ya están emparejados, el host podrá aparecer inmediatamente
  /// aunque el discovery activo no lo vuelva a encontrar.
  Future<List<BluetoothDevice>> bondedRetroHubDevices() async {
    final List<BluetoothDevice> bonded =
        await FlutterBluetoothSerial.instance.getBondedDevices();

    debugPrint(
      '[RetroHub BT] BONDED encontrados=${bonded.length} '
      '(${bonded.map((d) => '${d.name}/${d.address}').join(', ')})',
    );

    return bonded;
  }
}