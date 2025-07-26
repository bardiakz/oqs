import 'dart:convert';
import 'dart:typed_data';
import 'package:oqs/oqs.dart';
import 'package:oqs/src/kem.dart';

void main() {
  print('=== LibOQS Dart Example ===\n');

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

    // KEM Example
    kemExample();

    print('\n' + '=' * 50 + '\n');

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
  // final kemAlgorithms = ['Kyber512', 'Kyber768', 'Kyber1024'];
  final kemAlgorithms = KEM.getSupportedAlgorithms();
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
  // final sigAlgorithms = ['Dilithium2', 'Dilithium3', 'Falcon-512'];
  final sigAlgorithms = Signature.getSupportedAlgorithms();
  for (final algName in sigAlgorithms) {
    if (!LibOQS.isSignatureSupported(algName)) {
      print('$algName is not supported, skipping...');
      continue;
    }

    print('\nTesting $algName:');

    final sig = Signature.create(algName);
    if (sig == null) {
      print('Failed to create Signature instance for $algName');
      continue;
    }

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
