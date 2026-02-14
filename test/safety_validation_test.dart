import 'dart:typed_data';

import 'package:oqs/oqs.dart';
import 'package:test/test.dart';

void main() {
  String _pickKEMAlgorithm(List<String> algorithms) {
    const preferred = ['ML-KEM-768', 'ML-KEM-512', 'Kyber768', 'Kyber512'];
    for (final candidate in preferred) {
      if (algorithms.contains(candidate)) {
        return candidate;
      }
    }
    return algorithms.first;
  }

  String _pickSignatureAlgorithm(List<String> algorithms) {
    const preferred = ['ML-DSA-65', 'ML-DSA-44', 'Dilithium3', 'Dilithium2'];
    for (final candidate in preferred) {
      if (algorithms.contains(candidate)) {
        return candidate;
      }
    }
    return algorithms.first;
  }

  setUpAll(() {
    LibOQS.init();
  });

  tearDownAll(() {
    LibOQS.cleanup();
  });

  group('Algorithm Validation', () {
    test('unsupported KEM create throws LibOQSException', () {
      expect(
        () => KEM.create('NOT-A-REAL-KEM'),
        throwsA(isA<LibOQSException>()),
      );
    });

    test('unsupported Signature create throws LibOQSException', () {
      expect(
        () => Signature.create('NOT-A-REAL-SIG'),
        throwsA(isA<LibOQSException>()),
      );
    });
  });

  group('KEM Safety Checks', () {
    test('operations throw after dispose', () {
      final algorithm = _pickKEMAlgorithm(LibOQS.getSupportedKEMAlgorithms());
      final kem = KEM.create(algorithm)!;
      kem.dispose();

      expect(() => kem.generateKeyPair(), throwsA(isA<StateError>()));
      expect(() => kem.publicKeyLength, throwsA(isA<StateError>()));
    });

    test('invalid key material lengths throw LibOQSException', () {
      final algorithm = _pickKEMAlgorithm(LibOQS.getSupportedKEMAlgorithms());
      final kem = KEM.create(algorithm)!;
      final keyPair = kem.generateKeyPair();

      expect(
        () => kem.encapsulate(Uint8List(kem.publicKeyLength - 1)),
        throwsA(isA<LibOQSException>()),
      );
      expect(
        () => kem.decapsulate(
          Uint8List(kem.ciphertextLength - 1),
          keyPair.secretKey,
        ),
        throwsA(isA<LibOQSException>()),
      );
      expect(
        () => kem.decapsulate(
          Uint8List(kem.ciphertextLength),
          Uint8List(kem.secretKeyLength - 1),
        ),
        throwsA(isA<LibOQSException>()),
      );

      kem.dispose();
    });
  });

  group('Signature Safety Checks', () {
    test('operations throw after dispose', () {
      final algorithm = _pickSignatureAlgorithm(
        LibOQS.getSupportedSignatureAlgorithms(),
      );
      final sig = Signature.create(algorithm);
      sig.dispose();

      expect(() => sig.generateKeyPair(), throwsA(isA<StateError>()));
      expect(() => sig.publicKeyLength, throwsA(isA<StateError>()));
    });

    test('invalid key lengths throw LibOQSException', () {
      final algorithm = _pickSignatureAlgorithm(
        LibOQS.getSupportedSignatureAlgorithms(),
      );
      final sig = Signature.create(algorithm);
      final keyPair = sig.generateKeyPair();
      final msg = Uint8List.fromList('validation'.codeUnits);

      expect(
        () => sig.sign(msg, Uint8List(sig.secretKeyLength - 1)),
        throwsA(isA<LibOQSException>()),
      );
      final signature = sig.sign(msg, keyPair.secretKey);
      expect(
        () => sig.verify(msg, signature, Uint8List(sig.publicKeyLength - 1)),
        throwsA(isA<LibOQSException>()),
      );

      sig.dispose();
    });

    test('verification fails on tampered signature', () {
      final algorithm = _pickSignatureAlgorithm(
        LibOQS.getSupportedSignatureAlgorithms(),
      );
      final sig = Signature.create(algorithm);
      final keyPair = sig.generateKeyPair();
      final msg = Uint8List.fromList('hello quantum'.codeUnits);
      final signature = sig.sign(msg, keyPair.secretKey);

      signature[0] ^= 0x01;
      final valid = sig.verify(msg, signature, keyPair.publicKey);
      expect(valid, isFalse);

      sig.dispose();
    });
  });

  group('Random API Contracts', () {
    test('generateBytes validates bounds and returns requested length', () {
      final bytes = OQSRandom.generateBytes(32);
      expect(bytes.length, equals(32));

      expect(() => OQSRandom.generateBytes(0), throwsArgumentError);
      expect(
        () => OQSRandom.generateBytes(1024 * 1024 + 1),
        throwsArgumentError,
      );
    });

    test('generateSeed validates bounds', () {
      expect(OQSRandom.generateSeed().length, equals(32));
      expect(OQSRandom.generateSeed(16).length, equals(16));
      expect(OQSRandom.generateSeed(64).length, equals(64));

      expect(() => OQSRandom.generateSeed(15), throwsArgumentError);
      expect(() => OQSRandom.generateSeed(65), throwsArgumentError);
    });

    test('generateInt validates range and stays in bounds', () {
      for (int i = 0; i < 50; i++) {
        final n = OQSRandom.generateInt(3, 9);
        expect(n, inInclusiveRange(3, 8));
      }
      expect(() => OQSRandom.generateInt(5, 5), throwsArgumentError);
      expect(() => OQSRandom.generateInt(7, 3), throwsArgumentError);
    });

    test('utility extensions return sane values', () {
      final value = OQSRandomExtensions.generateDouble();
      expect(value, inInclusiveRange(0.0, 1.0));

      final list = [1, 2, 3, 4, 5];
      OQSRandomExtensions.shuffleList(list);
      expect(list.toSet(), equals({1, 2, 3, 4, 5}));
    });

    test('switchAlgorithm validates input', () {
      expect(() => OQSRandom.switchAlgorithm(''), throwsArgumentError);
    });
  });
}
