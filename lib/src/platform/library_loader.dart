import 'dart:ffi';
import 'dart:io';

/// Exception thrown when the liboqs library cannot be loaded.
class LibraryLoadException implements Exception {
  final String message;
  final dynamic cause;

  const LibraryLoadException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'LibraryLoadException: $message\nCaused by: $cause';
    }
    return 'LibraryLoadException: $message';
  }
}

/// Configuration class for platform-specific library paths.
class LibraryPaths {
  final String? windows;
  final String? linuxX64;
  final String? linuxArm64;
  final String? macOS;
  final String? iOS;
  final String? androidArm64;
  final String? androidArm32;
  final String? androidX64;
  final String? androidX86;

  const LibraryPaths({
    this.windows,
    // 'linux' accepted for backward compatibility, maps to linuxX64
    String? linux,
    String? linuxX64,
    this.linuxArm64,
    this.macOS,
    this.iOS,
    this.androidArm64,
    this.androidArm32,
    this.androidX64,
    this.androidX86,
  }) : linuxX64 = linuxX64 ?? linux;

  /// Get the path for the current platform and architecture.
  String? get currentPlatformPath {
    if (Platform.isWindows) return windows;
    if (Platform.isLinux) {
      final arch = _getLinuxArch();
      if (arch == 'aarch64' || arch == 'arm64') {
        return linuxArm64 ?? linuxX64; // fall back to x64 if arm64 not set
      }
      return linuxX64;
    }
    if (Platform.isMacOS) return macOS;
    if (Platform.isIOS) return iOS;
    if (Platform.isAndroid) {
      final abi = _getAndroidABI();
      switch (abi) {
        case 'arm64-v8a':
          return androidArm64;
        case 'armeabi-v7a':
          return androidArm32;
        case 'x86_64':
          return androidX64;
        case 'x86':
          return androidX86;
        default:
          return androidArm64 ?? androidArm32 ?? androidX64 ?? androidX86;
      }
    }
    return null;
  }

  /// Detects Linux CPU architecture via `uname -m`.
  String? _getLinuxArch() {
    try {
      final result = Process.runSync('uname', ['-m']);
      return result.stdout.toString().trim();
    } catch (e) {
      return Platform.environment['HOSTTYPE'];
    }
  }

  /// Attempts to detect Android ABI from Platform.version.
  String? _getAndroidABI() {
    try {
      final v = Platform.version;
      if (v.contains('arm64')) return 'arm64-v8a';
      if (v.contains('arm')) return 'armeabi-v7a';
      if (v.contains('x86_64')) return 'x86_64';
      if (v.contains('x86')) return 'x86';
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Creates a LibraryPaths from an extracted all-platforms archive.
  ///
  /// Expects the arch-separated layout produced by the build workflow:
  /// ```
  /// binaryRoot/
  ///   lib/
  ///     x86_64/liboqs.so        ← Linux x86_64
  ///     aarch64/liboqs.so       ← Linux ARM64
  ///     liboqs.dylib            ← macOS
  ///   bin/
  ///     oqs.dll                 ← Windows
  ///   liboqs.xcframework/       ← iOS (static, loaded via process())
  /// ```
  factory LibraryPaths.fromBinaryRoot(String binaryRoot) {
    return LibraryPaths(
      windows: '$binaryRoot/bin/oqs.dll',
      linuxX64: '$binaryRoot/lib/x86_64/liboqs.so',
      linuxArm64: '$binaryRoot/lib/aarch64/liboqs.so',
      macOS: '$binaryRoot/lib/liboqs.dylib',
      iOS: null, // iOS uses DynamicLibrary.process() via XCFramework
      androidArm64: '$binaryRoot/lib/liboqs.so',
      androidArm32: '$binaryRoot/lib/liboqs.so',
      androidX64: '$binaryRoot/lib/liboqs.so',
      androidX86: '$binaryRoot/lib/liboqs.so',
    );
  }

  /// Creates a LibraryPaths from separately extracted platform archives.
  factory LibraryPaths.fromExtractedArchives({
    String? windowsRoot,
    String? linuxX64Root,
    String? linuxArm64Root,
    String? macOSRoot,
    String? androidArm64Root,
    String? androidArm32Root,
    String? androidX64Root,
    String? androidX86Root,
  }) {
    return LibraryPaths(
      windows: windowsRoot != null ? '$windowsRoot/bin/oqs.dll' : null,
      linuxX64: linuxX64Root != null ? '$linuxX64Root/lib/liboqs.so' : null,
      linuxArm64: linuxArm64Root != null
          ? '$linuxArm64Root/lib/liboqs.so'
          : null,
      macOS: macOSRoot != null ? '$macOSRoot/lib/liboqs.dylib' : null,
      androidArm64: androidArm64Root != null
          ? '$androidArm64Root/lib/liboqs.so'
          : null,
      androidArm32: androidArm32Root != null
          ? '$androidArm32Root/lib/liboqs.so'
          : null,
      androidX64: androidX64Root != null
          ? '$androidX64Root/lib/liboqs.so'
          : null,
      androidX86: androidX86Root != null
          ? '$androidX86Root/lib/liboqs.so'
          : null,
    );
  }
}

/// Abstract base class for different library loading strategies.
abstract class LibraryLoadStrategy {
  DynamicLibrary? tryLoad();
  String get description;
}

/// Strategy that loads library from an explicitly provided path.
class ExplicitPathStrategy extends LibraryLoadStrategy {
  final String path;
  ExplicitPathStrategy(this.path);

  @override
  DynamicLibrary? tryLoad() {
    try {
      return DynamicLibrary.open(path);
    } catch (e) {
      return null;
    }
  }

  @override
  String get description => 'Explicit path: $path';
}

/// Strategy that loads library from LibraryPaths configuration.
class ConfiguredPathsStrategy extends LibraryLoadStrategy {
  final LibraryPaths paths;
  ConfiguredPathsStrategy(this.paths);

  @override
  DynamicLibrary? tryLoad() {
    if (Platform.isIOS) return DynamicLibrary.process();

    final path = paths.currentPlatformPath;
    if (path == null) return null;

    try {
      return DynamicLibrary.open(path);
    } catch (e) {
      return null;
    }
  }

  @override
  String get description => 'Configured paths for current platform';
}

/// Strategy that loads library from environment variable.
class EnvironmentVariableStrategy extends LibraryLoadStrategy {
  final String envVarName;
  EnvironmentVariableStrategy([this.envVarName = 'LIBOQS_PATH']);

  @override
  DynamicLibrary? tryLoad() {
    final envPath = Platform.environment[envVarName];
    if (envPath == null || envPath.isEmpty) return null;
    try {
      return DynamicLibrary.open(envPath);
    } catch (e) {
      return null;
    }
  }

  @override
  String get description => 'Environment variable: $envVarName';
}

/// Strategy that loads library from package-relative paths.
class PackageRelativeStrategy extends LibraryLoadStrategy {
  @override
  DynamicLibrary? tryLoad() {
    if (Platform.isIOS) return DynamicLibrary.process();

    final path = _getPackageLibraryPath();
    if (path == null) return null;
    try {
      return DynamicLibrary.open(path);
    } catch (e) {
      return null;
    }
  }

  String? _getPackageLibraryPath() {
    final currentDir = Directory.current.path;
    final fileName = _getLibraryFileName();

    final possiblePaths = [
      '$currentDir/bin/$fileName',
      '$currentDir/lib/$fileName',
      '$currentDir/lib/native/$fileName',
      '$currentDir/native/$fileName',
      '$currentDir/blobs/$fileName',
      if (Platform.isAndroid) ...[
        '$currentDir/lib/arm64-v8a/$fileName',
        '$currentDir/lib/armeabi-v7a/$fileName',
        '$currentDir/lib/x86_64/$fileName',
        '$currentDir/lib/x86/$fileName',
      ],
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  @override
  String get description => 'Package-relative paths';
}

/// Strategy that loads library from platform system locations.
class SystemLocationStrategy extends LibraryLoadStrategy {
  @override
  DynamicLibrary? tryLoad() {
    try {
      if (Platform.isIOS) return DynamicLibrary.process();
      return DynamicLibrary.open(_getLibraryFileName());
    } catch (e) {
      return null;
    }
  }

  @override
  String get description => 'System library locations';
}

/// Strategy that loads library from an extracted binary release directory.
class BinaryReleaseStrategy extends LibraryLoadStrategy {
  final String binaryRoot;
  BinaryReleaseStrategy(this.binaryRoot);

  @override
  DynamicLibrary? tryLoad() {
    try {
      if (Platform.isIOS) return DynamicLibrary.process();

      String path;
      if (Platform.isWindows) {
        path = '$binaryRoot/bin/oqs.dll';
      } else if (Platform.isLinux) {
        // Use arch-separated paths
        final arch = _getLinuxArch();
        if (arch == 'aarch64' || arch == 'arm64') {
          path = '$binaryRoot/lib/aarch64/liboqs.so';
        } else {
          path = '$binaryRoot/lib/x86_64/liboqs.so';
        }
      } else if (Platform.isAndroid) {
        path = '$binaryRoot/lib/liboqs.so';
      } else if (Platform.isMacOS) {
        path = '$binaryRoot/lib/liboqs.dylib';
      } else {
        return null;
      }

      if (File(path).existsSync()) return DynamicLibrary.open(path);
      return null;
    } catch (e) {
      return null;
    }
  }

  String? _getLinuxArch() {
    try {
      final result = Process.runSync('uname', ['-m']);
      return result.stdout.toString().trim();
    } catch (e) {
      return Platform.environment['HOSTTYPE'];
    }
  }

  @override
  String get description => 'Binary release structure at: $binaryRoot';
}

/// Legacy strategy for backward compatibility with old project structures.
class DefaultLocationStrategy extends LibraryLoadStrategy {
  @override
  DynamicLibrary? tryLoad() {
    try {
      if (Platform.isAndroid) return _tryAndroidPaths();
      if (Platform.isIOS) return DynamicLibrary.process();
      return DynamicLibrary.open(_getDefaultLibraryPath());
    } catch (e) {
      return null;
    }
  }

  DynamicLibrary? _tryAndroidPaths() {
    final currentDir = Directory.current.path;
    final paths = [
      '$currentDir/bin/android/arm64-v8a/liboqs.so',
      '$currentDir/bin/android/armeabi-v7a/liboqs.so',
      '$currentDir/bin/android/x86_64/liboqs.so',
      '$currentDir/bin/android/x86/liboqs.so',
    ];
    for (final path in paths) {
      try {
        if (File(path).existsSync()) return DynamicLibrary.open(path);
      } catch (e) {
        continue;
      }
    }
    try {
      return DynamicLibrary.open('liboqs.so');
    } catch (e) {
      return null;
    }
  }

  String _getDefaultLibraryPath() {
    final currentDir = Directory.current.path;
    if (Platform.isWindows) return '$currentDir/bin/windows/oqs.dll';
    if (Platform.isLinux) return '$currentDir/bin/linux/liboqs.so';
    if (Platform.isMacOS) return '$currentDir/bin/macos/liboqs.dylib';
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} is not supported',
    );
  }

  @override
  String get description => 'Legacy default platform-specific locations';
}

/// Returns the library filename for the current platform.
String _getLibraryFileName() {
  if (Platform.isWindows) return 'oqs.dll';
  if (Platform.isLinux || Platform.isAndroid) return 'liboqs.so';
  if (Platform.isMacOS) return 'liboqs.dylib';
  if (Platform.isIOS) return 'liboqs.a';
  throw UnsupportedError(
    'Platform ${Platform.operatingSystem} is not supported',
  );
}

/// Main class for loading the liboqs library with multiple fallback strategies.
class LibOQSLoader {
  static DynamicLibrary? _cachedLibrary;
  static LibraryPaths? _customPaths;

  /// Deprecated: use [customPaths] instead.
  @Deprecated(
    'Use LibOQSLoader.customPaths instead for better platform support',
  )
  static String? customPath;

  /// Configure platform-specific library paths.
  ///
  /// Example:
  /// ```dart
  /// LibOQSLoader.customPaths = LibraryPaths(
  ///   windows: 'C:/libs/oqs.dll',
  ///   linux: '/usr/local/lib/liboqs.so',       // x86_64
  ///   linuxArm64: '/usr/local/lib/liboqs.so',  // aarch64
  ///   macOS: '/usr/local/lib/liboqs.dylib',
  /// );
  /// ```
  static set customPaths(LibraryPaths? paths) {
    _customPaths = paths;
    clearCache();
  }

  static LibraryPaths? get customPaths => _customPaths;

  /// Loads the liboqs dynamic library using multiple fallback strategies:
  ///
  /// 1. [explicitPath] argument
  /// 2. [customPaths] (`LibraryPaths`)
  /// 3. Deprecated [customPath]
  /// 4. Environment variable (`LIBOQS_PATH` or [envVarName])
  /// 5. [binaryRoot] extracted release layout
  /// 6. Package-relative paths
  /// 7. System loader default name
  /// 8. Legacy paths (backward compat)
  ///
  /// Throws [LibraryLoadException] if all strategies fail.
  static DynamicLibrary loadLibrary({
    String? explicitPath,
    bool useCache = true,
    String envVarName = 'LIBOQS_PATH',
    String? binaryRoot,
  }) {
    if (useCache && _cachedLibrary != null) return _cachedLibrary!;

    final strategies = <LibraryLoadStrategy>[
      if (explicitPath != null) ExplicitPathStrategy(explicitPath),
      if (_customPaths != null) ConfiguredPathsStrategy(_customPaths!),
      // ignore: deprecated_member_use_from_same_package
      if (customPath != null) ExplicitPathStrategy(customPath!),
      EnvironmentVariableStrategy(envVarName),
      if (binaryRoot != null) BinaryReleaseStrategy(binaryRoot),
      PackageRelativeStrategy(),
      SystemLocationStrategy(),
      DefaultLocationStrategy(),
    ];

    final attemptedStrategies = <String>[];
    for (final strategy in strategies) {
      attemptedStrategies.add(strategy.description);
      final library = strategy.tryLoad();
      if (library != null) {
        if (useCache) _cachedLibrary = library;
        return library;
      }
    }

    throw LibraryLoadException(
      'Failed to load liboqs library for platform ${Platform.operatingSystem}.\n'
      'Attempted strategies:\n'
      '${attemptedStrategies.map((s) => '  - $s').join('\n')}',
    );
  }

  /// Clears the cached library, forcing a fresh load on next call.
  static void clearCache() => _cachedLibrary = null;

  /// Returns whether a library is currently cached.
  static bool get hasCachedLibrary => _cachedLibrary != null;
}

/// Legacy function for backward compatibility.
@Deprecated('Use LibOQSLoader.loadLibrary() instead')
DynamicLibrary loadLibOQS() => LibOQSLoader.loadLibrary();

/// Legacy function for backward compatibility.
@Deprecated('Use LibOQSLoader.loadLibrary() instead')
DynamicLibrary loadLibOQSWithErrorHandling() => LibOQSLoader.loadLibrary();
