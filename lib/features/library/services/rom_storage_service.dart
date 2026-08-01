import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../core/emulation/core_loader.dart';

/// Resultado de importar una ROM al almacenamiento permanente de RetroHub.
class ImportedRom {
  /// Ruta permanente y estable del archivo ROM dentro de RetroHub.
  final String path;

  /// Hash SHA-1 del contenido de la ROM. Se usa como id determinístico
  /// del juego: si el usuario reimporta el mismo archivo (por ejemplo,
  /// porque Android borró la caché de file_picker), el id no cambia y
  /// las partidas guardadas, save states y bitácora siguen intactos.
  final String hash;

  /// true si la ROM ya existía en la biblioteca (mismo contenido) y no
  /// hubo que copiar nada de nuevo.
  final bool alreadyImported;

  const ImportedRom({
    required this.path,
    required this.hash,
    required this.alreadyImported,
  });
}

/// Copia las ROMs seleccionadas con file_picker a una carpeta permanente.
///
/// Nunca se debe usar directamente la ruta que entrega file_picker como
/// romPath: esa ruta vive en la caché de la app y el sistema operativo
/// (especialmente Android) puede borrarla en cualquier momento, dejando
/// a SameBoy sin poder abrir el archivo.
class RomStorageService {
  static Future<ImportedRom> importRom({
    required String sourcePath,
    required String console,
    required String extension,
  }) async {
    final File source = File(sourcePath);
    final List<int> bytes = await source.readAsBytes();
    final String hash = sha1.convert(bytes).toString();

    final Directory targetDir = Directory(
      '${CoreLoader.documentsDirectory.path}${Platform.pathSeparator}'
      'RetroHub${Platform.pathSeparator}roms${Platform.pathSeparator}'
      '${console.toLowerCase()}',
    );
    await targetDir.create(recursive: true);

    final String targetPath =
        '${targetDir.path}${Platform.pathSeparator}$hash.$extension';
    final File target = File(targetPath);

    if (await target.exists()) {
      // Mismo contenido ya importado antes: no duplicar el archivo.
      return ImportedRom(
        path: targetPath,
        hash: hash,
        alreadyImported: true,
      );
    }

    await target.writeAsBytes(bytes, flush: true);

    return ImportedRom(
      path: targetPath,
      hash: hash,
      alreadyImported: false,
    );
  }
}
