import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'bindings/liboqs_bindings.dart';
import 'platform/library_loader.dart';

/// Base class for liboqs functionality
class LibOQSBase {
  static final DynamicLibrary _lib = LibOQSLoader.loadLibrary(useCache: false);
  static final LibOQSBindings _bindings = LibOQSBindings(_lib);

  /// Get the liboqs bindings instance
  static LibOQSBindings get bindings => _bindings;

  /// Initialize liboqs (call this before using any other functions)
  static void init() {}

  /// Clean up liboqs resources
  static void cleanup() {}

  static String getVersion() {
    final versionPtr = bindings.OQS_version();
    final versionString = versionPtr.cast<Utf8>().toDartString();
    return versionString;
  }
}

/// Exception thrown when liboqs operations fail
class LibOQSException implements Exception {
  final String message;
  final int? errorCode;

  const LibOQSException(this.message, [this.errorCode]);

  @override
  String toString() =>
      'LibOQSException: $message${errorCode != null ? ' (code: $errorCode)' : ''}';
}

/// Utility functions for working with C memory and Dart
class LibOQSUtils {
  /// Convert a Dart Uint8List to a C pointer
  static Pointer<Uint8> uint8ListToPointer(Uint8List data) {
    final ptr = calloc<Uint8>(data.length);
    final nativeData = ptr.asTypedList(data.length);
    nativeData.setAll(0, data);
    return ptr;
  }

  /// Convert a C pointer to a Dart Uint8List
  static Uint8List pointerToUint8List(Pointer<Uint8> ptr, int length) {
    return Uint8List.fromList(ptr.asTypedList(length));
  }

  /// Allocate memory for a byte array
  static Pointer<Uint8> allocateBytes(int size) {
    return calloc<Uint8>(size);
  }

  /// Free allocated memory
  static void freePointer(Pointer ptr) {
    calloc.free(ptr);
  }
}
