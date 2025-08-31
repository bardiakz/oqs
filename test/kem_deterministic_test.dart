import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:oqs/oqs.dart';

void main() {
  group('KEM Deterministic Key Generation', () {
    setUpAll(() {
      LibOQS.init();
    });

    tearDownAll(() {
      LibOQS.cleanup();
    });

    test('ML-KEM-768 supports deterministic generation', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);
      expect(kem!.supportsDeterministicGeneration, isTrue);
      expect(kem.seedLength, isNotNull);
      expect(kem.seedLength, greaterThan(0));
      kem.dispose();
    });

    test('Same seed produces identical keys', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);
      if (!kem!.supportsDeterministicGeneration) {
        kem.dispose();
        return; // Skip if not supported
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

    test('Different seeds produce different keys', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);
      if (!kem!.supportsDeterministicGeneration) {
        kem.dispose();
        return; // Skip if not supported
      }

      final seed1 = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => i % 256),
      );
      final seed2 = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => (i + 1) % 256),
      );

      final keyPair1 = kem.generateKeyPairDerand(seed1);
      final keyPair2 = kem.generateKeyPairDerand(seed2);

      expect(keyPair1.publicKey, isNot(equals(keyPair2.publicKey)));
      expect(keyPair1.secretKey, isNot(equals(keyPair2.secretKey)));

      kem.dispose();
    });

    test('Invalid seed length throws exception', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);
      if (!kem!.supportsDeterministicGeneration) {
        kem.dispose();
        return; // Skip if not supported
      }

      final invalidSeed = Uint8List(10); // Wrong size

      expect(
        () => kem.generateKeyPairDerand(invalidSeed),
        throwsA(isA<LibOQSException>()),
      );

      kem.dispose();
    });

    test('Deterministic keys work for encryption/decryption', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);
      if (!kem!.supportsDeterministicGeneration) {
        kem.dispose();
        return; // Skip if not supported
      }

      final seed = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => (i * 7 + 13) % 256),
      );

      final keyPair = kem.generateKeyPairDerand(seed);

      // Test encapsulation/decapsulation
      final encResult = kem.encapsulate(keyPair.publicKey);
      final sharedSecret = kem.decapsulate(
        encResult.ciphertext,
        keyPair.secretKey,
      );

      expect(sharedSecret, equals(encResult.sharedSecret));

      kem.dispose();
    });

    test('Kyber768 supports deterministic generation', () {
      final kem = KEM.create('Kyber768');
      if (kem == null) {
        return; // Skip if not available
      }

      expect(kem.supportsDeterministicGeneration, isTrue);
      expect(kem.seedLength, isNotNull);
      expect(kem.seedLength, greaterThan(0));

      // Test deterministic generation with Kyber
      final seed = Uint8List.fromList(
        List.generate(kem.seedLength!, (i) => (i * 3) % 256),
      );

      final keyPair1 = kem.generateKeyPairDerand(seed);
      final keyPair2 = kem.generateKeyPairDerand(seed);

      expect(keyPair1.publicKey, equals(keyPair2.publicKey));
      expect(keyPair1.secretKey, equals(keyPair2.secretKey));

      kem.dispose();
    });

    test('Unsupported algorithm throws exception', () {
      final kem = KEM.create('FrodoKEM-640-AES');
      if (kem == null) {
        return; // Skip if not available
      }

      // FrodoKEM typically doesn't support deterministic generation
      if (kem.supportsDeterministicGeneration) {
        // If it does support it, test it normally
        final seed = Uint8List.fromList(
          List.generate(kem.seedLength!, (i) => i % 256),
        );

        final keyPair = kem.generateKeyPairDerand(seed);
        expect(keyPair, isNotNull);
      } else {
        // Test that it properly throws when not supported
        final dummySeed = Uint8List(32);
        expect(
          () => kem.generateKeyPairDerand(dummySeed),
          throwsA(
            isA<LibOQSException>().having(
              (e) => e.message,
              'message',
              contains('does not support deterministic key generation'),
            ),
          ),
        );
      }

      kem.dispose();
    });

    test('Multiple algorithms support check', () {
      final algorithms = [
        'ML-KEM-512',
        'ML-KEM-768',
        'ML-KEM-1024',
        'Kyber512',
        'Kyber768',
        'Kyber1024',
      ];

      for (final algName in algorithms) {
        final kem = KEM.create(algName);
        if (kem != null) {
          // Just verify that we can check support without errors
          final supported = kem.supportsDeterministicGeneration;
          final seedLen = kem.seedLength;
          expect(supported, isA<bool>());
          if (supported) {
            expect(seedLen, isNotNull);
            expect(seedLen, greaterThan(0));
          }
          kem.dispose();
        }
      }
    });
  });
}
