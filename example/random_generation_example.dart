/// The `OQSRandom` class provides cryptographically secure random number
/// generation using liboqs's RNG implementation.
library;

import 'package:oqs/oqs.dart';

void randomExamples() {
  // Generate random bytes
  final bytes = OQSRandom.generateBytes(16);
  print('16 random bytes: $bytes');

  // Generate cryptographic seed (default 32 bytes)
  final seed = OQSRandom.generateSeed();
  print('32-byte seed: ${seed.length} bytes');

  // Generate custom seed length
  final customSeed = OQSRandom.generateSeed(64);
  print('64-byte seed: ${customSeed.length} bytes');

  // Generate random integer in range
  final randomInt = OQSRandom.generateInt(10, 100);
  print('Random int (10-99): $randomInt');
}

void extendedRandomExamples() {
  // Random boolean
  final bool randomBool = OQSRandomExtensions.generateBool();
  print('Random boolean: $randomBool');

  // Random double (0.0 to 1.0)
  final double randomDouble = OQSRandomExtensions.generateDouble();
  print('Random double: $randomDouble');

  // Cryptographically secure list shuffling
  final List<String> items = ['A', 'B', 'C', 'D', 'E'];
  print('Original: $items');
  OQSRandomExtensions.shuffleList(items);
  print('Shuffled: $items');
}

void advancedRandomExamples() {
  // List available RNG algorithms
  final algorithms = OQSRandom.getAvailableAlgorithms();
  print('Available RNG algorithms: $algorithms');

  // Check if algorithm is supported
  final isSupported = OQSRandom.isAlgorithmLikelySupported('system');
  print('System RNG supported: $isSupported');

  // Switch RNG algorithm (use with caution)
  final success = OQSRandom.switchAlgorithm('system');
  print('Switched to system RNG: $success');

  // Reset to default
  OQSRandom.resetToDefault();
  print('Reset to default RNG');
}

void cryptographicRandomExamples() {
  // Generate random salt for key derivation
  final salt = OQSRandom.generateBytes(16);
  print('Salt for key derivation: ${salt.length} bytes');

  // Generate random IV for encryption
  final iv = OQSRandom.generateBytes(12); // Typical AES-GCM IV size
  print('IV for encryption: ${iv.length} bytes');

  // Generate random session ID
  final sessionId = OQSRandom.generateBytes(32);
  print('Session ID: ${sessionId.length} bytes');

  // Generate random nonce for protocols
  final nonce = OQSRandom.generateBytes(24);
  print('Protocol nonce: ${nonce.length} bytes');
}
