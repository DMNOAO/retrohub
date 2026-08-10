/// Estados posibles de una sesión Link, independientes del transporte
/// (Bluetooth, WiFi, LAN, USB, QR, etc.) y del emulador.
///
/// Tanto [LinkTransport] como [LinkManager] reportan su estado usando este
/// enum, para que la UI de RetroHub siempre reaccione de la misma forma
/// sin importar qué transporte esté activo por debajo.
enum LinkState {
  /// No hay ninguna sesión activa ni intento de conexión en curso.
  disconnected,

  /// Buscando un jugador/host disponible (lado del que se une).
  searching,

  /// Esperando que otro jugador se conecte (lado del host).
  hosting,

  /// Conexión en curso hacia un host ya localizado.
  connecting,

  /// Conexión establecida, lista para transmitir el puerto serie del
  /// Cable Link.
  connected,

  /// Conexión establecida y sincronizando frame a frame con el otro
  /// dispositivo.
  syncing,

  /// La sesión terminó por un error (fallo de transporte, desconexión
  /// inesperada, etc.).
  error,
}
