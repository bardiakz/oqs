import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'package:oqs/src/bindings/liboqs_bindings.dart';
import 'package:oqs/src/oqs_base.dart';

/// Safe random number generation using liboqs
class OQSRandom {
  static const int _maxRandomSize = 1024 * 1024; // 1MB max

  /// Generate cryptographically secure random bytes
  ///
  /// Uses the current liboqs random number generator (default: system RNG)
  ///
  /// @param length Number of random bytes to generate (1 to 1MB)
  /// @return Uint8List containing the random bytes
  /// @throws LibOQSException if generation fails
  /// @throws ArgumentError if length is invalid
  static Uint8List generateBytes(int length) {
    if (length <= 0) {
      throw ArgumentError('Length must be positive, got: $length');
    }

    if (length > _maxRandomSize) {
      throw ArgumentError(
        'Length too large: $length bytes (max: $_maxRandomSize)',
      );
    }

    LibOQSBase.init();

    Pointer<Uint8>? randomPtr;
    try {
      randomPtr = LibOQSUtils.allocateBytes(length);
      LibOQSBase.bindings.OQS_randombytes(randomPtr, length);
      return LibOQSUtils.pointerToUint8List(randomPtr, length);
    } catch (e) {
      throw LibOQSException('Failed to generate random bytes: $e');
    } finally {
      LibOQSUtils.freePointer(randomPtr);
    }
  }

  /// Generate a random seed suitable for key derivation
  ///
  /// @param seedLength Length of seed in bytes (default: 32)
  /// @return Random seed as Uint8List
  static Uint8List generateSeed([int seedLength = 32]) {
    if (seedLength < 16 || seedLength > 64) {
      throw ArgumentError('Seed length should be between 16 and 64 bytes');
    }
    return generateBytes(seedLength);
  }

  /// Generate random integers in a range
  ///
  /// @param min Minimum value (inclusive)
  /// @param max Maximum value (exclusive)
  /// @return Random integer in range [min, max)
  static int generateInt(int min, int max) {
    if (min >= max) throw ArgumentError('min must be less than max');
    final range = max - min;
    final bytesNeeded = (range.bitLength + 7) ~/ 8;
    final cap = 1 << (bytesNeeded * 8);
    final unbiasedCap = cap - (cap % range);
    while (true) {
      final bytes = generateBytes(bytesNeeded);
      int value = 0;
      for (int i = 0; i < bytesNeeded; i++) {
        value = (value << 8) | bytes[i];
      }
      if (value < unbiasedCap) return min + (value % range);
    }
  }

  /// Switch to a different random number generator algorithm
  ///
  /// WARNING: Only use this if you understand the security implications
  ///
  /// @param algorithm Algorithm name (e.g., "system", "OpenSSL")
  /// @return true if switch was successful
  static bool switchAlgorithm(String algorithm) {
    if (algorithm.isEmpty) {
      throw ArgumentError('Algorithm name cannot be empty');
    }

    LibOQSBase.init();

    final algorithmPtr = algorithm.toNativeUtf8();
    try {
      final result = LibOQSBase.bindings.OQS_randombytes_switch_algorithm(
        algorithmPtr.cast(),
      );
      return result == OQS_STATUS.OQS_SUCCESS;
    } finally {
      LibOQSUtils.freePointer(algorithmPtr);
    }
  }

  /// Get list of available RNG algorithms
  ///
  /// Note: This is a hardcoded list of commonly available algorithms
  /// Actual availability may vary by platform and liboqs build
  static List<String> getAvailableAlgorithms() {
    return [
      'system', // Default system RNG
      'OpenSSL', // OpenSSL RAND_bytes
      'NIST-KAT', // For testing (deterministic)
    ];
  }

  /// Check if a specific RNG algorithm is likely supported
  static bool isAlgorithmLikelySupported(String algorithm) {
    return getAvailableAlgorithms().contains(algorithm);
  }

  /// Reset to default (system) random number generator
  static bool resetToDefault() {
    return switchAlgorithm('system');
  }
}

/// Extension methods for random operations
extension OQSRandomExtensions on OQSRandom {
  /// Generate a random boolean
  static bool generateBool() {
    return OQSRandom.generateBytes(1)[0] > 127;
  }

  /// Generate random double between 0.0 and 1.0
  static double generateDouble() {
    final bytes = OQSRandom.generateBytes(8);
    // Assemble as two unsigned 32-bit halves to avoid signed 64-bit overflow
    int hi = 0, lo = 0;
    for (int i = 0; i < 4; i++) {
      hi = (hi << 8) | bytes[i];
    }
    for (int i = 4; i < 8; i++) {
      lo = (lo << 8) | bytes[i];
    }
    // Use 53 bits (IEEE 754 mantissa) for uniform distribution
    final value = (hi & 0x1FFFFF) * 4294967296.0 + lo;
    return value / 9007199254740992.0; // 2^53
  }

  /// Shuffle a list in place using cryptographically secure randomness
  static void shuffleList<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = OQSRandom.generateInt(0, i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}
