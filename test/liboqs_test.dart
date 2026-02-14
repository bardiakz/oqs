import 'dart:typed_data';

import 'package:oqs/oqs.dart';
import 'package:test/test.dart';

void main() {
  String pickKEMAlgorithm(List<String> algorithms) {
    const preferred = ['ML-KEM-768', 'ML-KEM-512', 'Kyber768', 'Kyber512'];
    for (final candidate in preferred) {
      if (algorithms.contains(candidate)) {
        return candidate;
      }
    }
    return algorithms.first;
  }

  String pickSignatureAlgorithm(List<String> algorithms) {
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

  group('LibOQS Initialization', () {
    test('should return version information', () {
      final version = LibOQS.getVersion();
      expect(version, isNotEmpty);
      expect(version, contains('.'));
    });

    test('should list supported KEM algorithms', () {
      final kems = LibOQS.getSupportedKEMAlgorithms();
      expect(kems, isNotEmpty);
      expect(kems.every((alg) => alg.isNotEmpty), isTrue);
    });

    test('should list supported signature algorithms', () {
      final sigs = LibOQS.getSupportedSignatureAlgorithms();
      expect(sigs, isNotEmpty);
      expect(sigs.every((alg) => alg.isNotEmpty), isTrue);
    });
  });

  group('KEM Operations', () {
    test('key generation and encapsulation for an enabled algorithm', () {
      final kems = LibOQS.getSupportedKEMAlgorithms();
      final algorithm = pickKEMAlgorithm(kems);
      final kem = KEM.create(algorithm);

      final keyPair = kem!.generateKeyPair();
      expect(keyPair.publicKey.length, equals(kem.publicKeyLength));
      expect(keyPair.secretKey.length, equals(kem.secretKeyLength));

      final encResult = kem.encapsulate(keyPair.publicKey);
      expect(encResult.ciphertext.length, equals(kem.ciphertextLength));
      expect(encResult.sharedSecret.length, equals(kem.sharedSecretLength));

      final decryptedSecret = kem.decapsulate(
        encResult.ciphertext,
        keyPair.secretKey,
      );
      expect(decryptedSecret, equals(encResult.sharedSecret));

      kem.dispose();
    });
  });

  group('Signature Operations', () {
    test('key generation and signing for an enabled algorithm', () {
      final sigs = LibOQS.getSupportedSignatureAlgorithms();
      final algorithm = pickSignatureAlgorithm(sigs);
      final sig = Signature.create(algorithm);

      final keyPair = sig.generateKeyPair();
      expect(keyPair.publicKey.length, equals(sig.publicKeyLength));
      expect(keyPair.secretKey.length, equals(sig.secretKeyLength));

      final message = Uint8List.fromList('Hello World'.codeUnits);
      final signature = sig.sign(message, keyPair.secretKey);
      expect(signature.length, lessThanOrEqualTo(sig.maxSignatureLength));

      final isValid = sig.verify(message, signature, keyPair.publicKey);
      expect(isValid, isTrue);

      sig.dispose();
    });
  });
}
