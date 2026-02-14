# OQS for Dart

[![pub package](https://img.shields.io/pub/v/oqs.svg)](https://pub.dev/packages/oqs)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Dart FFI bindings for [liboqs](https://github.com/open-quantum-safe/liboqs), providing post-quantum KEM and signature primitives.

## Version Compatibility

| `oqs` package | `liboqs` |
|---|---|
| `3.x` | `0.15.x` |
| `2.x` | `0.14.x` (legacy) |

`3.0.0` is a breaking release aligned to `liboqs 0.15.0`.

## Install

```yaml
dependencies:
  oqs: ^3.0.0
```

## Native Library Setup

You still need a native `liboqs` library for your platform.

### Option 1: Prebuilt binaries

Use your own binaries or releases such as:
- https://github.com/bardiakz/liboqs-binaries/releases

### Option 2: Build from source

```bash
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja
ninja install
```

### Optional explicit paths

```dart
import 'package:oqs/oqs.dart';

LibOQSLoader.customPaths = LibraryPaths(
  windows: r'C:\libs\oqs.dll',
  linux: '/usr/local/lib/liboqs.so',
  macOS: '/opt/homebrew/lib/liboqs.dylib',
);
```

## Quick Start

```dart
import 'dart:typed_data';
import 'package:oqs/oqs.dart';

void main() {
  LibOQS.init();

  final kems = LibOQS.getSupportedKEMAlgorithms();
  if (kems.isEmpty) {
    throw StateError('No enabled KEM algorithms in loaded liboqs');
  }

  final kem = KEM.create(kems.first)!;
  final kp = kem.generateKeyPair();
  final enc = kem.encapsulate(kp.publicKey);
  final dec = kem.decapsulate(enc.ciphertext, kp.secretKey);

  print(dec.length == enc.sharedSecret.length); // true

  kem.dispose();
  LibOQS.cleanup();
}
```

## API Notes

- Prefer runtime algorithm discovery:
  - `LibOQS.getSupportedKEMAlgorithms()`
  - `LibOQS.getSupportedSignatureAlgorithms()`
- Do not hard-code key/signature lengths. Use:
  - `kem.publicKeyLength`, `kem.secretKeyLength`, `kem.ciphertextLength`
  - `sig.publicKeyLength`, `sig.secretKeyLength`, `sig.maxSignatureLength`
- Deterministic keypair generation is algorithm-dependent:
  - `kem.supportsDeterministicGeneration`
  - `kem.seedLength`

## Signature Example

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:oqs/oqs.dart';

void main() {
  final sigAlgs = LibOQS.getSupportedSignatureAlgorithms();
  if (sigAlgs.isEmpty) {
    throw StateError('No enabled signature algorithms');
  }

  final sig = Signature.create(sigAlgs.first);
  final kp = sig.generateKeyPair();

  final msg = Uint8List.fromList(utf8.encode('hello pqc'));
  final s = sig.sign(msg, kp.secretKey);
  final ok = sig.verify(msg, s, kp.publicKey);

  print(ok); // true
  sig.dispose();
}
```

## Migration to 3.0.0 (`liboqs 0.15.0`)

1. Upgrade dependency in `pubspec.yaml` to `^3.0.0`.
2. Ensure native `liboqs` binary is `0.15.x`.
3. Replace fixed algorithm assumptions (`Kyber*`, `Dilithium*`) with runtime discovery.
4. Remove hard-coded size assertions and read lengths from each algorithm instance.
5. Re-run tests against every target platform binary you ship.

## Common Problems

### Library not found

Set `LibOQSLoader.customPaths` or install `liboqs` to standard system paths.

### Algorithm not available

Enabled algorithms depend on how your `liboqs` binary was built. Check:

```dart
print(LibOQS.getSupportedKEMAlgorithms());
print(LibOQS.getSupportedSignatureAlgorithms());
```

## Security Notes

- Use NIST-standardized algorithms (`ML-KEM-*`, `ML-DSA-*`) for production.
- Dispose algorithm objects (`kem.dispose()`, `sig.dispose()`) when done.
- Keep `liboqs` binaries updated and track security advisories.
- Do not share mutable crypto object state across isolates/threads.

## Examples

See the [`example/`](example/) directory for end-to-end usage samples.
