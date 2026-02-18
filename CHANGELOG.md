## 3.1.0

### Added
- Linux ARM64 (aarch64) architecture support with automatic detection
- `linuxX64` and `linuxArm64` fields in `LibraryPaths` for explicit Linux architecture configuration
- Architecture-separated binary layout support for combined all-platforms archives
- Android ABI-specific subdirectories in combined archive structure (`android/<abi>/liboqs.so`)

### Changed
- `LibraryPaths.fromBinaryRoot()` now expects architecture-separated layout:
  - `lib/x86_64/liboqs.so` for Linux x86_64
  - `lib/aarch64/liboqs.so` for Linux ARM64
  - `android/<abi>/liboqs.so` for Android binaries
- `BinaryReleaseStrategy` automatically detects Linux architecture via `uname -m`
- Combined binary archives no longer overwrite multi-architecture libraries

### Deprecated
- `linux` parameter in `LibraryPaths` constructor (use `linuxX64` instead; `linux` still works as alias)

### Fixed
- Multi-architecture Linux support (x86_64 and ARM64 no longer overwrite each other)
- Android ABI-specific loading in combined all-platforms archives
- Binary release archive structure to preserve all platform binaries

### Migration Notes
- Old `linux` parameter still works (maps to `linuxX64` automatically)
- Apps using individual platform archives are unaffected
- Apps using combined archive should re-download latest release with fixed structure
- To migrate existing code using `linux`, optionally replace with `linuxX64` for clarity

## 3.0.3

### Fixed
- Reduced pub.dev analyzer noise from generated FFI bindings by adding a `ffigen` preamble that ignores `unused_element` and `unused_field` in `lib/src/bindings/liboqs_bindings.dart`.
- Regenerated bindings so `dart pub publish --dry-run` no longer reports generated-code analyzer warnings.

## 3.0.2

### Changed
- Improved analyzer hygiene for better package quality scoring.
- Added `analysis_options.yaml` and excluded generated FFI bindings from analyzer noise.
- Updated examples to use non-deprecated loader configuration (`LibOQSLoader.customPaths` + `LibraryPaths`).
- Cleaned minor lint issues in examples/tests.

### Fixed
- `dart analyze` now reports no issues in the package source/test/example set.

## 3.0.1

### Changed
- Expanded `README.md` into a practical loading guide for `liboqs` integration.
- Documented exact dynamic library loading strategy precedence used by `LibOQSLoader`.
- Added platform-specific auto-path selection details (including Android ABI and iOS static linking behavior).
- Added cache behavior and debugging workflow for resolving load failures consistently.

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