library;

import 'dart:typed_data';

import 'package:oqs/src/kem.dart';
import 'package:oqs/src/oqs_base.dart';
import 'package:oqs/src/signature.dart';

export 'src/kem.dart';
export 'src/oqs_base.dart' show LibOQSException, LibOQSUtils;
export 'src/platform/library_loader.dart'
    show LibOQSLoader, LibraryLoadException, LibraryPaths;
export 'src/random.dart' show OQSRandom, OQSRandomExtensions;
export 'src/signature.dart' show Signature;

/// Main LibOQS class for initialization and global operations
class LibOQS {
  // static bool _initialized = false;

  /// Initialize the liboqs library
  /// Call this before using any other functions
  /// This is optional but recommended for better performance
  static void init() {
    LibOQSBase.init();
  }

  /// Ensure initialization before first use
  // static void _ensureInitialized() {
  //   if (!_initialized) {
  //     init();
  //   }
  // }

  /// Clean up liboqs resources
  /// Call this when you're done using the library
  /// This function frees prefetched OpenSSL objects
  ///
  /// Dispose all [KEM] and [Signature] instances before calling this —
  /// their GC finalizers would otherwise call into a destroyed library.
  static void cleanup() {
    LibOQSBase.cleanup();
    // _initialized = false;
  }

  /// Get the version of liboqs
  static String getVersion() {
    return LibOQSBase.getVersion();
  }

  /// Get all supported KEM algorithms
  static List<String> getSupportedKEMAlgorithms() {
    return KEM.getSupportedKemAlgorithms();
  }

  /// Get all supported signature algorithms
  static List<String> getSupportedSignatureAlgorithms() {
    return Signature.getSupportedSignatureAlgorithms();
  }

  /// Check if a KEM algorithm is supported
  static bool isKEMSupported(String algorithmName) {
    return KEM.isSupported(algorithmName);
  }

  /// Check if a signature algorithm is supported
  static bool isSignatureSupported(String algorithmName) {
    return Signature.isSupported(algorithmName);
  }

  /// Constant-time comparison of two byte arrays to prevent timing side-channel attacks.
  ///
  /// Returns `true` if [a] and [b] have identical lengths and contents, `false` otherwise.
  static bool secureCompare(Uint8List a, Uint8List b) {
    return LibOQSUtils.secureCompare(a, b);
  }
}
