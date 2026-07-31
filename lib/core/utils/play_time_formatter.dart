abstract final class PlayTimeFormatter {
  static String fromSeconds(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    if (safe < 60) return safe == 0 ? 'Sin tiempo registrado' : 'Menos de 1 min';
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}
