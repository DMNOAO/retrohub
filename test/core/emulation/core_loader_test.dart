import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/emulation/core_loader.dart';

void main() {
  group('CoreLoader SNES', () {
    test('reconoce extensiones SNES sin importar mayúsculas', () {
      expect(CoreLoader.isSnesRom('/roms/Super Mario World.SFC'), isTrue);
      expect(CoreLoader.isSnesRom('/roms/Zelda.smc'), isTrue);
      expect(CoreLoader.isSnesRom('/roms/Pokemon.gba'), isFalse);
    });

    test('selecciona el backend SNES sólo para ROMs SNES', () {
      expect(CoreLoader.coreForRom('game.sfc').id, 'snes');
      expect(CoreLoader.coreForRom('game.gba').id, 'mgba');
      expect(CoreLoader.coreForRom('game.gbc').id, 'sameboy');
    });
  });
}
