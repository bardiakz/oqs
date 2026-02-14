import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:oqs/oqs.dart';

void main() {
  KEM? createFirstSupported(List<String> candidates) {
    for (final algorithm in candidates) {
      if (KEM.isSupported(algorithm)) {
        return KEM.create(algorithm);
      }
    }
    return null;
  }

  KEM? createDeterministicKem() {
    final preferred = ['ML-KEM-768', 'ML-KEM-512', 'ML-KEM-1024'];
    final kem = createFirstSupported(preferred);
    if (kem != null && kem.supportsDeterministicGeneration) {
      return kem;
    }
    kem?.dispose();

    for (final algorithm in LibOQS.getSupportedKEMAlgorithms()) {
      final candidate = KEM.create(algorithm)!;
      if (candidate.supportsDeterministicGeneration) {
        return candidate;
      }
      candidate.dispose();
    }

    return null;
  }

  group('KEM Deterministic Key Generation', () {
    setUpAll(() {
      LibOQS.init();
    });

    tearDownAll(() {
      LibOQS.cleanup();
    });

    test('reports deterministic support metadata correctly', () {
      final kem = createFirstSupported(['ML-KEM-768', 'ML-KEM-512']);
      if (kem == null) {
        return;
      }

      if (kem.supportsDeterministicGeneration) {
        expect(kem.seedLength, isNotNull);
        expect(kem.seedLength!, greaterThan(0));
      } else {
        expect(kem.seedLength == null || kem.seedLength == 0, isTrue);
      }

      kem.dispose();
    });

    test('same seed produces identical keys', () {
      final kem = createDeterministicKem();
      if (kem == null) {
        return;
      }

      final seed = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => i % 256),
      );
      final keyPair1 = kem.generateKeyPairDerand(seed);
      final keyPair2 = kem.generateKeyPairDerand(seed);

      expect(keyPair1.publicKey, equals(keyPair2.publicKey));
      expect(keyPair1.secretKey, equals(keyPair2.secretKey));

      kem.dispose();
    });

    test('different seeds produce different keys', () {
      final kem = createDeterministicKem();
      if (kem == null) {
        return;
      }

      final seed1 = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => i % 256),
      );
      final seed2 = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => (i + 17) % 256),
      );

      final keyPair1 = kem.generateKeyPairDerand(seed1);
      final keyPair2 = kem.generateKeyPairDerand(seed2);

      expect(keyPair1.publicKey, isNot(equals(keyPair2.publicKey)));
      expect(keyPair1.secretKey, isNot(equals(keyPair2.secretKey)));

      kem.dispose();
    });

    test('invalid seed length throws', () {
      final kem = createDeterministicKem();
      if (kem == null) {
        return;
      }

      expect(
        () => kem.generateKeyPairDerand(Uint8List(1)),
        throwsA(isA<LibOQSException>()),
      );

      kem.dispose();
    });

    test('deterministic keys are valid for encapsulation/decapsulation', () {
      final kem = createDeterministicKem();
      if (kem == null) {
        return;
      }

      final seed = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => (i * 7 + 13) % 256),
      );
      final keyPair = kem.generateKeyPairDerand(seed);

      final encapsulated = kem.encapsulate(keyPair.publicKey);
      final decapsulated = kem.decapsulate(
        encapsulated.ciphertext,
        keyPair.secretKey,
      );

      expect(decapsulated, equals(encapsulated.sharedSecret));
      kem.dispose();
    });
  });
}
