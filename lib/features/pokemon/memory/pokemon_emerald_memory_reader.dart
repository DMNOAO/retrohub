import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';
import '../../emulator/data/libretro_bridge.dart';
import '../../emulator/presentation/widget/libretro_game_view.dart';

/// Primera lectura segura de Pokémon Emerald.
///
/// Emerald mantiene el progreso en dos bloques alojados dinámicamente en
/// EWRAM. Las direcciones de los punteros globales cambian entre regiones y
/// revisiones, por lo que se usa la dirección inglesa como ruta rápida y se
/// recorre IWRAM como alternativa validada.
final class PokemonEmeraldMemoryReader {
  static const int _englishSaveBlock1PointerAddress = 0x03005D8C;
  static const int _englishSaveBlock2PointerAddress = 0x03005D90;

  static const int _iwramStart = 0x03000000;
  static const int _iwramSize = 0x00008000;
  static const int _ewramStart = 0x02000000;
  static const int _ewramEnd = 0x02040000;

  static const int _saveBlock1Size = 0x3D88;
  static const int _saveBlock2Size = 0x0F2C;

  final LibretroGameController? controller;
  final LibretroBridge? bridge;
  final PokemonGameProfile profile;

  const PokemonEmeraldMemoryReader({
    required LibretroGameController this.controller,
    required this.profile,
  }) : bridge = null;

  const PokemonEmeraldMemoryReader.fromBridge({
    required LibretroBridge this.bridge,
    required this.profile,
  }) : controller = null;

  PokemonMemorySnapshot? capture() {
    final bool memoryAvailable =
        controller?.isAttached ?? (bridge?.isGameLoaded ?? false);
    if (!memoryAvailable ||
        profile.version != PokemonGameVersion.emerald) {
      return null;
    }

    final _EmeraldSaveBlocks? blocks = _resolveSaveBlocks();
    if (blocks == null) return null;

    final int saveBlock1 = blocks.saveBlock1;
    final int saveBlock2 = blocks.saveBlock2;
    final List<int> nameBytes = _read(saveBlock2, 8);
    final String playerName = PokemonDecoder.decodeGen3Text(nameBytes);
    if (playerName.isEmpty) return null;

    final int trainerId = _u16(saveBlock2 + 0x0A);
    final int hours = _u16(saveBlock2 + 0x0E);
    final int minutes = _u8(saveBlock2 + 0x10);

    final int x = _s16(saveBlock1);
    final int y = _s16(saveBlock1 + 0x02);
    final int mapGroup = _u8(saveBlock1 + 0x04);
    final int mapNumber = _u8(saveBlock1 + 0x05);
    final int currentMapId = (mapGroup << 8) | mapNumber;

    final int encryptionKey = _u32(saveBlock2 + 0xAC);
    final int money = _u32(saveBlock1 + 0x490) ^ encryptionKey;

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      memoryShift: 0,
      playerName: playerName,
      trainerId: trainerId,
      currentMapId: currentMapId,
      playerX: x,
      playerY: y,
      money: money,
      badgesMask: 0,
      pokedexSeen: 0,
      pokedexCaught: 0,
      seenPokemonIds: const <int>[],
      caughtPokemonIds: const <int>[],
      party: const <PokemonPartyMember>[],
      gamePlayTimeMinutes: hours * 60 + minutes,
    );
  }

  _EmeraldSaveBlocks? _resolveSaveBlocks() {
    final int? englishSaveBlock1 =
        _readPointer(_englishSaveBlock1PointerAddress);
    final int? englishSaveBlock2 =
        _readPointer(_englishSaveBlock2PointerAddress);
    if (_validPair(englishSaveBlock1, englishSaveBlock2)) {
      return _EmeraldSaveBlocks(
        saveBlock1: englishSaveBlock1!,
        saveBlock2: englishSaveBlock2!,
      );
    }

    // En Emerald los globals gSaveBlock1Ptr y gSaveBlock2Ptr son punteros
    // contiguos. Buscar el par en IWRAM evita mantener una dirección por cada
    // idioma, pero las validaciones de ambos bloques impiden falsos positivos.
    final List<int> iwram = _read(_iwramStart, _iwramSize);
    if (iwram.length != _iwramSize) return null;

    for (int offset = 0; offset <= iwram.length - 8; offset += 4) {
      final int saveBlock1 =
          _littleEndian(iwram.sublist(offset, offset + 4));
      final int saveBlock2 =
          _littleEndian(iwram.sublist(offset + 4, offset + 8));
      if (_validPair(saveBlock1, saveBlock2)) {
        return _EmeraldSaveBlocks(
          saveBlock1: saveBlock1,
          saveBlock2: saveBlock2,
        );
      }
    }
    return null;
  }

  bool _validPair(int? saveBlock1, int? saveBlock2) {
    if (!_validBlock(saveBlock1, _saveBlock1Size) ||
        !_validBlock(saveBlock2, _saveBlock2Size)) {
      return false;
    }

    final List<int> name = _read(saveBlock2!, 8);
    if (!_validPlayerName(name)) return false;

    final int hours = _u16(saveBlock2 + 0x0E);
    final int minutes = _u8(saveBlock2 + 0x10);
    final int seconds = _u8(saveBlock2 + 0x11);
    final int frames = _u8(saveBlock2 + 0x12);
    if (hours > 9999 || minutes > 59 || seconds > 59 || frames > 59) {
      return false;
    }

    final int x = _s16(saveBlock1!);
    final int y = _s16(saveBlock1 + 0x02);
    final int mapGroup = _u8(saveBlock1 + 0x04);
    final int mapNumber = _u8(saveBlock1 + 0x05);
    if (x < -1 ||
        x > 255 ||
        y < -1 ||
        y > 255 ||
        mapGroup > 63 ||
        mapNumber > 127) {
      return false;
    }

    final int encryptionKey = _u32(saveBlock2 + 0xAC);
    final int money = _u32(saveBlock1 + 0x490) ^ encryptionKey;
    return money >= 0 && money <= 999999;
  }

  bool _validPlayerName(List<int> bytes) {
    if (bytes.length != 8) return false;
    final int terminator = bytes.indexOf(0xFF);
    if (terminator < 1 || terminator > 7) return false;

    for (final int value in bytes.take(terminator)) {
      final bool supported =
          value == 0x00 ||
          (value >= 0xA1 && value <= 0xB6) ||
          (value >= 0xBB && value <= 0xEE);
      if (!supported) return false;
    }
    return PokemonDecoder.decodeGen3Text(bytes).isNotEmpty;
  }

  int? _readPointer(int address) {
    final List<int> bytes = _read(address, 4);
    if (bytes.length != 4) return null;
    return _littleEndian(bytes);
  }

  bool _validBlock(int? address, int size) {
    if (address == null || address < _ewramStart) return false;
    return address <= _ewramEnd - size;
  }

  List<int> _read(int address, int length) {
    final LibretroGameController? activeController = controller;
    if (activeController != null) {
      return activeController.readMemoryAddress(
        address: address,
        length: length,
      );
    }
    return bridge?.readMemoryAddress(
          address: address,
          length: length,
        ) ??
        const <int>[];
  }

  int _u8(int address) {
    final List<int> bytes = _read(address, 1);
    return bytes.length == 1 ? bytes.first : 0;
  }

  int _u16(int address) {
    final List<int> bytes = _read(address, 2);
    return bytes.length == 2 ? _littleEndian(bytes) : 0;
  }

  int _u32(int address) {
    final List<int> bytes = _read(address, 4);
    return bytes.length == 4 ? _littleEndian(bytes) : 0;
  }

  int _s16(int address) {
    final int value = _u16(address);
    return value >= 0x8000 ? value - 0x10000 : value;
  }

  int _littleEndian(List<int> bytes) {
    int value = 0;
    for (int index = 0; index < bytes.length; index++) {
      value |= (bytes[index] & 0xFF) << (index * 8);
    }
    return value;
  }
}

final class _EmeraldSaveBlocks {
  final int saveBlock1;
  final int saveBlock2;

  const _EmeraldSaveBlocks({
    required this.saveBlock1,
    required this.saveBlock2,
  });
}
