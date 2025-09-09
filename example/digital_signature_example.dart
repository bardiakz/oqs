import 'package:oqs/oqs.dart';
import 'dart:convert';

void main() {
  // Initialize the library (optional, but recommended for performance)
  LibOQS.init();

  // Create signature instance
  final sig = Signature.create('ML-DSA-65');

  try {
    // Generate a key pair
    final keyPair = sig.generateKeyPair();

    // Message to sign
    final message = utf8.encode('Hello, post-quantum world!');

    // Sign the message
    final signature = sig.sign(message, keyPair.secretKey);
    print('Signature length: ${signature.length}');

    // Verify the signature
    final isValid = sig.verify(message, signature, keyPair.publicKey);
    print('Signature valid: $isValid');
  } finally {
    // Clean up signature instance
    sig.dispose();
  }
}
