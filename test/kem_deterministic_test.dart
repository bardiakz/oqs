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

    test('ML-KEM-768 deterministic generation support check', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);

      // Check support but don't assert it's true - ML-KEM may not support deterministic generation
      final supportsDeterm = kem!.supportsDeterministicGeneration;
      final seedLen = kem.seedLength;

      print('ML-KEM-768 deterministic support: $supportsDeterm');
      print('ML-KEM-768 seed length: $seedLen');

      if (supportsDeterm) {
        expect(seedLen, isNotNull);
        expect(seedLen, greaterThan(0));
        print('✅ ML-KEM-768 supports deterministic generation');
      } else {
        print(
          'ℹ️ ML-KEM-768 does not support deterministic generation in this liboqs version',
        );
      }

      kem.dispose();
    });

    test('Same seed produces identical keys (if supported)', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);

      if (!kem!.supportsDeterministicGeneration) {
        print('Skipping deterministic test - not supported by ML-KEM-768');
        kem.dispose();
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

    test('Different seeds produce different keys (if supported)', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);

      if (!kem!.supportsDeterministicGeneration) {
        print('Skipping deterministic test - not supported by ML-KEM-768');
        kem.dispose();
        return;
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

    test('Invalid seed length throws exception (if supported)', () {
      final kem = KEM.create('ML-KEM-768');
      expect(kem, isNotNull);

      if (!kem!.supportsDeterministicGeneration) {
        print('Skipping deterministic test - not supported by ML-KEM-768');
        kem.dispose();
        return;
      }

      final invalidSeed = Uint8List(10); // Wrong size

      expect(
        () => kem.generateKeyPairDerand(invalidSeed),
        throwsA(isA<LibOQSException>()),
      );

      kem.dispose();
    });

    test(
      'Deterministic keys work for encryption/decryption (if supported)',
      () {
        final kem = KEM.create('ML-KEM-768');
        expect(kem, isNotNull);

        if (!kem!.supportsDeterministicGeneration) {
          print('Skipping deterministic test - not supported by ML-KEM-768');
          kem.dispose();
          return;
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
      },
    );

    test('Kyber768 deterministic generation check', () {
      final kem = KEM.create('Kyber768');
      if (kem == null) {
        print('Kyber768 not available - skipping test');
        return;
      }

      // Check if Kyber768 supports deterministic generation
      final supportsDeterm = kem.supportsDeterministicGeneration;
      final seedLen = kem.seedLength;

      print('Kyber768 deterministic support: $supportsDeterm');
      print('Kyber768 seed length: $seedLen');

      if (supportsDeterm) {
        print('✅ Kyber768 supports deterministic generation - testing it');
        expect(seedLen, isNotNull);
        expect(seedLen, greaterThan(0));

        // Test deterministic generation with Kyber
        final seed = Uint8List.fromList(
          List.generate(seedLen!, (i) => (i * 3) % 256),
        );

        final keyPair1 = kem.generateKeyPairDerand(seed);
        final keyPair2 = kem.generateKeyPairDerand(seed);

        expect(keyPair1.publicKey, equals(keyPair2.publicKey));
        expect(keyPair1.secretKey, equals(keyPair2.secretKey));
      } else {
        print(
          'ℹ️ Kyber768 does not support deterministic generation in this liboqs version',
        );
        expect(seedLen, isNull);

        // Test that attempting deterministic generation throws an error
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

    test('Unsupported algorithm behavior', () {
      final kem = KEM.create('FrodoKEM-640-AES');
      if (kem == null) {
        print('FrodoKEM-640-AES not available - skipping test');
        return;
      }

      // FrodoKEM typically doesn't support deterministic generation
      if (kem.supportsDeterministicGeneration) {
        print(
          'FrodoKEM-640-AES supports deterministic generation - testing it',
        );
        final seed = Uint8List.fromList(
          List.generate(kem.seedLength!, (i) => i % 256),
        );

        final keyPair = kem.generateKeyPairDerand(seed);
        expect(keyPair, isNotNull);
      } else {
        print(
          'FrodoKEM-640-AES does not support deterministic generation - testing error handling',
        );
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

      final supportedCount = <String, bool>{};

      for (final algName in algorithms) {
        final kem = KEM.create(algName);
        if (kem != null) {
          final supported = kem.supportsDeterministicGeneration;
          final seedLen = kem.seedLength;
          supportedCount[algName] = supported;

          print('$algName: deterministic=$supported, seedLength=$seedLen');

          expect(supported, isA<bool>());
          if (supported) {
            expect(seedLen, isNotNull);
            expect(seedLen, greaterThan(0));
          }
          kem.dispose();
        } else {
          print('$algName: not available');
        }
      }

      // Print summary
      print('\nDeterministic support summary:');
      supportedCount.forEach((alg, supported) {
        print('  $alg: ${supported ? "✅" : "❌"}');
      });

      // At least some algorithms should be available for testing
      expect(
        supportedCount.isNotEmpty,
        isTrue,
        reason: 'At least some KEM algorithms should be available',
      );
    });

    // Test the algorithms that actually support deterministic generation
    test('Test ML-KEM deterministic generation functionality', () {
      // Focus on ML-KEM variants which actually support deterministic generation
      final mlkemAlgorithms = ['ML-KEM-512', 'ML-KEM-768', 'ML-KEM-1024'];

      bool foundSupported = false;

      for (final algName in mlkemAlgorithms) {
        final kem = KEM.create(algName);
        if (kem != null) {
          if (kem.supportsDeterministicGeneration) {
            foundSupported = true;
            print('$algName supports deterministic generation - testing...');

            final seed = Uint8List.fromList(
              List.generate(kem.seedLength!, (i) => (i * 7) % 256),
            );

            final keyPair1 = kem.generateKeyPairDerand(seed);
            final keyPair2 = kem.generateKeyPairDerand(seed);

            expect(keyPair1.publicKey, equals(keyPair2.publicKey));
            expect(keyPair1.secretKey, equals(keyPair2.secretKey));

            // Also test that it works with encryption/decryption
            final encResult = kem.encapsulate(keyPair1.publicKey);
            final sharedSecret = kem.decapsulate(
              encResult.ciphertext,
              keyPair1.secretKey,
            );
            expect(sharedSecret, equals(encResult.sharedSecret));

            print('✅ $algName deterministic generation works correctly');
            break; // Test one that works
          }
          kem.dispose();
        }
      }

      expect(
        foundSupported,
        isTrue,
        reason:
            'At least one ML-KEM algorithm should support deterministic generation',
      );
    });
  });
}
