import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'package:oqs/src/bindings/liboqs_bindings.dart';
import 'package:oqs/src/platform/library_loader.dart';

/// Thread-safe base class for liboqs functionality
class LibOQSBase {
  static DynamicLibrary? _lib;
  static LibOQSBindings? _bindings;
  static bool _initialized = false;
  static final Map<int, bool> _threadInitialized = {};

  /// Get the library instance with validation
  static DynamicLibrary get lib {
    if (_lib == null) {
      try {
        _lib = LibOQSLoader.loadLibrary(useCache: true);
      } catch (e) {
        throw LibOQSException('Failed to load LibOQS library: $e');
      }
    }
    return _lib!;
  }

  /// Get the liboqs bindings instance with validation
  static LibOQSBindings get bindings {
    if (_bindings == null) {
      try {
        _bindings = LibOQSBindings(lib);
      } catch (e) {
        throw LibOQSException('Failed to create LibOQS bindings: $e');
      }
    }
    return _bindings!;
  }

  /// Safe initialization with comprehensive error handling
  static void init() {
    if (_initialized) return;

    try {
      // Validate library is loaded
      final testPtr = bindings.OQS_version();
      if (testPtr == nullptr) {
        throw LibOQSException('LibOQS library appears to be invalid');
      }

      // Initialize the library
      bindings.OQS_init();
      _initialized = true;

      // Mark current thread as initialized
      final threadId = Isolate.current.hashCode;
      _threadInitialized[threadId] = true;
    } catch (e) {
      _initialized = false;
      throw LibOQSException('Failed to initialize LibOQS: $e');
    }
  }

  /// Safe cleanup with error handling
  static void cleanup() {
    if (!_initialized) return;

    try {
      // Clean up current thread first
      cleanupThread();

      // Then destroy the library
      bindings.OQS_destroy();
    } catch (e) {
      print('Warning: Error during LibOQS cleanup: $e');
    } finally {
      _initialized = false;
      _threadInitialized.clear();
    }
  }

  /// Clean up thread-specific resources
  static void cleanupThread() {
    final threadId = Isolate.current.hashCode;
    if (_threadInitialized[threadId] == true) {
      try {
        bindings.OQS_thread_stop();
        _threadInitialized[threadId] = false;
      } catch (e) {
        print('Warning: Error during thread cleanup: $e');
      }
    }
  }

  /// Get version with comprehensive error handling
  static String getVersion() {
    init(); // Auto-initialize if needed

    try {
      final versionPtr = bindings.OQS_version();
      if (versionPtr == nullptr) {
        throw LibOQSException('Failed to get LibOQS version pointer');
      }

      // Validate the pointer before dereferencing
      final version = versionPtr.cast<Utf8>().toDartString();
      if (version.isEmpty) {
        throw LibOQSException('LibOQS version string is empty');
      }

      return version;
    } catch (e) {
      throw LibOQSException('Error getting LibOQS version: $e');
    }
  }

  /// Check if library is properly initialized
  static bool get isInitialized => _initialized;
}

/// Enhanced exception class with more context
class LibOQSException implements Exception {
  final String message;
  final int? errorCode;
  final String? algorithmName;
  final StackTrace? stackTrace;

  LibOQSException(this.message, [this.errorCode, this.algorithmName])
    : stackTrace = StackTrace.current;

  @override
  String toString() {
    final parts = <String>['LibOQSException'];
    if (errorCode != null) parts.add('(code: $errorCode)');
    if (algorithmName != null) parts.add('[alg: $algorithmName]');
    parts.add(': $message');
    return parts.join('');
  }
}

/// Memory-safe utility class with extensive validation
class LibOQSUtils {
  /// Maximum allowed allocation size (100MB)
  static const int _maxAllocationSize = 100 * 1024 * 1024;

  /// Convert Uint8List to pointer with safety checks
  static Pointer<Uint8> uint8ListToPointer(Uint8List data) {
    if (data.isEmpty) {
      throw ArgumentError('Data cannot be empty');
    }

    if (data.length > _maxAllocationSize) {
      throw LibOQSException(
        'Data too large: ${data.length} bytes (max: $_maxAllocationSize)',
      );
    }

    Pointer<Uint8>? ptr;
    try {
      ptr = calloc<Uint8>(data.length);
      if (ptr == nullptr) {
        throw LibOQSException('Failed to allocate ${data.length} bytes');
      }

      // Validate the pointer before using it
      final nativeData = ptr.asTypedList(data.length);
      nativeData.setAll(0, data);

      return ptr;
    } catch (e) {
      if (ptr != null && ptr != nullptr) {
        try {
          calloc.free(ptr);
        } catch (_) {}
      }
      throw LibOQSException('Error converting Uint8List to pointer: $e');
    }
  }

  /// Convert pointer to Uint8List with extensive validation
  static Uint8List pointerToUint8List(Pointer<Uint8> ptr, int length) {
    if (ptr == nullptr) {
      throw LibOQSException('Cannot convert null pointer to Uint8List');
    }

    if (length <= 0) {
      return Uint8List(0);
    }

    if (length > _maxAllocationSize) {
      throw LibOQSException(
        'Length too large: $length bytes (max: $_maxAllocationSize)',
      );
    }

    try {
      // Create new list and copy data safely
      final data = Uint8List(length);
      final sourceData = ptr.asTypedList(length);

      // Copy in chunks to detect memory access issues early
      const chunkSize = 4096;
      for (int i = 0; i < length; i += chunkSize) {
        final end = (i + chunkSize < length) ? i + chunkSize : length;
        data.setRange(i, end, sourceData.sublist(i, end));
      }

      return data;
    } catch (e) {
      throw LibOQSException(
        'Error copying data from pointer (length: $length): $e',
      );
    }
  }

  /// Allocate memory with safety checks
  static Pointer<Uint8> allocateBytes(int size) {
    if (size <= 0) {
      throw ArgumentError('Size must be positive, got: $size');
    }

    if (size > _maxAllocationSize) {
      throw LibOQSException(
        'Allocation too large: $size bytes (max: $_maxAllocationSize)',
      );
    }

    try {
      final ptr = calloc<Uint8>(size);
      if (ptr == nullptr) {
        throw LibOQSException('Failed to allocate $size bytes - out of memory');
      }

      // Initialize memory to zero for safety
      final data = ptr.asTypedList(size);
      data.fillRange(0, size, 0);

      return ptr;
    } catch (e) {
      throw LibOQSException('Error allocating $size bytes: $e');
    }
  }

  /// Safe pointer deallocation
  static void freePointer(Pointer? ptr) {
    if (ptr == null || ptr == nullptr) return;

    try {
      calloc.free(ptr);
    } catch (e) {
      print('Warning: Error freeing pointer: $e');
    }
  }

  /// Validate algorithm name
  static void validateAlgorithmName(String name) {
    if (name.isEmpty) {
      throw ArgumentError('Algorithm name cannot be empty');
    }

    if (name.length > 256) {
      throw ArgumentError('Algorithm name too long: ${name.length} characters');
    }

    // Check for basic validity
    if (!RegExp(r'^[a-zA-Z0-9\-\+_]+$').hasMatch(name)) {
      throw ArgumentError('Algorithm name contains invalid characters: $name');
    }
  }
}

/// Safe signature implementation with crash protection
class SafeSignature {
  final Pointer<OQS_SIG> _sigPtr;
  final String algorithmName;
  bool _disposed = false;

  SafeSignature._(this._sigPtr, this.algorithmName);

  /// Create signature instance with comprehensive safety checks
  static SafeSignature? create(String algorithmName) {
    try {
      LibOQSUtils.validateAlgorithmName(algorithmName);
      LibOQSBase.init();

      final namePtr = algorithmName.toNativeUtf8();
      try {
        final sigPtr = LibOQSBase.bindings.OQS_SIG_new(namePtr.cast());
        if (sigPtr == nullptr) {
          return null; // Algorithm not supported
        }

        // Validate the created signature structure
        final sig = sigPtr.cast<OQS_SIG>();
        final ref = sig.ref;

        // Basic validation of the structure
        if (ref.length_public_key <= 0 ||
            ref.length_public_key > LibOQSUtils._maxAllocationSize ||
            ref.length_secret_key <= 0 ||
            ref.length_secret_key > LibOQSUtils._maxAllocationSize ||
            ref.length_signature <= 0 ||
            ref.length_signature > LibOQSUtils._maxAllocationSize) {
          LibOQSBase.bindings.OQS_SIG_free(sig);
          throw LibOQSException(
            'Invalid signature parameters for $algorithmName',
          );
        }

        return SafeSignature._(sig, algorithmName);
      } finally {
        LibOQSUtils.freePointer(namePtr);
      }
    } catch (e) {
      throw LibOQSException(
        'Failed to create signature for $algorithmName: $e',
      );
    }
  }

  /// Check if algorithm is supported safely
  static bool isSupported(String algorithmName) {
    try {
      LibOQSUtils.validateAlgorithmName(algorithmName);
      LibOQSBase.init();

      final namePtr = algorithmName.toNativeUtf8();
      try {
        return LibOQSBase.bindings.OQS_SIG_alg_is_enabled(namePtr.cast()) == 1;
      } finally {
        LibOQSUtils.freePointer(namePtr);
      }
    } catch (e) {
      print('Warning: Error checking algorithm support for $algorithmName: $e');
      return false;
    }
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('Signature instance has been disposed');
    }
  }

  int get publicKeyLength {
    _checkDisposed();
    return _sigPtr.ref.length_public_key;
  }

  int get secretKeyLength {
    _checkDisposed();
    return _sigPtr.ref.length_secret_key;
  }

  int get maxSignatureLength {
    _checkDisposed();
    return _sigPtr.ref.length_signature;
  }

  /// Generate key pair with extensive error handling
  Map<String, Uint8List>? generateKeyPair() {
    _checkDisposed();

    Pointer<Uint8>? publicKey;
    Pointer<Uint8>? secretKey;

    try {
      publicKey = LibOQSUtils.allocateBytes(publicKeyLength);
      secretKey = LibOQSUtils.allocateBytes(secretKeyLength);

      final keypairFn = _sigPtr.ref.keypair
          .asFunction<
            int Function(Pointer<Uint8> publicKey, Pointer<Uint8> secretKey)
          >();

      final result = keypairFn(publicKey, secretKey);
      if (result != 0) {
        return null; // Failed to generate
      }

      return {
        'publicKey': LibOQSUtils.pointerToUint8List(publicKey, publicKeyLength),
        'secretKey': LibOQSUtils.pointerToUint8List(secretKey, secretKeyLength),
      };
    } catch (e) {
      print('Error generating key pair for $algorithmName: $e');
      return null;
    } finally {
      LibOQSUtils.freePointer(publicKey);
      LibOQSUtils.freePointer(secretKey);
    }
  }

  /// Safe disposal
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      try {
        LibOQSBase.bindings.OQS_SIG_free(_sigPtr);
      } catch (e) {
        print('Warning: Error disposing signature: $e');
      }
    }
  }
}
