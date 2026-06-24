import 'dart:convert';
import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:oqs/src/bindings/liboqs_bindings.dart';
import 'package:oqs/src/oqs_base.dart';

final Finalizer<Pointer<OQS_KEM>> _kemFinalizer = Finalizer(
  (ptr) => LibOQSBase.bindings.OQS_KEM_free(ptr),
);

/// Key Encapsulation Mechanism (KEM) implementation
class KEM {
  late final Pointer<OQS_KEM> _kemPtr;
  final String algorithmName;

  bool _disposed = false;

  KEM._(this._kemPtr, this.algorithmName) {
    _kemFinalizer.attach(this, _kemPtr, detach: this);
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('KEM instance has been disposed');
    }
  }

  String get algorithmVersion {
    _checkDisposed();
    return _kemPtr.ref.alg_version.cast<Utf8>().toDartString();
  }

  int get claimedNistLevel {
    _checkDisposed();
    return _kemPtr.ref.claimed_nist_level;
  }

  bool get isIndCcaSecure {
    _checkDisposed();
    return _kemPtr.ref.ind_cca;
  }

  /// supported KEM algorithms by liboqs
  static void printSupportedKemAlgorithms() {
    print("Supported KEMs:");
    final kemCount = LibOQSBase.bindings.OQS_KEM_alg_count();
    for (int i = 0; i < kemCount; i++) {
      final kemNamePtr = LibOQSBase.bindings.OQS_KEM_alg_identifier(i);
      if (kemNamePtr != ffi.nullptr) {
        final kemName = kemNamePtr.cast<Utf8>().toDartString();
        final isEnabled = LibOQSBase.bindings.OQS_KEM_alg_is_enabled(
          kemNamePtr,
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
          kemNamePtr,
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
    LibOQSBase.init(); // Auto-initialize

    if (algorithmName.isEmpty) {
      throw ArgumentError('Algorithm name cannot be empty');
    }

    final namePtr = algorithmName.toNativeUtf8();
    try {
      final kemPtr = LibOQSBase.bindings.OQS_KEM_new(namePtr.cast());
      if (kemPtr == nullptr) {
        throw LibOQSException(
          'Failed to create KEM instance. Algorithm may not be supported or enabled.',
          null,
          algorithmName,
        );
      }
      return KEM._(kemPtr.cast<OQS_KEM>(), algorithmName);
    } finally {
      LibOQSUtils.freePointer(namePtr);
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
  @Deprecated('Use getSupportedKemAlgorithms() directly')
  static List<String> getSupportedKemAlgorithmsHardCodedList() {
    return getSupportedKemAlgorithms();
  }

  /// Get the public key length for this KEM
  int get publicKeyLength {
    _checkDisposed();
    return _kemPtr.ref.length_public_key;
  }

  /// Get the secret key length for this KEM
  int get secretKeyLength {
    _checkDisposed();
    return _kemPtr.ref.length_secret_key;
  }

  /// Get the ciphertext length for this KEM
  int get ciphertextLength {
    _checkDisposed();
    return _kemPtr.ref.length_ciphertext;
  }

  /// Get the shared secret length for this KEM
  int get sharedSecretLength {
    _checkDisposed();
    return _kemPtr.ref.length_shared_secret;
  }

  /// Get the seed length required for deterministic key generation
  int? get seedLength {
    _checkDisposed();
    final length = _kemPtr.ref.length_keypair_seed;
    return length > 0 ? length : null;
  }

  /// Check if this KEM supports deterministic key generation
  bool get supportsDeterministicGeneration {
    _checkDisposed();
    return _kemPtr.ref.keypair_derand != nullptr && seedLength != null;
  }

  /// Generate a key pair deterministically from a seed
  ///
  /// The [seed] must be exactly [seedLength] bytes long. Returns a [KEMKeyPair]
  /// containing the generated public and secret keys. Throws [LibOQSException]
  /// if the algorithm doesn't support deterministic generation or if the seed
  /// length is invalid.
  KEMKeyPair generateKeyPairDerand(Uint8List seed) {
    _checkDisposed();

    if (!supportsDeterministicGeneration) {
      throw LibOQSException(
        'Algorithm $algorithmName does not support deterministic key generation',
      );
    }

    final requiredSeedLength = seedLength;
    if (requiredSeedLength == null) {
      throw LibOQSException(
        'Cannot determine required seed length for $algorithmName',
      );
    }

    if (seed.length != requiredSeedLength) {
      throw LibOQSException(
        'Invalid seed length: expected $requiredSeedLength, got ${seed.length}',
      );
    }

    Pointer<Uint8>? publicKey;
    Pointer<Uint8>? secretKey;
    Pointer<Uint8>? seedPtr;

    try {
      publicKey = LibOQSUtils.allocateBytes(publicKeyLength);
      secretKey = LibOQSUtils.allocateBytes(secretKeyLength);
      seedPtr = LibOQSUtils.uint8ListToPointer(seed);

      final status = LibOQSBase.bindings.OQS_KEM_keypair_derand(
        _kemPtr,
        publicKey,
        secretKey,
        seedPtr,
      );
      if (status != OQS_STATUS.OQS_SUCCESS) {
        throw LibOQSException(
          'Failed to generate deterministic key pair',
          status.value,
        );
      }

      return KEMKeyPair(
        publicKey: LibOQSUtils.pointerToUint8List(publicKey, publicKeyLength),
        secretKey: LibOQSUtils.pointerToUint8List(secretKey, secretKeyLength),
      );
    } finally {
      LibOQSUtils.freePointer(publicKey); // Public key doesn't strictly need cleansing
      LibOQSUtils.freeSecure(secretKey, secretKeyLength);
      LibOQSUtils.freeSecure(seedPtr, seed.length);
    }
  }

  /// Generate a key pair
  KEMKeyPair generateKeyPair() {
    _checkDisposed();
    Pointer<Uint8>? publicKey;
    Pointer<Uint8>? secretKey;

    try {
      publicKey = LibOQSUtils.allocateBytes(publicKeyLength);
      secretKey = LibOQSUtils.allocateBytes(secretKeyLength);

      final status = LibOQSBase.bindings.OQS_KEM_keypair(
        _kemPtr,
        publicKey,
        secretKey,
      );
      if (status != OQS_STATUS.OQS_SUCCESS) {
        throw LibOQSException('Failed to generate key pair', status.value);
      }

      return KEMKeyPair(
        publicKey: LibOQSUtils.pointerToUint8List(publicKey, publicKeyLength),
        secretKey: LibOQSUtils.pointerToUint8List(secretKey, secretKeyLength),
      );
    } finally {
      LibOQSUtils.freePointer(publicKey);
      LibOQSUtils.freeSecure(secretKey, secretKeyLength);
    }
  }

  /// Encapsulate a shared secret using the public key
  KEMEncapsulationResult encapsulate(Uint8List publicKey) {
    _checkDisposed();
    if (publicKey.length != publicKeyLength) {
      throw LibOQSException(
        'Invalid public key length: expected $publicKeyLength, got ${publicKey.length}',
      );
    }

    Pointer<Uint8>? ciphertext;
    Pointer<Uint8>? sharedSecret;
    Pointer<Uint8>? publicKeyPtr;

    try {
      ciphertext = LibOQSUtils.allocateBytes(ciphertextLength);
      sharedSecret = LibOQSUtils.allocateBytes(sharedSecretLength);
      publicKeyPtr = LibOQSUtils.uint8ListToPointer(publicKey);

      final status = LibOQSBase.bindings.OQS_KEM_encaps(
        _kemPtr,
        ciphertext,
        sharedSecret,
        publicKeyPtr,
      );
      if (status != OQS_STATUS.OQS_SUCCESS) {
        throw LibOQSException('Failed to encapsulate', status.value);
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
      LibOQSUtils.freeSecure(sharedSecret, sharedSecretLength);
      LibOQSUtils.freePointer(publicKeyPtr);
    }
  }

  /// Decapsulate a shared secret using the secret key
  Uint8List decapsulate(Uint8List ciphertext, Uint8List secretKey) {
    _checkDisposed();
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

    Pointer<Uint8>? sharedSecret;
    Pointer<Uint8>? ciphertextPtr;
    Pointer<Uint8>? secretKeyPtr;

    try {
      sharedSecret = LibOQSUtils.allocateBytes(sharedSecretLength);
      ciphertextPtr = LibOQSUtils.uint8ListToPointer(ciphertext);
      secretKeyPtr = LibOQSUtils.uint8ListToPointer(secretKey);

      final status = LibOQSBase.bindings.OQS_KEM_decaps(
        _kemPtr,
        sharedSecret,
        ciphertextPtr,
        secretKeyPtr,
      );
      if (status != OQS_STATUS.OQS_SUCCESS) {
        throw LibOQSException('Failed to decapsulate', status.value);
      }

      return LibOQSUtils.pointerToUint8List(sharedSecret, sharedSecretLength);
    } finally {
      LibOQSUtils.freeSecure(sharedSecret, sharedSecretLength);
      LibOQSUtils.freePointer(ciphertextPtr);
      LibOQSUtils.freeSecure(secretKeyPtr, secretKey.length);
    }
  }

  /// Clean up resources
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _kemFinalizer.detach(this);
      LibOQSBase.bindings.OQS_KEM_free(_kemPtr);
    }
  }
}

/// KEM key pair
class KEMKeyPair {
  final Uint8List publicKey;
  final Uint8List secretKey;

  const KEMKeyPair({required this.publicKey, required this.secretKey});

  /// Wipes the key material from the Dart heap.
  /// Note: This does not guarantee security due to GC movement,
  /// but is a best-effort cleanup.
  void dispose() {
    publicKey.fillRange(0, publicKey.length, 0);
    secretKey.fillRange(0, secretKey.length, 0);
  }

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

/// KEM encapsulation result
class KEMEncapsulationResult {
  final Uint8List ciphertext;
  final Uint8List sharedSecret;

  const KEMEncapsulationResult({
    required this.ciphertext,
    required this.sharedSecret,
  });

  /// Wipes the shared secret and ciphertext from the Dart heap.
  void dispose() {
    ciphertext.fillRange(0, ciphertext.length, 0);
    sharedSecret.fillRange(0, sharedSecret.length, 0);
  }

  /// Returns all Uint8List properties as base64 encoded strings
  Map<String, String> toStrings() {
    return {
      'ciphertext': base64Encode(ciphertext),
      'sharedSecret': base64Encode(sharedSecret),
    };
  }

  /// Alternative method that returns properties as hex strings
  Map<String, String> toHexStrings() {
    return {
      'ciphertext': ciphertext
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      'sharedSecret': sharedSecret
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
    };
  }
}
