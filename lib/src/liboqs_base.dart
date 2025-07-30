import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'bindings/liboqs_bindings.dart';
import 'platform/library_loader.dart';

/// Base class for liboqs functionality
class LibOQSBase {
  static final DynamicLibrary _lib = LibOQSLoader.loadLibrary(useCache: true);
  static final LibOQSBindings _bindings = LibOQSBindings(_lib);

  //thread-safe initialization
  static bool _initialized = false;

  /// Get the liboqs bindings instance
  static LibOQSBindings get bindings => _bindings;

  /// Thread-safe initialization (simplified)
  static void init() {
    if (!_initialized) {
      bindings.OQS_init();
      _initialized = true;
    }
  }

  /// Clean up liboqs resources
  static void cleanup() {
    if (_initialized) {
      bindings.OQS_thread_stop();
      bindings.OQS_destroy();
      _initialized = false;
    }
  }

  /// Clean up thread-specific resources
  static void cleanupThread() {
    if (_initialized) {
      bindings.OQS_thread_stop();
    }
  }

  static String getVersion() {
    init(); // Auto-initialize if needed
    final versionPtr = bindings.OQS_version();
    final versionString = versionPtr.cast<Utf8>().toDartString();
    return versionString;
  }
}

class LibOQSException implements Exception {
  final String message;
  final int? errorCode;
  final String? algorithmName;

  const LibOQSException(this.message, [this.errorCode, this.algorithmName]);

  @override
  String toString() {
    final parts = <String>['LibOQSException'];
    if (errorCode != null) parts.add('($errorCode)');
    if (algorithmName != null) parts.add('[${algorithmName}]');
    parts.add(': $message');
    return parts.join('');
  }
}

class LibOQSUtils {
  /// Convert a Dart Uint8List to a C pointer
  static Pointer<Uint8> uint8ListToPointer(Uint8List data) {
    if (data.isEmpty) {
      throw ArgumentError('Data cannot be empty');
    }
    final ptr = calloc<Uint8>(data.length);
    final nativeData = ptr.asTypedList(data.length);
    nativeData.setAll(0, data);
    return ptr;
  }

  /// Convert a C pointer to a Dart Uint8List with guaranteed copy
  static Uint8List pointerToUint8List(Pointer<Uint8> ptr, int length) {
    if (ptr == nullptr || length <= 0) {
      return Uint8List(0);
    }

    // Create a new Uint8List and copy data to ensure memory safety
    final data = Uint8List(length);
    final sourceData = ptr.asTypedList(length);
    data.setRange(0, length, sourceData);
    return data;
  }

  /// Allocate memory for a byte array
  static Pointer<Uint8> allocateBytes(int size) {
    if (size <= 0) {
      throw ArgumentError('Size must be positive, got: $size');
    }
    return calloc<Uint8>(size);
  }

  /// Safely free allocated memory
  static void freePointer(Pointer? ptr) {
    if (ptr != null && ptr != nullptr) {
      calloc.free(ptr);
    }
  }
}
