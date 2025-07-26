import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'bindings/liboqs_bindings.dart';
import 'liboqs_base.dart';

/// Key Encapsulation Mechanism (KEM) implementation
class KEM {
  late final Pointer<OQS_KEM> _kemPtr;
  final String algorithmName;

  KEM._(this._kemPtr, this.algorithmName);

  /// supported KEM algorithms by liboqs
  static void printSupportedKemAlgorithms() {
    print("Supported KEMs:");
    final kemCount = LibOQSBase.bindings.OQS_KEM_alg_count();
    for (int i = 0; i < kemCount; i++) {
      final kemNamePtr = LibOQSBase.bindings.OQS_KEM_alg_identifier(i);
      if (kemNamePtr != ffi.nullptr) {
        final kemName = kemNamePtr.cast<Utf8>().toDartString();
        final isEnabled = LibOQSBase.bindings.OQS_KEM_alg_is_enabled(
          kemName.toNativeUtf8().cast<ffi.Char>(),
        );
        if (isEnabled == 1) {
          print("- $kemName");
        }
      }
    }
  }

  /// returns list of supported kem algorithms from liboqs
  static List<String> getSupportedKemAlgorithms() {
    final kemCount = LibOQSBase.bindings.OQS_KEM_alg_count();
    final List<String> supportedKems = [];

    for (int i = 0; i < kemCount; i++) {
      final kemNamePtr = LibOQSBase.bindings.OQS_KEM_alg_identifier(i);
      if (kemNamePtr != ffi.nullptr) {
        final kemName = kemNamePtr.cast<Utf8>().toDartString();
        final isEnabled = LibOQSBase.bindings.OQS_KEM_alg_is_enabled(
          kemName.toNativeUtf8().cast<ffi.Char>(),
        );
        if (isEnabled == 1) {
          supportedKems.add(kemName);
        }
      }
    }
    return supportedKems;
  }

  /// Create a new KEM instance with the specified algorithm
  static KEM? create(String algorithmName) {
    final namePtr = algorithmName.toNativeUtf8();
    try {
      final kemPtr = LibOQSBase.bindings.OQS_KEM_new(namePtr.cast());
      if (kemPtr == nullptr) {
        return null;
      }
      return KEM._(kemPtr.cast<OQS_KEM>(), algorithmName);
    } finally {
      calloc.free(namePtr);
    }
  }

  /// Check if a KEM algorithm is supported
  static bool isSupported(String algorithmName) {
    final namePtr = algorithmName.toNativeUtf8();
    try {
      return LibOQSBase.bindings.OQS_KEM_alg_is_enabled(namePtr.cast()) == 1;
    } finally {
      calloc.free(namePtr);
    }
  }

  /// Get hard coded list of supported KEM algorithms
  static List<String> getSupportedKemAlgorithmsHardCodedList() {
    final List<String> algorithms = [];

    final kemAlgorithms = [
      'Classic-McEliece-348864',
      'Classic-McEliece-348864f',
      'Classic-McEliece-460896',
      'Classic-McEliece-460896f',
      'Classic-McEliece-6688128',
      'Classic-McEliece-6688128f',
      'Classic-McEliece-6960119',
      'Classic-McEliece-6960119f',
      'Classic-McEliece-8192128',
      'Classic-McEliece-8192128f',
      'Kyber512',
      'Kyber768',
      'Kyber1024',
      'ML-KEM-512',
      'ML-KEM-768',
      'ML-KEM-1024',
      'sntrup761',
      'FrodoKEM-640-AES',
      'FrodoKEM-640-SHAKE',
      'FrodoKEM-976-AES',
      'FrodoKEM-976-SHAKE',
      'FrodoKEM-1344-AES',
      'FrodoKEM-1344-SHAKE',
    ];

    for (final alg in kemAlgorithms) {
      if (isSupported(alg)) {
        algorithms.add(alg);
      }
    }

    return algorithms;
  }

  /// Get the public key length for this KEM
  int get publicKeyLength {
    return _kemPtr.ref.length_public_key;
  }

  /// Get the secret key length for this KEM
  int get secretKeyLength {
    return _kemPtr.ref.length_secret_key;
  }

  /// Get the ciphertext length for this KEM
  int get ciphertextLength {
    return _kemPtr.ref.length_ciphertext;
  }

  /// Get the shared secret length for this KEM
  int get sharedSecretLength {
    return _kemPtr.ref.length_shared_secret;
  }

  /// Generate a key pair
  KEMKeyPair generateKeyPair() {
    final publicKey = LibOQSUtils.allocateBytes(publicKeyLength);
    final secretKey = LibOQSUtils.allocateBytes(secretKeyLength);

    try {
      // Call the keypair function pointer from the struct
      final keypairFn = _kemPtr.ref.keypair
          .asFunction<
            int Function(Pointer<Uint8> publicKey, Pointer<Uint8> secretKey)
          >();

      final result = keypairFn(publicKey, secretKey);
      if (result != 0) {
        throw LibOQSException('Failed to generate key pair', result);
      }

      return KEMKeyPair(
        publicKey: LibOQSUtils.pointerToUint8List(publicKey, publicKeyLength),
        secretKey: LibOQSUtils.pointerToUint8List(secretKey, secretKeyLength),
      );
    } finally {
      LibOQSUtils.freePointer(publicKey);
      LibOQSUtils.freePointer(secretKey);
    }
  }

  /// Encapsulate a shared secret using the public key
  KEMEncapsulationResult encapsulate(Uint8List publicKey) {
    if (publicKey.length != publicKeyLength) {
      throw LibOQSException(
        'Invalid public key length: expected $publicKeyLength, got ${publicKey.length}',
      );
    }

    final ciphertext = LibOQSUtils.allocateBytes(ciphertextLength);
    final sharedSecret = LibOQSUtils.allocateBytes(sharedSecretLength);
    final publicKeyPtr = LibOQSUtils.uint8ListToPointer(publicKey);

    try {
      // Call the encaps function pointer from the struct
      final encapsFn = _kemPtr.ref.encaps
          .asFunction<
            int Function(
              Pointer<Uint8> ciphertext,
              Pointer<Uint8> sharedSecret,
              Pointer<Uint8> publicKey,
            )
          >();

      final result = encapsFn(ciphertext, sharedSecret, publicKeyPtr);

      if (result != 0) {
        throw LibOQSException('Failed to encapsulate', result);
      }

      return KEMEncapsulationResult(
        ciphertext: LibOQSUtils.pointerToUint8List(
          ciphertext,
          ciphertextLength,
        ),
        sharedSecret: LibOQSUtils.pointerToUint8List(
          sharedSecret,
          sharedSecretLength,
        ),
      );
    } finally {
      LibOQSUtils.freePointer(ciphertext);
      LibOQSUtils.freePointer(sharedSecret);
      LibOQSUtils.freePointer(publicKeyPtr);
    }
  }

  /// Decapsulate a shared secret using the secret key
  Uint8List decapsulate(Uint8List ciphertext, Uint8List secretKey) {
    if (ciphertext.length != ciphertextLength) {
      throw LibOQSException(
        'Invalid ciphertext length: expected $ciphertextLength, got ${ciphertext.length}',
      );
    }
    if (secretKey.length != secretKeyLength) {
      throw LibOQSException(
        'Invalid secret key length: expected $secretKeyLength, got ${secretKey.length}',
      );
    }

    final sharedSecret = LibOQSUtils.allocateBytes(sharedSecretLength);
    final ciphertextPtr = LibOQSUtils.uint8ListToPointer(ciphertext);
    final secretKeyPtr = LibOQSUtils.uint8ListToPointer(secretKey);

    try {
      // Call the decaps function pointer from the struct
      final decapsFn = _kemPtr.ref.decaps
          .asFunction<
            int Function(
              Pointer<Uint8> sharedSecret,
              Pointer<Uint8> ciphertext,
              Pointer<Uint8> secretKey,
            )
          >();

      final result = decapsFn(sharedSecret, ciphertextPtr, secretKeyPtr);

      if (result != 0) {
        throw LibOQSException('Failed to decapsulate', result);
      }

      return LibOQSUtils.pointerToUint8List(sharedSecret, sharedSecretLength);
    } finally {
      LibOQSUtils.freePointer(sharedSecret);
      LibOQSUtils.freePointer(ciphertextPtr);
      LibOQSUtils.freePointer(secretKeyPtr);
    }
  }

  /// Clean up resources
  void dispose() {
    LibOQSBase.bindings.OQS_KEM_free(_kemPtr);
  }
}

/// KEM key pair
class KEMKeyPair {
  final Uint8List publicKey;
  final Uint8List secretKey;

  const KEMKeyPair({required this.publicKey, required this.secretKey});
}

/// KEM encapsulation result
class KEMEncapsulationResult {
  final Uint8List ciphertext;
  final Uint8List sharedSecret;

  const KEMEncapsulationResult({
    required this.ciphertext,
    required this.sharedSecret,
  });
}
