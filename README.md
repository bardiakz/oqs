# OQS - Post-Quantum Cryptography for Dart

[![pub package](https://img.shields.io/pub/v/oqs.svg)](https://pub.dev/packages/oqs)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.8.1-brightgreen.svg)](https://dart.dev)

A Dart FFI wrapper for [liboqs](https://github.com/open-quantum-safe/liboqs), providing access to post-quantum cryptographic algorithms including key encapsulation mechanisms (KEMs), digital signatures, and cryptographically secure random number generation.

## Features

- 🔐 **Key Encapsulation Mechanisms (KEMs)**: ML-KEM (Kyber), Classic McEliece, FrodoKEM, NTRU Prime, and more
- ✍️ **Digital Signatures**: ML-DSA (Dilithium), Falcon, SPHINCS+, and other post-quantum signature schemes
- 🎲 **Cryptographically Secure Random**: Hardware-backed random number generation with algorithm switching
- 🌐 **Cross-Platform**: Support for Android, iOS, Linux, macOS, and Windows
- 🚀 **High Performance**: Direct FFI bindings with minimal overhead
- 🔧 **Flexible Loading**: Multiple library loading strategies with automatic fallbacks

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

### Random Number Generation
- System-level cryptographically secure random bytes
- Multiple RNG algorithm support (system, OpenSSL, etc.)
- Convenience functions for integers, booleans, and doubles
- Cryptographically secure list shuffling
- Seed generation for key derivation

## Using Prebuilt Binaries

For convenience, some prebuilt liboqs binaries (v0.14.0) are available for common platforms. You can download them from the [liboqs-prebuilt-binaries](https://github.com/bardiakz/liboqs-prebuilt-binaries-v0.14.0) repository.

### Quick Setup with Prebuilt Binaries

**For Dart projects you can just place the bin directory in root of your project and you will be good to go:**
   ```
   your_project/
   ├── lib/
   ├── bin/          # Create this directory
   │   └── linux/liboqs.so # (or .dylib/.dll depending on platform)
   └── pubspec.yaml
   ```
**For Android in Flutter, native libraries must be placed in the jniLibs folder to be automatically included in the APK:**
```
    android/app/src/main/jniLibs/
    ├── arm64-v8a/
    │   └── liboqs.so
    ├── armeabi-v7a/
    │   └── liboqs.so
    └── x86_64/
        └── liboqs.so
```
**For Windows just put the oqs.dll in the build directory before packing the msix**

**For Linux oqs.so can be placed in /bundle/lib before creating the AppImage**

### Library Loading Configuration

The package uses flexible library loading with automatic fallbacks:

```dart
import 'package:oqs/oqs.dart';

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

    // Test random generation
    final randomBytes = OQSRandom.generateBytes(32);
    print('Generated ${randomBytes.length} random bytes');

    print('✅ liboqs loaded successfully!');
  } catch (e) {
    print('❌ Failed to load liboqs: $e');
  }
}
```

## Quick Start

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

### Complete Algorithm Lists

#### KEM Algorithms (LibOQS Version: 0.14.1-dev)
```dart
kemAlgorithms = [
  'Classic-McEliece-348864', 'Classic-McEliece-348864f',
  'Classic-McEliece-460896', 'Classic-McEliece-460896f',
  'Classic-McEliece-6688128', 'Classic-McEliece-6688128f',
  'Classic-McEliece-6960119', 'Classic-McEliece-6960119f',
  'Classic-McEliece-8192128', 'Classic-McEliece-8192128f',
  'Kyber512', 'Kyber768', 'Kyber1024',
  'ML-KEM-512', 'ML-KEM-768', 'ML-KEM-1024',
  'sntrup761',
  'FrodoKEM-640-AES', 'FrodoKEM-640-SHAKE',
  'FrodoKEM-976-AES', 'FrodoKEM-976-SHAKE',
  'FrodoKEM-1344-AES', 'FrodoKEM-1344-SHAKE',
];
```

#### Signature Algorithms (LibOQS Version: 0.14.1-dev)
```dart
sigAlgorithms = [
  'Dilithium2', 'Dilithium3', 'Dilithium5',
  'ML-DSA-44', 'ML-DSA-65', 'ML-DSA-87',
  'Falcon-512', 'Falcon-1024', 'Falcon-padded-512', 'Falcon-padded-1024',
  'SPHINCS+-SHA2-128f-simple', 'SPHINCS+-SHA2-128s-simple',
  'SPHINCS+-SHA2-192f-simple', 'SPHINCS+-SHA2-192s-simple',
  'SPHINCS+-SHA2-256f-simple', 'SPHINCS+-SHA2-256s-simple',
  'SPHINCS+-SHAKE-128f-simple', 'SPHINCS+-SHAKE-128s-simple',
  'SPHINCS+-SHAKE-192f-simple', 'SPHINCS+-SHAKE-192s-simple',
  'SPHINCS+-SHAKE-256f-simple', 'SPHINCS+-SHAKE-256s-simple',
  'MAYO-1', 'MAYO-2', 'MAYO-3', 'MAYO-5',
  // Cross-Tree variants
  'cross-rsdp-128-balanced', 'cross-rsdp-128-fast', 'cross-rsdp-128-small',
  'cross-rsdp-192-balanced', 'cross-rsdp-192-fast', 'cross-rsdp-192-small',
  'cross-rsdp-256-balanced', 'cross-rsdp-256-fast', 'cross-rsdp-256-small',
  // And many more SNOVA and OV variants...
];
```

## Resource Management

### Basic Usage
Basic usage doesn't require explicit cleanup for most applications:

```dart
import 'package:oqs/oqs.dart';

void main() {
  final kem = KEM.create('ML-KEM-768')!;
  final keyPair = kem.generateKeyPair();
  // Use KEM... automatic cleanup on app termination
  kem.dispose(); // Clean up KEM instance when done
}
```

### Performance Optimization
For better performance, initialize once at app start:

```dart
import 'package:oqs/oqs.dart';

void main() {
  // At app startup
  LibOQS.init(); // Enables CPU optimizations and faster algorithms

  // Then use normally throughout your app
  final kem = KEM.create('ML-KEM-768')!;
  // ...
}
```

### Advanced Cleanup (Optional)
For advanced scenarios like long-running servers or testing:

```dart
import 'package:oqs/oqs.dart';

void main() {
  // Long-running server applications
  LibOQS.init();
  // ... use library extensively
  LibOQS.cleanup(); // Clean shutdown to free OpenSSL resources

  // Multithreaded applications
  // On each worker thread before termination:
  LibOQS.cleanupThread(); // Prevents OpenSSL thread-local storage leaks

  // Complete cleanup (convenience method)
  LibOQS.cleanupAll(); // Calls cleanupThread() + cleanup()
}
```

### Thread Safety
- All operations are thread-safe after initialization
- Call `LibOQS.cleanupThread()` on each thread before termination in multithreaded apps
- `LibOQS.init()` is safe to call multiple times
- Individual KEM/Signature instances should not be shared between threads

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

### Option 3: Build from Source

```bash
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja install
```

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

## Complete Working Examples

### Full Random Generation Example

```dart
import 'package:oqs/oqs.dart';

void randomExample() {
  print('=== Random Generation Example ===');
  
  try {
    // Basic random generation
    print('\n1. Basic Random Generation:');
    final randomBytes = OQSRandom.generateBytes(32);
    print('   32 random bytes: ${_bytesToHex(randomBytes.take(16).toList())}...');
    
    final seed = OQSRandom.generateSeed();
    print('   Crypto seed (32 bytes): ${_bytesToHex(seed.take(8).toList())}...');
    
    // Random numbers and booleans
    print('\n2. Random Numbers:');
    final randomInts = List.generate(5, (_) => OQSRandom.generateInt(1, 100));
    print('   Random integers (1-99): $randomInts');
    
    final randomBools = List.generate(8, (_) => OQSRandomExtensions.generateBool());
    print('   Random booleans: $randomBools');
    
    final randomDoubles = List.generate(3, (_) => OQSRandomExtensions.generateDouble());
    print('   Random doubles: ${randomDoubles.map((d) => d.toStringAsFixed(4)).toList()}');
    
    // Cryptographic shuffling
    print('\n3. Cryptographic Shuffling:');
    final testList = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve'];
    print('   Original: $testList');
    OQSRandomExtensions.shuffleList(testList);
    print('   Shuffled: $testList');
    
    // RNG algorithms
    print('\n4. RNG Algorithms:');
    final algorithms = OQSRandom.getAvailableAlgorithms();
    print('   Available: $algorithms');
    
    final systemSupported = OQSRandom.isAlgorithmLikelySupported('system');
    print('   System RNG supported: $systemSupported');
    
  } catch (e) {
    print('Error: $e');
  }
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}

void main() {
  LibOQS.init();
  randomExample();
}
```

### Full KEM Example with Error Handling

```dart
import 'package:oqs/oqs.dart';
import 'dart:typed_data';

void kemExample() {
  print('=== KEM Example ===');
  
  try {
    // Initialize library
    LibOQS.init();
    
    // Create KEM instance
    final kem = KEM.create('ML-KEM-768');
    if (kem == null) {
      print('ML-KEM-768 not supported');
      return;
    }
    
    print('Algorithm: ${kem.algorithmName}');
    print('Public key length: ${kem.publicKeyLength}');
    print('Secret key length: ${kem.secretKeyLength}');
    print('Ciphertext length: ${kem.ciphertextLength}');
    print('Shared secret length: ${kem.sharedSecretLength}');
    
    // Generate key pair
    final keyPair = kem.generateKeyPair();
    print('\n✓ Key pair generated');
    
    // Alice encapsulates
    final encResult = kem.encapsulate(keyPair.publicKey);
    print('✓ Secret encapsulated');
    
    // Bob decapsulates
    final bobSecret = kem.decapsulate(encResult.ciphertext, keyPair.secretKey);
    print('✓ Secret decapsulated');
    
    // Verify secrets match
    bool secretsMatch = true;
    if (encResult.sharedSecret.length != bobSecret.length) {
      secretsMatch = false;
    } else {
      for (int i = 0; i < encResult.sharedSecret.length; i++) {
        if (encResult.sharedSecret[i] != bobSecret[i]) {
          secretsMatch = false;
          break;
        }
      }
    }
    
    print('✓ Secrets match: $secretsMatch');
    
    // Demonstrate using random data
    final randomSalt = OQSRandom.generateBytes(16);
    print('✓ Generated random salt: ${randomSalt.length} bytes');
    
    // Clean up
    kem.dispose();
    
  } catch (e) {
    print('Error: $e');
  }
}

void main() {
  kemExample();
}
```

### Full Signature Example with Error Handling

```dart
import 'package:oqs/oqs.dart';
import 'dart:convert';

void signatureExample() {
  print('=== Signature Example ===');
  
  try {
    // Initialize library
    LibOQS.init();
    
    // Create signature instance
    final sig = Signature.create('ML-DSA-65');
    
    print('Algorithm: ${sig.algorithmName}');
    print('Public key length: ${sig.publicKeyLength}');
    print('Secret key length: ${sig.secretKeyLength}');
    print('Max signature length: ${sig.maxSignatureLength}');
    
    // Generate key pair
    final keyPair = sig.generateKeyPair();
    print('\n✓ Key pair generated');
    
    // Message to sign
    final message = utf8.encode('Hello, post-quantum cryptography!');
    print('Message: "${utf8.decode(message)}"');
    
    // Sign message
    final signature = sig.sign(message, keyPair.secretKey);
    print('✓ Message signed (signature length: ${signature.length})');
    
    // Verify signature
    final isValid = sig.verify(message, signature, keyPair.publicKey);
    print('✓ Signature valid: $isValid');
    
    // Test with wrong message
    final wrongMessage = utf8.encode('Wrong message');
    final isInvalid = sig.verify(wrongMessage, signature, keyPair.publicKey);
    print('✓ Wrong message verification: $isInvalid (should be false)');
    
    // Demonstrate with random message
    final randomMessage = OQSRandom.generateBytes(64);
    final randomSignature = sig.sign(randomMessage, keyPair.secretKey);
    final randomValid = sig.verify(randomMessage, randomSignature, keyPair.publicKey);
    print('✓ Random message signature valid: $randomValid');
    
    // Clean up
    sig.dispose();
    
  } catch (e) {
    print('Error: $e');
  }
}

void main() {
  signatureExample();
}
```

## Performance Considerations

- **Initialization**: Call `LibOQS.init()` once at startup for optimal performance
- **Memory Management**: Always call `dispose()` on KEM/Signature instances when done
- **Thread Safety**: liboqs operations are thread-safe, but don't share instance objects
- **Key Reuse**: Generate fresh key pairs for each session when possible
- **Algorithm Selection**: ML-KEM and ML-DSA are NIST-standardized and recommended
- **Random Generation**: `OQSRandom` uses hardware-backed sources when available

## Security Notes

⚠️ **Important Security Considerations:**

- ML-KEM and ML-DSA are NIST-standardized and suitable for production use
- Other algorithms may be experimental - validate against current security recommendations
- Keep the liboqs library updated to the latest version
- Properly dispose of secret key material by calling `dispose()`
- The random number generator uses cryptographically secure sources
- Be cautious when switching RNG algorithms - stick with 'system' for most use cases
- Use `OQSRandom.generateSeed()` for cryptographic key derivation

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
- `Failed to generate random bytes`: RNG initialization failed - check library installation

### Getting Help

If you encounter issues:
1. Check the [troubleshooting section](#troubleshooting) above
2. Review the [examples](example/) directory
3. Search existing [GitHub issues](https://github.com/bardiakz/oqs/issues)
4. Open a new issue with details about your platform and error messages

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [liboqs](https://github.com/open-quantum-safe/liboqs) - The underlying C library
- [OQS-OpenSSL](https://github.com/open-quantum-safe/openssl) - OpenSSL integration
- [Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography) - NIST PQC project

---

For more information about post-quantum cryptography and the algorithms provided by this package, visit [OpenQuantumSafe.org](https://openquantumsafe.org/)