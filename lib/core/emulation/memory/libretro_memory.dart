import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../core_loader.dart';

abstract final class LibretroMemoryId {
  static const int saveRam = 0;
  static const int rtc = 1;
  static const int systemRam = 2;
  static const int videoRam = 3;
}

typedef _GetMemorySizeNative = Size Function(Uint32 memoryId);
typedef _GetMemorySizeDart = int Function(int memoryId);

typedef _ReadMemoryByteNative = Int32 Function(
  Uint32 memoryId,
  Size offset,
);
typedef _ReadMemoryByteDart = int Function(
  int memoryId,
  int offset,
);

typedef _ReadMemoryBlockNative = Size Function(
  Uint32 memoryId,
  Size offset,
  Pointer<Uint8> destination,
  Size destinationSize,
);
typedef _ReadMemoryBlockDart = int Function(
  int memoryId,
  int offset,
  Pointer<Uint8> destination,
  int destinationSize,
);

class LibretroMemory {
  final DynamicLibrary _library;

  late final _GetMemorySizeDart _getMemorySize;
  late final _ReadMemoryByteDart _readMemoryByte;
  late final _ReadMemoryBlockDart _readMemoryBlock;

  LibretroMemory._(this._library) {
    _getMemorySize = _library.lookupFunction<
        _GetMemorySizeNative,
        _GetMemorySizeDart>(
      'rh_get_memory_region_size',
    );

    _readMemoryByte = _library.lookupFunction<
        _ReadMemoryByteNative,
        _ReadMemoryByteDart>(
      'rh_read_memory_byte',
    );

    _readMemoryBlock = _library.lookupFunction<
        _ReadMemoryBlockNative,
        _ReadMemoryBlockDart>(
      'rh_read_memory_block',
    );
  }

  factory LibretroMemory.open() {
    final DynamicLibrary? library = CoreLoader.loadBridge();

    if (library == null) {
      throw StateError(
        'No se pudo cargar libretro_bridge.dll.',
      );
    }

    return LibretroMemory._(library);
  }

  int memorySize(int memoryId) {
    return _getMemorySize(memoryId);
  }

  int? readByte({
    required int memoryId,
    required int offset,
  }) {
    if (offset < 0) {
      return null;
    }

    final int value = _readMemoryByte(
      memoryId,
      offset,
    );

    return value < 0 ? null : value;
  }

  Uint8List readBlock({
    required int memoryId,
    required int offset,
    required int length,
  }) {
    if (offset < 0 || length <= 0) {
      return Uint8List(0);
    }

    final Pointer<Uint8> buffer = calloc<Uint8>(length);

    try {
      final int read = _readMemoryBlock(
        memoryId,
        offset,
        buffer,
        length,
      );

      if (read <= 0) {
        return Uint8List(0);
      }

      return Uint8List.fromList(
        buffer.asTypedList(read),
      );
    } finally {
      calloc.free(buffer);
    }
  }

  Map<String, int> inspectAvailableRegions() {
    return <String, int>{
      'saveRam': memorySize(LibretroMemoryId.saveRam),
      'rtc': memorySize(LibretroMemoryId.rtc),
      'systemRam': memorySize(LibretroMemoryId.systemRam),
      'videoRam': memorySize(LibretroMemoryId.videoRam),
    };
  }
}
