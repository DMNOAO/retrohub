/// Decodifica la tabla internacional de glifos de Diamante, Perla y Platino.
/// No es UTF-16: cada palabra es un índice en la fuente interna del juego.
abstract final class PokemonGen4TextDecoder {
  static String decodeWords(Iterable<int> values) {
    final StringBuffer result = StringBuffer();
    for (final int value in values) {
      if (value == 0xFFFF) break;
      final String? character = _character(value);
      if (character != null) result.write(character);
    }
    return result.toString().trim();
  }

  static String? _character(int value) {
    if (value >= 0x121 && value <= 0x12A) {
      return String.fromCharCode(0x30 + value - 0x121);
    }
    if (value >= 0x12B && value <= 0x144) {
      return String.fromCharCode(0x41 + value - 0x12B);
    }
    if (value >= 0x145 && value <= 0x15E) {
      return String.fromCharCode(0x61 + value - 0x145);
    }
    if (value >= 0x15F && value <= 0x1A1) {
      return _latin[value - 0x15F];
    }
    return _symbols[value];
  }

  static const List<String> _latin = <String>[
    'À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì',
    'Í', 'Î', 'Ï', 'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', '×', 'Ø', 'Ù',
    'Ú', 'Û', 'Ü', 'Ý', 'Þ', 'ß', 'à', 'á', 'â', 'ã', 'ä', 'å', 'æ',
    'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï', 'ð', 'ñ', 'ò', 'ó',
    'ô', 'õ', 'ö', '÷', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ', 'ÿ', 'Œ',
    'œ', 'Ş', 'ş',
  ];

  static const Map<int, String> _symbols = <int, String>{
    0x1A8: r'$', 0x1A9: '¡', 0x1AA: '¿', 0x1AB: '!', 0x1AC: '?',
    0x1AD: ',', 0x1AE: '.', 0x1B1: '/', 0x1B3: "'", 0x1B8: '«',
    0x1B9: '»', 0x1BA: '(', 0x1BB: ')', 0x1BD: '♂', 0x1BE: '♀',
    0x1BF: '+', 0x1C0: '-', 0x1C1: '*', 0x1C2: '#', 0x1C3: '=',
    0x1C4: '&', 0x1C5: '~', 0x1C6: ':', 0x1C7: ';', 0x1D0: '@',
    0x1D2: '%', 0x1DE: ' ', 0x1E8: '°', 0x1E9: '_',
  };
}
