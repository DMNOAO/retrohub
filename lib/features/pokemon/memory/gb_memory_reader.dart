import '../../../core/emulation/memory/libretro_memory.dart';
import '../models/pokemon_memory_snapshot.dart';

class GbMemoryReader {
  final LibretroMemory memory;

  const GbMemoryReader({
    required this.memory,
  });

  factory GbMemoryReader.open() {
    return GbMemoryReader(
      memory: LibretroMemory.open(),
    );
  }

  PokemonMemorySnapshot captureDiagnosticSnapshot({
    int offset = 0,
    int length = 32,
  }) {
    final int systemRamSize = memory.memorySize(
      LibretroMemoryId.systemRam,
    );

    final List<int> bytes = systemRamSize <= 0
        ? <int>[]
        : memory.readBlock(
            memoryId: LibretroMemoryId.systemRam,
            offset: offset,
            length: length,
          );

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      systemRamSize: systemRamSize,
      diagnosticBytes: bytes,
    );
  }

  Map<String, int> inspectRegions() {
    return memory.inspectAvailableRegions();
  }

  int? readSystemRamByte(int offset) {
    return memory.readByte(
      memoryId: LibretroMemoryId.systemRam,
      offset: offset,
    );
  }

  List<int> readSystemRamBlock({
    required int offset,
    required int length,
  }) {
    return memory.readBlock(
      memoryId: LibretroMemoryId.systemRam,
      offset: offset,
      length: length,
    );
  }
}
