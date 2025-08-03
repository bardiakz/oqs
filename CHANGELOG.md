## 2.0.1

### Added Random Number Generation: New OQSRandom class providing cryptographically secure random number generation

- generateBytes(int length) - Generate random bytes using liboqs RNG
- generateSeed([int seedLength]) - Generate cryptographic seeds (default 32 bytes)
- generateInt(int min, int max) - Generate random integers in specified range
- switchAlgorithm(String algorithm) - Switch between RNG algorithms (system, OpenSSL, etc.)
- getAvailableAlgorithms() - List available RNG algorithms
- resetToDefault() - Reset to system RNG
