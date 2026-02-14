import 'dart:convert';
import 'dart:typed_data';
import 'package:oqs/oqs.dart';

void main() {
  print('=== LibOQS Dart Example ===\n');

  // Configure platform-specific path before initialization.
  LibOQSLoader.customPaths = const LibraryPaths(linux: 'bin/linux/liboqs.so');

  // Initialize the library
  LibOQS.init();

  try {
    // Print supported algorithms
    KEM.printSupportedKemAlgorithms();
    Signature.printSupportedSignatureAlgorithms();
    // Print library information
    print('LibOQS Version: ${LibOQS.getVersion()}');
    print(
      'Supported KEM algorithms: ${LibOQS.getSupportedKEMAlgorithms().length}',
    );
    print(
      'Supported Signature algorithms: ${LibOQS.getSupportedSignatureAlgorithms().length}\n',
    );
    //random example
    randomExample();

    // KEM Example
    kemExample();

    print('\n${'=' * 50}\n');

    // Signature Example
    signatureExample();
  } catch (e) {
    print('Error: $e');
  } finally {
    // Clean up
    LibOQS.cleanup();
  }
}

void kemExample() {
  print('=== KEM (Key Encapsulation Mechanism) Example ===');

  // Try different KEM algorithms
  final kemAlgorithms = ['ML-KEM-512', 'ML-KEM-768', 'ML-KEM-1024'];
  for (final algName in kemAlgorithms) {
    if (!LibOQS.isKEMSupported(algName)) {
      print('$algName is not supported, skipping...');
      continue;
    }

    print('\nTesting $algName:');

    final kem = KEM.create(algName);
    if (kem == null) {
      print('Failed to create KEM instance for $algName');
      continue;
    }

    try {
      // Print algorithm details
      print('  Public key length: ${kem.publicKeyLength} bytes');
      print('  Secret key length: ${kem.secretKeyLength} bytes');
      print('  Ciphertext length: ${kem.ciphertextLength} bytes');
      print('  Shared secret length: ${kem.sharedSecretLength} bytes');

      // Generate key pair
      final keyPair = kem.generateKeyPair();
      print('  ✓ Generated key pair');

      // Encapsulate
      final encResult = kem.encapsulate(keyPair.publicKey);
      print('  ✓ Encapsulated shared secret');

      // Decapsulate
      final sharedSecret = kem.decapsulate(
        encResult.ciphertext,
        keyPair.secretKey,
      );
      print('  ✓ Decapsulated shared secret');

      // Verify the shared secrets match
      final match = _compareUint8Lists(encResult.sharedSecret, sharedSecret);
      print('  ✓ Shared secrets match: $match');

      if (match) {
        print(
          '  Shared secret (hex): ${_bytesToHex(sharedSecret.take(16).toList())}...',
        );
      }

      // Test deterministic key generation if supported
      if (kem.supportsDeterministicGeneration) {
        print('\n  Testing deterministic generation...');
        print('  Seed length required: ${kem.seedLength} bytes');

        // Generate a seed
        final seed = OQSRandom.generateSeed(kem.seedLength!);
        print('  Generated seed: ${_bytesToHex(seed.take(16).toList())}...');

        // Generate two key pairs with same seed
        final keyPair1 = kem.generateKeyPairDerand(seed);
        final keyPair2 = kem.generateKeyPairDerand(seed);

        // Verify they're identical
        final publicKeysMatch = _compareUint8Lists(
          keyPair1.publicKey,
          keyPair2.publicKey,
        );
        final secretKeysMatch = _compareUint8Lists(
          keyPair1.secretKey,
          keyPair2.secretKey,
        );

        print(
          '  ✓ Deterministic generation: Public keys match: $publicKeysMatch',
        );
        print(
          '  ✓ Deterministic generation: Secret keys match: $secretKeysMatch',
        );

        // Generate with different seed to verify they're different
        final seed2 = OQSRandom.generateSeed(kem.seedLength!);
        final keyPair3 = kem.generateKeyPairDerand(seed2);

        final differentKeys = !_compareUint8Lists(
          keyPair1.publicKey,
          keyPair3.publicKey,
        );
        print('  ✓ Different seeds produce different keys: $differentKeys');
      } else {
        print('  ℹ Deterministic generation not supported for $algName');
      }
    } catch (e) {
      print('  ✗ Error: $e');
    } finally {
      kem.dispose();
    }
  }
}

void signatureExample() {
  print('=== Digital Signature Example ===');

  // Try different signature algorithms
  final sigAlgorithms = ['ML-DSA-44', 'ML-DSA-65', 'Falcon-512'];
  for (final algName in sigAlgorithms) {
    if (!LibOQS.isSignatureSupported(algName)) {
      print('$algName is not supported, skipping...');
      continue;
    }

    print('\nTesting $algName:');

    final sig = Signature.create(algName);

    try {
      // Print algorithm details
      print('  Public key length: ${sig.publicKeyLength} bytes');
      print('  Secret key length: ${sig.secretKeyLength} bytes');
      print('  Max signature length: ${sig.maxSignatureLength} bytes');

      // Generate key pair
      final keyPair = sig.generateKeyPair();
      print('  ✓ Generated key pair');

      // Create a message to sign
      final message = Uint8List.fromList(
        utf8.encode(
          'Hello, Post-Quantum World! This is a test message for $algName.',
        ),
      );

      // Sign the message
      final signature = sig.sign(message, keyPair.secretKey);
      print('  ✓ Signed message (signature length: ${signature.length} bytes)');

      // Verify the signature
      final isValid = sig.verify(message, signature, keyPair.publicKey);
      print('  ✓ Signature verification: $isValid');

      // Test with invalid signature
      final invalidSignature = Uint8List.fromList(
        signature.toList()..shuffle(),
      );
      final isInvalid = sig.verify(
        message,
        invalidSignature,
        keyPair.publicKey,
      );
      print('  ✓ Invalid signature verification: $isInvalid (should be false)');
    } catch (e) {
      print('  ✗ Error: $e');
    } finally {
      sig.dispose();
    }
  }
}

void randomExample() {
  print('=== Random Number Generation Example ===');

  try {
    // Generate random bytes
    print('Generating random bytes...');
    final randomBytes = OQSRandom.generateBytes(32);
    print(
      '  ✓ Generated 32 random bytes: ${_bytesToHex(randomBytes.take(16).toList())}...',
    );

    // Generate a cryptographic seed
    print('\nGenerating cryptographic seed...');
    final seed = OQSRandom.generateSeed(32);
    print('  ✓ Generated seed: ${_bytesToHex(seed.take(16).toList())}...');

    // Generate random integers
    print('\nGenerating random integers...');
    final randomInts = List.generate(5, (_) => OQSRandom.generateInt(1, 100));
    print('  ✓ Random integers (1-99): $randomInts');

    // Generate random boolean values
    print('\nGenerating random booleans...');
    final randomBools = List.generate(
      10,
      (_) => OQSRandomExtensions.generateBool(),
    );
    print('  ✓ Random booleans: $randomBools');

    // Generate random double
    print('\nGenerating random doubles...');
    final randomDoubles = List.generate(
      5,
      (_) => OQSRandomExtensions.generateDouble(),
    );
    print(
      '  ✓ Random doubles (0.0-1.0): ${randomDoubles.map((d) => d.toStringAsFixed(6)).toList()}',
    );

    // Test list shuffling
    print('\nTesting cryptographic shuffle...');
    final testList = List.generate(10, (i) => i);
    print('  Original list: $testList');
    OQSRandomExtensions.shuffleList(testList);
    print('  ✓ Shuffled list: $testList');

    // Show available RNG algorithms
    print('\nAvailable RNG algorithms:');
    final algorithms = OQSRandom.getAvailableAlgorithms();
    for (final alg in algorithms) {
      final supported = OQSRandom.isAlgorithmLikelySupported(alg) ? '✓' : '?';
      print('  $supported $alg');
    }

    // Test algorithm switching (optional, be careful with this)
    print('\nTesting RNG algorithm info...');
    print('  Current algorithm: system (default)');

    // Generate some bytes with default algorithm
    final defaultBytes = OQSRandom.generateBytes(16);
    print(
      '  ✓ Generated with default: ${_bytesToHex(defaultBytes.take(8).toList())}...',
    );
  } catch (e) {
    print('  ✗ Random generation error: $e');
  }
}

// Helper functions
bool _compareUint8Lists(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}
