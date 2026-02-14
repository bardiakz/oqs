## 3.0.0

### Breaking Changes
- Migrated runtime behavior and tests to `liboqs` `0.15.0` bindings.
- Removed reliance on hard-coded algorithm lists for public API discovery paths.
- Updated behavior assumptions for algorithm availability and key/signature sizes; these are now resolved from the loaded `liboqs` build at runtime.

### Changed
- Switched KEM operations to stable top-level `liboqs` calls:
  - `OQS_KEM_keypair_derand`
  - `OQS_KEM_keypair`
  - `OQS_KEM_encaps`
  - `OQS_KEM_decaps`
- Switched signature operations to stable top-level `liboqs` calls:
  - `OQS_SIG_keypair`
  - `OQS_SIG_sign`
  - `OQS_SIG_verify`
- `LibOQS.getSupportedKEMAlgorithms()` and `LibOQS.getSupportedSignatureAlgorithms()` now rely on runtime enumeration from `liboqs`.

### Fixed
- Resolved FFI instability from direct struct function-pointer invocation by using exported function entry points.
- Updated tests to avoid brittle `0.14.x` assumptions (fixed algorithm names/sizes) and use capability-based selection.

### Migration Notes
- Ensure native library version is `liboqs >= 0.15.0`.
- If your app assumes specific algorithm names (e.g. only `Kyber*`/`Dilithium*`), move to runtime checks with:
  - `LibOQS.getSupportedKEMAlgorithms()`
  - `LibOQS.getSupportedSignatureAlgorithms()`
- Avoid hard-coding key/signature lengths; read them from the created `KEM`/`Signature` instance.

## 2.4.0

### Added
- Per-platform library path configuration via `LibraryPaths` class
- `LibraryPaths.fromBinaryRoot()` factory for binary release integration
- `LibraryPaths.fromExtractedArchives()` factory for separate platform archives
- `binaryRoot` parameter to `loadLibrary()` for extracted release directories
- iOS XCFramework support with `DynamicLibrary.process()` static linking
- Android ABI auto-detection from `Platform.version`
- Better error messages showing all attempted loading strategies

### Changed
- Improved library loading with more fallback strategies
- Enhanced `PackageRelativeStrategy` to check binary release structure
- Updated iOS loading to use static linking instead of dynamic library

### Deprecated
- `LibOQSLoader.customPath` - use `LibOQSLoader.customPaths` instead

### Fixed
- iOS library loading (was incorrectly trying to load `.dylib`)
- Android loading efficiency with ABI detection
- Memory safety in pointer operations with chunk-based copying

## 2.2.0

### Added
- Custom library path option via `LibOQSLoader.customPath` for more flexible loading.
