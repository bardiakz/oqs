# OQS - Post-Quantum Cryptography for Dart

[![pub package](https://img.shields.io/pub/v/oqs.svg)](https://pub.dev/packages/oqs)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Dart bindings for [liboqs](https://github.com/open-quantum-safe/liboqs) - quantum-resistant cryptography.

## What You Get

- **Key Exchange (KEM)**: ML-KEM (Kyber), FrodoKEM, Classic McEliece, NTRU Prime
- **Digital Signatures**: ML-DSA (Dilithium), Falcon, SPHINCS+, MAYO
- **Secure Random**: Hardware-backed cryptographic RNG
- **Cross-Platform**: Android, iOS, Linux, macOS, Windows

## Quick Start

### 1. Add Dependency

```yaml
dependencies:
  oqs: ^1.0.0
```

### 2. Get liboqs Binaries

Download pre-built binaries from [liboqs-binaries releases](https://github.com/YOUR_USERNAME/liboqs-binaries/releases).

**Extract and place files:**

```
# Dart/Flutter project
your_project/
├── bin/
│   ├── oqs.dll           # Windows
│   └── linux/liboqs.so   # Linux
├── lib/liboqs.dylib      # macOS
└── pubspec.yaml

# Flutter Android (jniLibs)
android/app/src/main/jniLibs/
├── arm64-v8a/liboqs.so
├── armeabi-v7a/liboqs.so
└── x86_64/liboqs.so

# Flutter iOS
# Drag liboqs.xcframework into Xcode project
```

**Or configure manually:**

```dart
import 'package:oqs/oqs.dart';

LibOQSLoader.customPaths = LibraryPaths(
  windows: 'C:/libs/oqs.dll',
  linux: '/usr/local/lib/liboqs.so',
  macOS: '/opt/homebrew/lib/liboqs.dylib',
);
```

### 3. Use It

**Key Exchange:**

```dart
import 'package:oqs/oqs.dart';

void main() {
  // Create KEM instance
  final kem = KEM.create('ML-KEM-768')!;
  
  // Alice generates keys
  final keyPair = kem.generateKeyPair();
  
  // Bob encapsulates
  final result = kem.encapsulate(keyPair.publicKey);
  
  // Alice decapsulates
  final aliceSecret = kem.decapsulate(result.ciphertext, keyPair.secretKey);
  
  // Secrets match!
  print(aliceSecret == result.sharedSecret); // true
  
  kem.dispose();
}
```

**Digital Signatures:**

```dart
import 'dart:convert';
import 'package:oqs/oqs.dart';

void main() {
  final sig = Signature.create('ML-DSA-65');
  
  // Generate keys
  final keys = sig.generateKeyPair();
  
  // Sign
  final message = utf8.encode('Hello quantum world');
  final signature = sig.sign(message, keys.secretKey);
  
  // Verify
  final valid = sig.verify(message, signature, keys.publicKey);
  print(valid); // true
  
  sig.dispose();
}
```

**Random Generation:**

```dart
import 'package:oqs/oqs.dart';

void main() {
  // Generate random bytes
  final bytes = OQSRandom.generateBytes(32);
  
  // Generate seed for key derivation
  final seed = OQSRandom.generateSeed();
  
  // Random integers
  final dice = OQSRandom.generateInt(1, 7); // 1-6
  
  // Cryptographically shuffle
  final deck = [1, 2, 3, 4, 5];
  OQSRandomExtensions.shuffleList(deck);
}
```

## API Reference

### KEM (Key Exchange)

```dart
// Create
final kem = KEM.create('ML-KEM-768')!;

// Properties
kem.algorithmName         // "ML-KEM-768"
kem.publicKeyLength       // 1184
kem.secretKeyLength       // 2400
kem.ciphertextLength      // 1088
kem.sharedSecretLength    // 32

// Operations
final keyPair = kem.generateKeyPair();
final result = kem.encapsulate(publicKey);
final secret = kem.decapsulate(ciphertext, secretKey);

// Cleanup
kem.dispose();
```

### Signature

```dart
// Create
final sig = Signature.create('ML-DSA-65');

// Properties
sig.algorithmName         // "ML-DSA-65"
sig.publicKeyLength       // 1952
sig.secretKeyLength       // 4032
sig.maxSignatureLength    // 3309

// Operations
final keyPair = sig.generateKeyPair();
final signature = sig.sign(message, secretKey);
final valid = sig.verify(message, signature, publicKey);

// Cleanup
sig.dispose();
```

### Random

```dart
// Bytes
OQSRandom.generateBytes(32);
OQSRandom.generateSeed();

// Numbers
OQSRandom.generateInt(1, 100);
OQSRandomExtensions.generateBool();
OQSRandomExtensions.generateDouble();

// Utilities
OQSRandomExtensions.shuffleList(myList);
```

### Discovery

```dart
// List supported algorithms
final kems = LibOQS.getSupportedKEMAlgorithms();
final sigs = LibOQS.getSupportedSignatureAlgorithms();

// Check support
LibOQS.isKEMSupported('ML-KEM-768');       // true
LibOQS.isSignatureSupported('ML-DSA-65');  // true

// Version
LibOQS.getVersion(); // "0.15.0"
```

## Algorithms

<details>
<summary><b>Key Exchange (KEM)</b></summary>

**NIST Standardized:**
- `ML-KEM-512`, `ML-KEM-768`, `ML-KEM-1024` ⭐ (recommended)

**Legacy Names:**
- `Kyber512`, `Kyber768`, `Kyber1024`

**Others:**
- Classic McEliece (10 variants)
- FrodoKEM (6 variants)
- `sntrup761`
</details>

<details>
<summary><b>Digital Signatures</b></summary>

**NIST Standardized:**
- `ML-DSA-44`, `ML-DSA-65`, `ML-DSA-87` ⭐ (recommended)

**Legacy Names:**
- `Dilithium2`, `Dilithium3`, `Dilithium5`

**Others:**
- Falcon (4 variants)
- SPHINCS+ (12 variants)
- MAYO (4 variants)
- Cross-Tree (9 variants)
- SNOVA (14 variants)
- OV (12 variants)
</details>

## Platform Setup

### Option 1: Pre-built Binaries (Easiest)

Download from [releases](https://github.com/YOUR_USERNAME/liboqs-binaries/releases) and place in your project.

### Option 2: System Install

**Ubuntu/Debian:**
```bash
sudo apt install liboqs-dev
```

**macOS:**
```bash
brew install liboqs
```

**Windows:**
```bash
vcpkg install liboqs
```

### Option 3: Build from Source

```bash
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs && mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja install
```

## Advanced

### Library Loading

The package tries multiple strategies automatically:

1. Explicit path (if provided)
2. Platform-specific custom paths
3. Environment variable (`LIBOQS_PATH`)
4. Project directories (`bin/`, `lib/`)
5. System locations (`/usr/lib`, `/usr/local/lib`)

**Manual configuration:**

```dart
// Per-platform paths
LibOQSLoader.customPaths = LibraryPaths(
  windows: 'C:/libs/oqs.dll',
  linux: '/usr/local/lib/liboqs.so',
  macOS: '/usr/local/lib/liboqs.dylib',
  androidArm64: '/data/app/libs/liboqs.so',
);

// From extracted binary release
LibOQSLoader.customPaths = LibraryPaths.fromBinaryRoot(
  '/path/to/liboqs-0.15.0'
);

// Single explicit path
final lib = LibOQSLoader.loadLibrary(
  explicitPath: '/custom/path/liboqs.so'
);
```

### Performance

```dart
// Initialize once at app startup
void main() {
  LibOQS.init(); // Enables optimizations
  runApp(MyApp());
}

// Always dispose when done
final kem = KEM.create('ML-KEM-768')!;
// ... use kem ...
kem.dispose(); // Free resources
```

### Thread Safety

```dart
// Safe: Each thread can use library independently
// Just call LibOQS.init() once globally

// Long-running server cleanup
void shutdown() {
  LibOQS.cleanup(); // Clean OpenSSL resources
}
```

## Troubleshooting

**Library not found:**
```dart
// Set environment variable
export LIBOQS_PATH=/path/to/liboqs.so

// Or configure paths
LibOQSLoader.customPaths = LibraryPaths(
  linux: '/usr/local/lib/liboqs.so',
);
```

**Algorithm not supported:**
```dart
// Check if enabled
if (!LibOQS.isKEMSupported('ML-KEM-768')) {
  print('Not available in this build');
}

// List what's available
print(LibOQS.getSupportedKEMAlgorithms());
```

**Invalid key length:**
```dart
// Get expected sizes first
final kem = KEM.create('ML-KEM-768')!;
print('Public key: ${kem.publicKeyLength}');
print('Secret key: ${kem.secretKeyLength}');
```

## Security Notes

⚠️ **Important:**
- Use `ML-KEM` and `ML-DSA` for production (NIST standardized)
- Keep liboqs updated
- Always call `dispose()` on KEM/Signature instances
- Don't share instance objects between threads
- Use `OQSRandom.generateSeed()` for key derivation

## Examples

See [example/](example/) directory for complete working examples.

## Links

- [liboqs](https://github.com/open-quantum-safe/liboqs) - C library
- [Open Quantum Safe](https://openquantumsafe.org/) - Project homepage
- [NIST PQC](https://csrc.nist.gov/projects/post-quantum-cryptography) - Standardization

## License

MIT License - see [LICENSE](LICENSE) file.

---

**Need help?** [Open an issue](https://github.com/bardiakz/oqs/issues)