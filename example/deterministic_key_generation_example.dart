import 'package:oqs/oqs.dart';

void main() {
  final kem = KEM.create('ML-KEM-768');
  if (kem == null) return;

  try {
    // Check if deterministic generation is supported
    if (kem.supportsDeterministicGeneration) {
      // Generate a seed (must be exactly kem.seedLength bytes)
      final seed = OQSRandom.generateSeed(kem.seedLength!);

      // Generate deterministic key pair
      final keyPair = kem.generateKeyPairDerand(seed);
      print('Generated deterministic key pair');

      // Same seed always produces same keys
      final keyPair2 = kem.generateKeyPairDerand(seed);
      print(
        'Same seed produces identical keys: ${(keyPair.publicKey, keyPair2.publicKey)}',
      );
    }
  } finally {
    kem.dispose();
  }
}
