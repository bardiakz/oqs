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

## Platform Setup

### Prerequisites

You need to have the liboqs library installed on your system. Install it using:

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

#### From Source
```bash
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja install
```

### Android

For Android applications, you'll need to build liboqs for Android and include the native libraries in your app. The package supports the following architectures:

- `arm64-v8a` (64-bit ARM)
- `armeabi-v7a` (32-bit ARM)
- `x86_64` (64-bit Intel)
- `x86` (32-bit Intel)

### iOS

For iOS, you'll need to build liboqs as a framework and include it in your iOS project.

### Desktop Platforms

For Linux, macOS, and Windows, ensure the liboqs library is installed in standard system locations or set the `LIBOQS_PATH` environment variable.

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

## Development

### Development Setup

1. Fork and clone the repository
2. Install dependencies: `dart pub get`
3. Ensure liboqs is installed on your system
4. Run tests: `dart test`
5. Ensure code is formatted: `dart format .`
6. Run static analysis: `dart analyze`

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