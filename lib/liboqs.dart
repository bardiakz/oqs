library;

import 'liboqs.dart';
export 'src/liboqs_base.dart';
export 'src/kem.dart';
export 'src/signature.dart';

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
    return KEM.getSupportedAlgorithms();
  }

  /// Get all supported signature algorithms
  static List<String> getSupportedSignatureAlgorithms() {
    return Signature.getSupportedAlgorithms();
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
