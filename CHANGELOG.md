## 1.0.5

### Added
- `toStrings()` method to `KEMKeyPair` class that returns publicKey and secretKey as base64 encoded strings
- `toHexStrings()` method to `KEMKeyPair` class that returns publicKey and secretKey as hexadecimal strings
- `toStrings()` method to `KEMEncapsulationResult` class that returns ciphertext and sharedSecret as base64 encoded strings
- `toHexStrings()` method to `KEMEncapsulationResult` class that returns ciphertext and sharedSecret as hexadecimal strings

### Changed
- Enhanced `KEMKeyPair` and `KEMEncapsulationResult` classes with string conversion capabilities for better debugging and serialization support