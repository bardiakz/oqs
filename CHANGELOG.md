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