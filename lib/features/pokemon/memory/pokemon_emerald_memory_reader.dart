import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';
import '../../emulator/presentation/widget/libretro_game_view.dart';

/// Primera lectura segura de Pokémon Emerald.
///
/// Emerald mantiene el progreso en dos bloques alojados dinámicamente en
/// EWRAM. Los punteros globales viven en IWRAM y deben resolverse en cada
/// captura; no se deben tratar los campos como direcciones absolutas.
final class PokemonEmeraldMemoryReader {
  static const int _saveBlock1PointerAddress = 0x03005D8C;
  static const int _saveBlock2PointerAddress = 0x03005D90;

  static const int _ewramStart = 0x02000000;
  static const int _ewramEnd = 0x02040000;

  static const int _saveBlock1Size = 0x3D88;
  static const int _saveBlock2Size = 0x0F2C;

  final LibretroGameController controller;
  final PokemonGameProfile profile;

  const PokemonEmeraldMemoryReader({
    required this.controller,
    required this.profile,
  });

  PokemonMemorySnapshot? capture() {
    if (!controller.isAttached ||
        profile.version != PokemonGameVersion.emerald) {
      return null;
    }

    final int? saveBlock1 = _readPointer(_saveBlock1PointerAddress);
    final int? saveBlock2 = _readPointer(_saveBlock2PointerAddress);
    if (!_validBlock(saveBlock1, _saveBlock1Size) ||
        !_validBlock(saveBlock2, _saveBlock2Size)) {
      return null;
    }

    final List<int> nameBytes = _read(saveBlock2!, 8);
    final String playerName = PokemonDecoder.decodeGen3Text(nameBytes);
    if (playerName.isEmpty) return null;

    final int trainerId = _u16(saveBlock2 + 0x0A);
    final int hours = _u16(saveBlock2 + 0x0E);
    final int minutes = _u8(saveBlock2 + 0x10);
    if (minutes > 59) return null;

    final int x = _s16(saveBlock1!);
    final int y = _s16(saveBlock1 + 0x02);
    final int mapGroup = _u8(saveBlock1 + 0x04);
    final int mapNumber = _u8(saveBlock1 + 0x05);
    final int currentMapId = (mapGroup << 8) | mapNumber;

    final int encryptionKey = _u32(saveBlock2 + 0xAC);
    final int money = _u32(saveBlock1 + 0x490) ^ encryptionKey;
    if (money < 0 || money > 999999) return null;

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

  int? _readPointer(int address) {
    final List<int> bytes = _read(address, 4);
    if (bytes.length != 4) return null;
    return _littleEndian(bytes);
  }

  bool _validBlock(int? address, int size) {
    if (address == null || address < _ewramStart) return false;
    return address <= _ewramEnd - size;
  }

  List<int> _read(int address, int length) =>
      controller.readMemoryAddress(address: address, length: length);

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
