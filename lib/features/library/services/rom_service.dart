import '../models/rom_info.dart';

class RomService {
  static RomInfo? parseRom(String path, String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    String? console;

    switch (extension) {
      case 'gb':
        console = 'GB';
        break;
      case 'gbc':
        console = 'GBC';
        break;
      case 'gba':
        console = 'GBA';
        break;
      case 'smc':
      case 'sfc':
        console = 'SNES';
        break;
    }

    if (console == null) return null;

    final title = fileName.replaceFirst(
      RegExp(r'\.[^.]+$'),
      '',
    );

    return RomInfo(
      path: path,
      title: title,
      console: console,
    );
  }
}