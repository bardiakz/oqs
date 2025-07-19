import 'dart:typed_data';

import 'package:oqs/liboqs.dart';
import 'package:test/test.dart';

void main() {
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
      expect(kems, contains('Kyber512'));
    });

    test('should list supported signature algorithms', () {
      final sigs = LibOQS.getSupportedSignatureAlgorithms();
      expect(sigs, isNotEmpty);
      expect(sigs, contains('Dilithium2'));
    });
  });

  group('KEM Operations', () {
    test('Kyber512 key generation and encapsulation', () {
      final kem = KEM.create('Kyber512');
      expect(kem, isNotNull);

      final keyPair = kem!.generateKeyPair();
      expect(keyPair.publicKey.length, equals(800));
      expect(keyPair.secretKey.length, equals(1632));

      final encResult = kem.encapsulate(keyPair.publicKey);
      expect(encResult.ciphertext.length, equals(768));
      expect(encResult.sharedSecret.length, equals(32));

      final decryptedSecret = kem.decapsulate(
        encResult.ciphertext,
        keyPair.secretKey,
      );
      expect(decryptedSecret, equals(encResult.sharedSecret));

      kem.dispose();
    });
  });

  group('Signature Operations', () {
    test('Dilithium2 key generation and signing', () {
      final sig = Signature.create('Dilithium2');
      expect(sig, isNotNull);

      final keyPair = sig!.generateKeyPair();
      expect(keyPair.publicKey.length, equals(1312));
      expect(keyPair.secretKey.length, equals(2528));

      final message = Uint8List.fromList('Hello World'.codeUnits);
      final signature = sig.sign(message, keyPair.secretKey);
      expect(signature.length, lessThanOrEqualTo(2420));

      final isValid = sig.verify(message, signature, keyPair.publicKey);
      expect(isValid, isTrue);

      sig.dispose();
    });
  });
}
