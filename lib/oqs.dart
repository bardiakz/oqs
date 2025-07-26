library;

import 'package:oqs/src/liboqs_base.dart';

import 'oqs.dart';
export 'src/kem.dart';
export 'src/signature.dart' show Signature;
export 'src/platform/library_loader.dart'
    show LibOQSLoader, LibraryLoadException;
export 'src/liboqs_base.dart' show LibOQSException;

// Export data classes
export 'src/kem.dart' show KEMKeyPair, KEMEncapsulationResult;

/// Main LibOQS class for initialization and global operations
class LibOQS {
  /// Initialize the liboqs library
  /// Call this before using any other functions
  static void init() {
    LibOQSBase.init();
  }

  /// Clean up liboqs resources
  /// Call this when you're done using the library
  static void cleanup() {
    LibOQSBase.cleanup();
  }

  /// Get the version of liboqs
  static String getVersion() {
    return LibOQSBase.getVersion();
  }

  /// Get all supported KEM algorithms
  static List<String> getSupportedKEMAlgorithms() {
    return KEM.getSupportedKemAlgorithmsHardCodedList();
  }

  /// Get all supported signature algorithms
  static List<String> getSupportedSignatureAlgorithms() {
    return Signature.getSupportedSignatureAlgorithmsHardCodedList();
  }

  /// Check if a KEM algorithm is supported
  static bool isKEMSupported(String algorithmName) {
    return KEM.isSupported(algorithmName);
  }

  /// Check if a signature algorithm is supported
  static bool isSignatureSupported(String algorithmName) {
    return Signature.isSupported(algorithmName);
  }
}
