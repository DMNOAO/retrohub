/// Traduce direcciones CPU de la WRAM de Game Boy Color al bloque lineal de
/// 32 KiB que SameBoy publica como RETRO_MEMORY_SYSTEM_RAM.
///
/// Distribución usada por SameBoy:
/// - 0x0000..0x0FFF -> WRAM0 (CPU 0xC000..0xCFFF)
/// - 0x1000..0x1FFF -> WRAM1 (CPU 0xD000..0xDFFF)
/// - 0x2000..0x2FFF -> WRAM2
/// - ...
/// - 0x7000..0x7FFF -> WRAM7
abstract final class GbcMemoryMapper {
  static const int bankSize = 0x1000;
  static const int fixedBankCpuStart = 0xC000;
  static const int switchableBankCpuStart = 0xD000;
  static const int maximumBank = 7;
  static const int systemRamSize = 0x8000;

  static int toSystemRamOffset({
    required int bank,
    required int cpuAddress,
  }) {
    if (bank < 0 || bank > maximumBank) {
      throw RangeError.range(bank, 0, maximumBank, 'bank');
    }

    if (bank == 0) {
      if (cpuAddress < fixedBankCpuStart || cpuAddress > 0xCFFF) {
        throw RangeError(
          'La dirección del banco 0 debe estar entre 0xC000 y 0xCFFF.',
        );
      }
      return cpuAddress - fixedBankCpuStart;
    }

    if (cpuAddress < switchableBankCpuStart || cpuAddress > 0xDFFF) {
      throw RangeError(
        'La dirección de un banco WRAM conmutable debe estar entre '
        '0xD000 y 0xDFFF.',
      );
    }

    return (bank * bankSize) + (cpuAddress - switchableBankCpuStart);
  }

  static bool isValidSystemRamRange(int offset, int length) {
    return offset >= 0 &&
        length >= 0 &&
        offset + length <= systemRamSize;
  }

  static int bankForOffset(int offset) {
    if (offset < 0 || offset >= systemRamSize) {
      throw RangeError.range(offset, 0, systemRamSize - 1, 'offset');
    }
    return offset ~/ bankSize;
  }

  static int cpuAddressForOffset(int offset) {
    final int bank = bankForOffset(offset);
    final int inBank = offset % bankSize;
    return (bank == 0 ? fixedBankCpuStart : switchableBankCpuStart) + inBank;
  }
}
