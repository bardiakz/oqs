// lib/src/signature.dart
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'bindings/liboqs_bindings.dart';
import 'liboqs_base.dart';

/// Digital Signature implementation
class Signature {
  late final Pointer<OQS_SIG> _sigPtr;
  final String algorithmName;

  Signature._(this._sigPtr, this.algorithmName);

  /// Create a new Signature instance with the specified algorithm
  static Signature? create(String algorithmName) {
    final namePtr = algorithmName.toNativeUtf8();
    try {
      final sigPtr = LibOQSBase.bindings.OQS_SIG_new(namePtr.cast());
      if (sigPtr == nullptr) {
        return null;
      }
      // Cast to the correct type
      return Signature._(sigPtr.cast<OQS_SIG>(), algorithmName);
    } finally {
      calloc.free(namePtr);
    }
  }

  /// Check if a signature algorithm is supported
  static bool isSupported(String algorithmName) {
    final namePtr = algorithmName.toNativeUtf8();
    try {
      return LibOQSBase.bindings.OQS_SIG_alg_is_enabled(namePtr.cast()) == 1;
    } finally {
      calloc.free(namePtr);
    }
  }

  /// Get list of supported signature algorithms
  static List<String> getSupportedAlgorithms() {
    final List<String> algorithms = [];

    // Common liboqs signature algorithms
    final sigAlgorithms = [
      'Dilithium2',
      'Dilithium3',
      'Dilithium5',
      'Falcon-512',
      'Falcon-1024',
      'SPHINCS+-Haraka-128f-robust',
      'SPHINCS+-Haraka-128f-simple',
      'SPHINCS+-Haraka-128s-robust',
      'SPHINCS+-Haraka-128s-simple',
      'SPHINCS+-Haraka-192f-robust',
      'SPHINCS+-Haraka-192f-simple',
      'SPHINCS+-Haraka-192s-robust',
      'SPHINCS+-Haraka-192s-simple',
      'SPHINCS+-Haraka-256f-robust',
      'SPHINCS+-Haraka-256f-simple',
      'SPHINCS+-Haraka-256s-robust',
      'SPHINCS+-Haraka-256s-simple',
      'SPHINCS+-SHA256-128f-robust',
      'SPHINCS+-SHA256-128f-simple',
      'SPHINCS+-SHA256-128s-robust',
      'SPHINCS+-SHA256-128s-simple',
      'SPHINCS+-SHA256-192f-robust',
      'SPHINCS+-SHA256-192f-simple',
      'SPHINCS+-SHA256-192s-robust',
      'SPHINCS+-SHA256-192s-simple',
      'SPHINCS+-SHA256-256f-robust',
      'SPHINCS+-SHA256-256f-simple',
      'SPHINCS+-SHA256-256s-robust',
      'SPHINCS+-SHA256-256s-simple',
      'SPHINCS+-SHAKE256-128f-robust',
      'SPHINCS+-SHAKE256-128f-simple',
      'SPHINCS+-SHAKE256-128s-robust',
      'SPHINCS+-SHAKE256-128s-simple',
      'SPHINCS+-SHAKE256-192f-robust',
      'SPHINCS+-SHAKE256-192f-simple',
      'SPHINCS+-SHAKE256-192s-robust',
      'SPHINCS+-SHAKE256-192s-simple',
      'SPHINCS+-SHAKE256-256f-robust',
      'SPHINCS+-SHAKE256-256f-simple',
      'SPHINCS+-SHAKE256-256s-robust',
      'SPHINCS+-SHAKE256-256s-simple',
    ];

    for (final alg in sigAlgorithms) {
      if (isSupported(alg)) {
        algorithms.add(alg);
      }
    }

    return algorithms;
  }

  /// Get the public key length for this signature algorithm
  int get publicKeyLength {
    return _sigPtr.ref.length_public_key;
  }

  /// Get the secret key length for this signature algorithm
  int get secretKeyLength {
    return _sigPtr.ref.length_secret_key;
  }

  /// Get the maximum signature length for this algorithm
  int get maxSignatureLength {
    return _sigPtr.ref.length_signature;
  }

  /// Generate a key pair
  SignatureKeyPair generateKeyPair() {
    final publicKey = LibOQSUtils.allocateBytes(publicKeyLength);
    final secretKey = LibOQSUtils.allocateBytes(secretKeyLength);

    try {
      // Call the keypair function pointer from the struct
      final keypairFn = _sigPtr.ref.keypair
          .asFunction<
            int Function(Pointer<Uint8> publicKey, Pointer<Uint8> secretKey)
          >();

      final result = keypairFn(publicKey, secretKey);
      if (result != 0) {
        throw LibOQSException('Failed to generate key pair', result);
      }

      return SignatureKeyPair(
        publicKey: LibOQSUtils.pointerToUint8List(publicKey, publicKeyLength),
        secretKey: LibOQSUtils.pointerToUint8List(secretKey, secretKeyLength),
      );
    } finally {
      LibOQSUtils.freePointer(publicKey);
      LibOQSUtils.freePointer(secretKey);
    }
  }

  /// Sign a message
  Uint8List sign(Uint8List message, Uint8List secretKey) {
    if (secretKey.length != secretKeyLength) {
      throw LibOQSException(
        'Invalid secret key length: expected $secretKeyLength, got ${secretKey.length}',
      );
    }

    final signature = LibOQSUtils.allocateBytes(maxSignatureLength);
    final signatureLength = calloc<Size>();
    signatureLength.value = maxSignatureLength;

    final messagePtr = LibOQSUtils.uint8ListToPointer(message);
    final secretKeyPtr = LibOQSUtils.uint8ListToPointer(secretKey);

    try {
      // Call the sign function pointer from the struct
      final signFn = _sigPtr.ref.sign
          .asFunction<
            int Function(
              Pointer<Uint8> signature,
              Pointer<Size> signatureLen,
              Pointer<Uint8> message,
              int messageLen,
              Pointer<Uint8> secretKey,
            )
          >();

      final result = signFn(
        signature,
        signatureLength,
        messagePtr,
        message.length,
        secretKeyPtr,
      );

      if (result != 0) {
        throw LibOQSException('Failed to sign message', result);
      }

      final actualLength = signatureLength.value;
      return LibOQSUtils.pointerToUint8List(signature, actualLength);
    } finally {
      LibOQSUtils.freePointer(signature);
      LibOQSUtils.freePointer(signatureLength.cast());
      LibOQSUtils.freePointer(messagePtr);
      LibOQSUtils.freePointer(secretKeyPtr);
    }
  }

  /// Verify a signature
  bool verify(Uint8List message, Uint8List signature, Uint8List publicKey) {
    if (publicKey.length != publicKeyLength) {
      throw LibOQSException(
        'Invalid public key length: expected $publicKeyLength, got ${publicKey.length}',
      );
    }

    final messagePtr = LibOQSUtils.uint8ListToPointer(message);
    final signaturePtr = LibOQSUtils.uint8ListToPointer(signature);
    final publicKeyPtr = LibOQSUtils.uint8ListToPointer(publicKey);

    try {
      // Call the verify function pointer from the struct
      final verifyFn = _sigPtr.ref.verify
          .asFunction<
            int Function(
              Pointer<Uint8> message,
              int messageLen,
              Pointer<Uint8> signature,
              int signatureLen,
              Pointer<Uint8> publicKey,
            )
          >();

      final result = verifyFn(
        messagePtr,
        message.length,
        signaturePtr,
        signature.length,
        publicKeyPtr,
      );

      return result == 0;
    } finally {
      LibOQSUtils.freePointer(messagePtr);
      LibOQSUtils.freePointer(signaturePtr);
      LibOQSUtils.freePointer(publicKeyPtr);
    }
  }

  /// Clean up resources
  void dispose() {
    LibOQSBase.bindings.OQS_SIG_free(_sigPtr);
  }
}

/// Signature key pair
class SignatureKeyPair {
  final Uint8List publicKey;
  final Uint8List secretKey;

  const SignatureKeyPair({required this.publicKey, required this.secretKey});
}
