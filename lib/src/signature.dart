import 'dart:convert';
import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'bindings/liboqs_bindings.dart';
import 'liboqs_base.dart';

/// Digital Signature implementation
class Signature {
  late final Pointer<OQS_SIG> _sigPtr;
  final String algorithmName;

  Signature._(this._sigPtr, this.algorithmName);

  String get algorithmVersion =>
      _sigPtr.ref.alg_version.cast<Utf8>().toDartString();
  int get claimedNistLevel => _sigPtr.ref.claimed_nist_level;
  bool get isEufCmaSecure => _sigPtr.ref.euf_cma;

  /// supported Signature algorithms by liboqs
  static void printSupportedSignatureAlgorithms() {
    print("\nSupported Signatures:");
    final sigCount = LibOQSBase.bindings.OQS_SIG_alg_count();
    for (int i = 0; i < sigCount; i++) {
      final sigNamePtr = LibOQSBase.bindings.OQS_SIG_alg_identifier(i);
      if (sigNamePtr != ffi.nullptr) {
        final sigName = sigNamePtr.cast<Utf8>().toDartString();
        final isEnabled = LibOQSBase.bindings.OQS_SIG_alg_is_enabled(
          sigName.toNativeUtf8().cast<ffi.Char>(),
        );
        if (isEnabled == 1) {
          print("- $sigName");
        }
      }
    }
  }

  /// returns list of supported Signature algorithms from liboqs
  static List<String> getSupportedSignatureAlgorithms() {
    final sigCount = LibOQSBase.bindings.OQS_SIG_alg_count();
    final List<String> supportedSigs = [];

    for (int i = 0; i < sigCount; i++) {
      final sigNamePtr = LibOQSBase.bindings.OQS_SIG_alg_identifier(i);
      if (sigNamePtr != ffi.nullptr) {
        final sigName = sigNamePtr.cast<Utf8>().toDartString();
        final isEnabled = LibOQSBase.bindings.OQS_SIG_alg_is_enabled(
          sigName.toNativeUtf8().cast<ffi.Char>(),
        );
        if (isEnabled == 1) {
          supportedSigs.add(sigName);
        }
      }
    }

    return supportedSigs;
  }

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

  /// Get hard coded list of supported signature algorithms
  static List<String> getSupportedSignatureAlgorithmsHardCodedList() {
    final List<String> algorithms = [];

    final sigAlgorithms = [
      'Dilithium2',
      'Dilithium3',
      'Dilithium5',
      'ML-DSA-44',
      'ML-DSA-65',
      'ML-DSA-87',
      'Falcon-512',
      'Falcon-1024',
      'Falcon-padded-512',
      'Falcon-padded-1024',
      'SPHINCS+-SHA2-128f-simple',
      'SPHINCS+-SHA2-128s-simple',
      'SPHINCS+-SHA2-192f-simple',
      'SPHINCS+-SHA2-192s-simple',
      'SPHINCS+-SHA2-256f-simple',
      'SPHINCS+-SHA2-256s-simple',
      'SPHINCS+-SHAKE-128f-simple',
      'SPHINCS+-SHAKE-128s-simple',
      'SPHINCS+-SHAKE-192f-simple',
      'SPHINCS+-SHAKE-192s-simple',
      'SPHINCS+-SHAKE-256f-simple',
      'SPHINCS+-SHAKE-256s-simple',
      'MAYO-1',
      'MAYO-2',
      'MAYO-3',
      'MAYO-5',
      'cross-rsdp-128-balanced',
      'cross-rsdp-128-fast',
      'cross-rsdp-128-small',
      'cross-rsdp-192-balanced',
      'cross-rsdp-192-fast',
      'cross-rsdp-192-small',
      'cross-rsdp-256-balanced',
      'cross-rsdp-256-fast',
      'cross-rsdp-256-small',
      'cross-rsdpg-128-balanced',
      'cross-rsdpg-128-fast',
      'cross-rsdpg-128-small',
      'cross-rsdpg-192-balanced',
      'cross-rsdpg-192-fast',
      'cross-rsdpg-192-small',
      'cross-rsdpg-256-balanced',
      'cross-rsdpg-256-fast',
      'cross-rsdpg-256-small',
      'OV-Is',
      'OV-Ip',
      'OV-III',
      'OV-V',
      'OV-Is-pkc',
      'OV-Ip-pkc',
      'OV-III-pkc',
      'OV-V-pkc',
      'OV-Is-pkc-skc',
      'OV-Ip-pkc-skc',
      'OV-III-pkc-skc',
      'OV-V-pkc-skc',
      'SNOVA_24_5_4',
      'SNOVA_24_5_4_SHAKE',
      'SNOVA_24_5_4_esk',
      'SNOVA_24_5_4_SHAKE_esk',
      'SNOVA_37_17_2',
      'SNOVA_25_8_3',
      'SNOVA_56_25_2',
      'SNOVA_49_11_3',
      'SNOVA_37_8_4',
      'SNOVA_24_5_5',
      'SNOVA_60_10_4',
      'SNOVA_29_6_5',
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

  /// Returns all Uint8List properties as base64 encoded strings
  Map<String, String> toStrings() {
    return {
      'publicKey': base64Encode(publicKey),
      'secretKey': base64Encode(secretKey),
    };
  }

  /// Alternative method that returns properties as hex strings
  Map<String, String> toHexStrings() {
    return {
      'publicKey': publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      'secretKey': secretKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
    };
  }
}
