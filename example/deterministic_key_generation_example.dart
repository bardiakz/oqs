import 'dart:typed_data';
import 'package:oqs/oqs.dart';

void main() {
  final kem = KEM.create('ML-KEM-768');
  if (kem == null) return;

  try {
    // Check if deterministic generation is supported
    if (kem.supportsDeterministicGeneration) {
      // Generate a seed (must be exactly kem.seedLength bytes)
      final seed = OQSRandom.generateSeed(kem.seedLength!);

      try {
        // Generate deterministic key pair
        final keyPair = kem.generateKeyPairDerand(seed);
        try {
          print('Generated deterministic key pair');

          // Same seed always produces same keys
          final keyPair2 = kem.generateKeyPairDerand(seed);
          try {
            print(
              'Same seed produces identical keys: ${_listsEqual(keyPair.publicKey, keyPair2.publicKey)}',
            );
          } finally {
            keyPair2.dispose();
          }
        } finally {
          keyPair.dispose();
        }
      } finally {
        // Best practice: Wipe seed from memory
        seed.fillRange(0, seed.length, 0);
      }
    }
  } finally {
    kem.dispose();
  }
}

bool _listsEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
