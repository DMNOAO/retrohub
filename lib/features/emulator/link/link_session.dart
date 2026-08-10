import 'link_state.dart';

/// Datos de una sesión Link activa (o recién cerrada).
///
/// Es un contenedor puro: no valida, no transmite, no decide nada.
/// Quien construye y actualiza instancias de [LinkSession] es
/// [LinkManager]; este archivo solo describe la forma de los datos.
class LinkSession {
  const LinkSession({
    required this.id,
    required this.isHost,
    required this.localName,
    required this.state,
    this.remoteName,
    this.connectedAt,
  });

  /// Identificador único de la sesión (generado localmente).
  final String id;

  /// `true` si este dispositivo creó la sesión (host), `false` si se unió
  /// a una existente.
  final bool isHost;

  /// Nombre visible del jugador local.
  final String localName;

  /// Nombre visible del jugador remoto, una vez conocido. `null` hasta
  /// que la conexión se establece.
  final String? remoteName;

  /// Momento en el que la sesión pasó a [LinkState.connected] por primera
  /// vez. `null` si todavía no se ha conectado.
  final DateTime? connectedAt;

  /// Estado actual de la sesión.
  final LinkState state;

  LinkSession copyWith({
    String? remoteName,
    DateTime? connectedAt,
    LinkState? state,
  }) {
    return LinkSession(
      id: id,
      isHost: isHost,
      localName: localName,
      remoteName: remoteName ?? this.remoteName,
      connectedAt: connectedAt ?? this.connectedAt,
      state: state ?? this.state,
    );
  }

  @override
  String toString() {
    return 'LinkSession(id: $id, isHost: $isHost, localName: $localName, '
        'remoteName: $remoteName, state: $state)';
  }
}
