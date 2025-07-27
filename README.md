# OQS - Post-Quantum Cryptography for Dart

[![pub package](https://img.shields.io/pub/v/oqs.svg)](https://pub.dev/packages/oqs)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D2.17.0-brightgreen.svg)](https://dart.dev)

A Dart FFI wrapper for [liboqs](https://github.com/open-quantum-safe/liboqs), providing access to post-quantum cryptographic algorithms including key encapsulation mechanisms (KEMs) and digital signatures.

## Features

- 🔐 **Key Encapsulation Mechanisms (KEMs)**: ML-KEM (Kyber), Classic McEliece, FrodoKEM, NTRU Prime, and more
- ✍️ **Digital Signatures**: ML-DSA (Dilithium), Falcon, SPHINCS+, and other post-quantum signature schemes
- 🌐 **Cross-Platform**: Support for Android, iOS, Linux, macOS, and Windows
- 🚀 **High Performance**: Direct FFI bindings with minimal overhead
- 🔧 **Flexible Loading**: Multiple library loading strategies with automatic fallbacks
- 📱 **Mobile Ready**: Optimized for Flutter applications

## Supported Algorithms

### Key Encapsulation Mechanisms (KEMs)
- ML-KEM-512, ML-KEM-768, ML-KEM-1024 (NIST standardized)
- Kyber512, Kyber768, Kyber1024 (legacy names)
- Classic McEliece variants
- FrodoKEM variants
- NTRU Prime (sntrup761)
- And more...

### Digital Signatures
- ML-DSA-44, ML-DSA-65, ML-DSA-87 (NIST standardized)
- Dilithium2, Dilithium3, Dilithium5 (legacy names)
- Falcon-512, Falcon-1024
- SPHINCS+ variants
- MAYO signatures
- Cross-Tree signatures
- And more...

## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  oqs: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

## Using Prebuilt Binaries

For convenience, some prebuilt liboqs binaries (v0.14.0) are available for common platforms. You can download them from the [liboqs-prebuilt-binaries](https://github.com/bardiakz/liboqs-prebuilt-binaries-v0.14.0) repository.

### Quick Setup with Prebuilt Binaries


**You can just place the bin directory in root of your project and you will be good to go:**
   ```
   your_project/
   ├── lib/
   ├── bin/          # Create this directory
   │   └── linux/liboqs.so # (or .dylib/.dll depending on platform)
   └── pubspec.yaml
   ```

### Library Loading Configuration

The package uses flexible library loading with automatic fallbacks:

```dart
// The package automatically tries multiple loading strategies:
// 1. Environment variable (LIBOQS_PATH)
// 2. Standard system locations (/usr/lib, /usr/local/lib, etc.)
// 3. Relative paths (./bin/, ../lib/, etc.)
// 4. Platform-specific locations

// Manual configuration (advanced users):
import 'package:oqs/src/platform/library_loader.dart';

final library = LibOQSLoader.loadLibrary(
  explicitPath: '/custom/path/to/liboqs.so',
  useCache: false,
);
```

### Verifying Installation

Test that the library loads correctly:

```dart
import 'package:oqs/oqs.dart';

void main() {
  try {
    // Initialize the library
    LibOQS.init();

    // Check version
    print('liboqs version: ${LibOQS.getVersion()}');

    // List available algorithms
    print('Available KEMs: ${LibOQS.getSupportedKEMAlgorithms().length}');
    print('Available Signatures: ${LibOQS.getSupportedSignatureAlgorithms().length}');

    print('✅ liboqs loaded successfully!');
  } catch (e) {
    print('❌ Failed to load liboqs: $e');
  }
}

## Platform Setup

### Option 1: Use Prebuilt Binaries (Recommended)

The easiest way to get started is using the prebuilt binaries. See the [Using Prebuilt Binaries](#using-prebuilt-binaries) section above for detailed instructions.

### Option 2: Install from Package Manager

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install liboqs-dev
```

#### macOS (Homebrew)
```bash
brew install liboqs
```

#### Windows (vcpkg)
```bash
vcpkg install liboqs
```
### Android

For Android applications, you'll need to build liboqs for Android and include the native libraries in your app. The package supports the following architectures:

- `arm64-v8a` (64-bit ARM)
- `armeabi-v7a` (32-bit ARM)
- `x86_64` (64-bit Intel)
- `x86` (32-bit Intel)

### iOS

For iOS, you'll need to build liboqs as a framework and include it in your iOS project.


### Option 3: Build from Source

```bash
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja install
```

### list of all KEM algorithms for creating the instance (LibOQS Version: 0.14.1-dev)
```dart
kemAlgorithms = [
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
```

### list of all Signature algorithms for creating the instance (LibOQS Version: 0.14.1-dev)
```dart
sigAlgorithms = [
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
```

### Key Encapsulation (KEM) Example

```dart
import 'package:oqs/oqs.dart';

void main() {
  // Initialize the library (optional, but recommended for performance)
  LibOQS.init();
  
  // Create KEM instance
  final kem = KEM.create('ML-KEM-768');
  if (kem == null) {
    print('Algorithm not supported');
    return;
  }
  
  try {
    // Generate a key pair
    final keyPair = kem.generateKeyPair();
    print('Public key length: ${keyPair.publicKey.length}');
    print('Secret key length: ${keyPair.secretKey.length}');
    
    // Encapsulate a shared secret
    final encapsulationResult = kem.encapsulate(keyPair.publicKey);
    print('Ciphertext length: ${encapsulationResult.ciphertext.length}');
    print('Shared secret length: ${encapsulationResult.sharedSecret.length}');
    
    // Decapsulate the shared secret
    final decapsulatedSecret = kem.decapsulate(
      encapsulationResult.ciphertext, 
      keyPair.secretKey
    );
    
    // Verify the shared secrets match
    print('Secrets match: ${_listsEqual(encapsulationResult.sharedSecret, decapsulatedSecret)}');
  } finally {
    // Clean up KEM instance
    kem.dispose();
  }
}

bool _listsEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

### Digital Signature Example

```dart
import 'package:oqs/oqs.dart';
import 'dart:convert';

void main() {
  // Initialize the library (optional, but recommended for performance)
  LibOQS.init();
  
  // Create signature instance
  final sig = Signature.create('ML-DSA-65');
  if (sig == null) {
    print('Algorithm not supported');
    return;
  }
  
  try {
    // Generate a key pair
    final keyPair = sig.generateKeyPair();
    
    // Message to sign
    final message = utf8.encode('Hello, post-quantum world!');
    
    // Sign the message
    final signature = sig.sign(message, keyPair.secretKey);
    print('Signature length: ${signature.length}');
    
    // Verify the signature
    final isValid = sig.verify(message, signature, keyPair.publicKey);
    print('Signature valid: $isValid');
  } finally {
    // Clean up signature instance
    sig.dispose();
  }
}
```

## Available Algorithms

Get lists of supported algorithms at runtime:

```dart
import 'package:oqs/oqs.dart';

void main() {
  // List all supported KEMs
  final kemAlgorithms = LibOQS.getSupportedKEMAlgorithms();
  print('Supported KEMs: $kemAlgorithms');
  
  // List all supported signature algorithms  
  final sigAlgorithms = LibOQS.getSupportedSignatureAlgorithms();
  print('Supported signatures: $sigAlgorithms');
  
  // Check if a specific algorithm is supported
  print('ML-KEM-768 supported: ${LibOQS.isKEMSupported('ML-KEM-768')}');
  print('ML-DSA-65 supported: ${LibOQS.isSignatureSupported('ML-DSA-65')}');
  
  // Print all supported algorithms
  KEM.printSupportedKemAlgorithms();
  Signature.printSupportedSignatureAlgorithms();
}
```

## Resource Management

### Basic Usage
Basic usage doesn't require explicit cleanup for most applications:

```dart
final kem = KEM.create('ML-KEM-768')!;
final keyPair = kem.generateKeyPair();
// Use KEM... automatic cleanup on app termination
kem.dispose(); // Clean up KEM instance when done
```

### Performance Optimization
For better performance, initialize once at app start:

```dart
// At app startup
LibOQS.init(); // Enables CPU optimizations and faster algorithms

// Then use normally throughout your app
final kem = KEM.create('ML-KEM-768')!;
// ...
```

### Advanced Cleanup (Optional)
For advanced scenarios like long-running servers or testing:

```dart
// Long-running server applications
LibOQS.init();
// ... use library extensively
LibOQS.cleanup(); // Clean shutdown to free OpenSSL resources

// Multithreaded applications
// On each worker thread before termination:
LibOQS.cleanupThread(); // Prevents OpenSSL thread-local storage leaks

// Complete cleanup (convenience method)
LibOQS.cleanupAll(); // Calls cleanupThread() + cleanup()
```

### Thread Safety
- All operations are thread-safe after initialization
- Call `LibOQS.cleanupThread()` on each thread before termination in multithreaded apps
- `LibOQS.init()` is safe to call multiple times
- Individual KEM/Signature instances should not be shared between threads


### Library Loading Order

The package attempts to load the liboqs library in the following order:

1. **Environment variable**: `LIBOQS_PATH` if set
2. **Prebuilt binaries**: `./bin/` directory in your project
3. **System locations**: `/usr/lib`, `/usr/local/lib`, etc.
4. **Relative paths**: `../lib/`, `./lib/`, etc.
5. **Platform-specific paths**: Windows DLL search paths, macOS framework paths

This ensures maximum compatibility across different deployment scenarios.

## Advanced Usage

### Custom Library Path

You can specify custom library loading behavior by setting environment variables:

```bash
# Set custom library path
export LIBOQS_PATH=/path/to/your/liboqs.so

# Run your Dart application
dart run your_app.dart
```

### Error Handling

```dart
import 'package:oqs/oqs.dart';

void main() {
  try {
    final kem = KEM.create('NonExistentAlgorithm');
    if (kem == null) {
      print('Algorithm not supported');
      return;
    }
    
    // Use KEM...
  } on LibOQSException catch (e) {
    print('LibOQS error: $e');
  } catch (e) {
    print('Other error: $e');
  }
}
```

## Performance Considerations

- **Initialization**: Call `LibOQS.init()` once at startup for optimal performance
- **Memory Management**: Always call `dispose()` on KEM/Signature instances when done
- **Thread Safety**: liboqs operations are thread-safe, but don't share instance objects
- **Key Reuse**: Generate fresh key pairs for each session when possible
- **Algorithm Selection**: ML-KEM and ML-DSA are NIST-standardized and recommended

## Security Notes

⚠️ **Important Security Considerations:**

- This package provides access to **post-quantum cryptographic algorithms**
- ML-KEM and ML-DSA are NIST-standardized and suitable for production use
- Other algorithms may be experimental - validate against current security recommendations
- Keep the liboqs library updated to the latest version
- Use cryptographically secure random number generators (handled automatically by liboqs)
- Properly dispose of secret key material by calling `dispose()`
- Never reuse key pairs across different sessions

## Building from Source

To build the native liboqs library yourself:

1. Clone the liboqs repository:
```bash
git clone https://github.com/open-quantum-safe/liboqs.git
```

2. Build for your target platform:
```bash
cd liboqs
mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja install
```

3. The library will be installed to `/usr/local/lib` by default.


### Contributing

Contributions are welcome! Please:
- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PRs

## Examples

Check out the [example](example/) directory for more comprehensive examples including:

- Basic KEM and signature operations
- Performance benchmarking
- Error handling patterns
- Resource management examples
- Platform-specific considerations

## Troubleshooting

### Library Loading Issues

If you encounter library loading errors:

1. **Install liboqs**: Ensure the liboqs library is installed (`liboqs-dev` package on Ubuntu)
2. **Check library path**: Verify the library is in standard locations (`/usr/lib`, `/usr/local/lib`)
3. **Set environment variable**: Use `LIBOQS_PATH` to specify custom location
4. **Verify architecture**: Ensure library matches your platform architecture
5. **Check dependencies**: Ensure OpenSSL and other dependencies are installed

### Common Error Messages

- `Failed to load liboqs library`: Library not found - install liboqs or set `LIBOQS_PATH`
- `Algorithm 'X' is not supported`: Algorithm not compiled into your liboqs build
- `Invalid key length`: Key material doesn't match expected size for algorithm
- `Failed to generate key pair`: Usually indicates library loading or initialization issues

### Getting Help

If you encounter issues:
1. Check the [troubleshooting section](#troubleshooting) above
2. Review the [examples](example/) directory
3. Search existing [GitHub issues](https://github.com/yourusername/dart-oqs/issues)
4. Open a new issue with details about your platform and error messages

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes in each version.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Open Quantum Safe](https://openquantumsafe.org/) project for liboqs
- NIST Post-Quantum Cryptography Standardization effort
- The Dart and Flutter communities

## Related Projects

- [liboqs](https://github.com/open-quantum-safe/liboqs) - The underlying C library
- [OQS-OpenSSL](https://github.com/open-quantum-safe/openssl) - OpenSSL integration
- [Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography) - NIST PQC project

---

For more information about post-quantum cryptography and the algorithms provided by this package, visit [OpenQuantumSafe.org](https://openquantumsafe.org/).