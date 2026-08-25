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

  group('CoreLoader Nintendo DS', () {
    test('reconoce ROMs NDS sin importar mayúsculas', () {
      expect(CoreLoader.isNdsRom('/roms/Pokemon HeartGold.NDS'), isTrue);
      expect(CoreLoader.isNdsRom('/roms/Pokemon Platinum.nds'), isTrue);
      expect(CoreLoader.isNdsRom('/roms/Pokemon Emerald.gba'), isFalse);
    });

    test('selecciona melonDS DS sólo para ROMs NDS', () {
      expect(CoreLoader.coreForRom('game.nds').id, 'melondsds');
      expect(
        CoreLoader.coreForRom('game.nds').androidLibraryName,
        'libmelondsds_libretro.so',
      );
    });
  });
}
