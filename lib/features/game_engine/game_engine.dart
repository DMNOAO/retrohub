import 'dart:typed_data';

abstract interface class GameMemoryAccess {
  int memoryRegionSize(int memoryId);

  int? readMemoryByte({
    required int memoryId,
    required int offset,
  });

  Uint8List readMemoryBlock({
    required int memoryId,
    required int offset,
    required int length,
  });
}

abstract interface class GameEngine<TSnapshot> {
  String get engineName;
  String get gameName;
  bool get isSupported;
  TSnapshot? capture();
  void dispose();
}
