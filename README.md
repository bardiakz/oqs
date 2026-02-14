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
  oqs: ^3.0.1
```

## Native Library Setup

You still need a native `liboqs` library for your platform.

### Option 1: Prebuilt binaries

Use Pre-Built binaries:
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

## Library Loading Guide

`LibOQSLoader.loadLibrary()` uses fallback strategies in this exact order:

1. `explicitPath` argument
2. `LibOQSLoader.customPaths` (`LibraryPaths`)
3. Deprecated `LibOQSLoader.customPath`
4. Environment variable (`LIBOQS_PATH`, or `envVarName`)
5. `binaryRoot` extracted release layout
6. Package-relative paths
7. System loader/default name (`liboqs.so`, `oqs.dll`, `liboqs.dylib`)
8. Legacy default paths (`bin/<platform>/...`)

If all fail, `LibraryLoadException` includes all attempted strategies.

### Auto Path Selection (Package-relative)

`PackageRelativeStrategy` checks:

- `./bin/<library-file>`
- `./lib/<library-file>`
- `./lib/native/<library-file>`
- `./native/<library-file>`
- `./blobs/<library-file>`
- Android extras:
  - `./lib/arm64-v8a/liboqs.so`
  - `./lib/armeabi-v7a/liboqs.so`
  - `./lib/x86_64/liboqs.so`
  - `./lib/x86/liboqs.so`

### Platform Notes

- iOS uses `DynamicLibrary.process()` (XCFramework/static linking), not `DynamicLibrary.open(...)`.
- Android ABI-specific selection is supported through `LibraryPaths.currentPlatformPath`.
- On Linux/macOS/Windows, system resolution can work when the library is installed in standard paths.

### Recommended Config Patterns

Use explicit, deterministic config for production:

```dart
final lib = LibOQSLoader.loadLibrary(
  explicitPath: '/opt/liboqs/lib/liboqs.so',
);
```

Or per-platform config:

```dart
LibOQSLoader.customPaths = LibraryPaths(
  windows: r'C:\oqs\oqs.dll',
  linux: '/usr/local/lib/liboqs.so',
  macOS: '/opt/homebrew/lib/liboqs.dylib',
  androidArm64: '/data/local/tmp/liboqs.so',
);
```

Or extracted release root:

```dart
final lib = LibOQSLoader.loadLibrary(binaryRoot: '/opt/liboqs-0.15.0');
```

### Cache Behavior

- Loader caches resolved `DynamicLibrary` by default.
- Update paths at runtime: set `LibOQSLoader.customPaths = ...` (this clears cache).
- Manual reset: `LibOQSLoader.clearCache()`.

### Debug Checklist

1. Verify `LibOQS.getVersion()` returns non-empty string.
2. Print `LibOQS.getSupportedKEMAlgorithms()` to confirm expected build features.
3. If loading fails, inspect thrown `LibraryLoadException` strategy list and fix the earliest intended path.

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

## Migration to 3.x (`liboqs 0.15.0`)

1. Upgrade dependency in `pubspec.yaml` to `^3.0.1`.
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
