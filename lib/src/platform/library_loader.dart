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
  final String? linux;
  final String? macOS;
  final String? iOS;
  final String? androidArm64;
  final String? androidArm32;
  final String? androidX64;
  final String? androidX86;

  const LibraryPaths({
    this.windows,
    this.linux,
    this.macOS,
    this.iOS,
    this.androidArm64,
    this.androidArm32,
    this.androidX64,
    this.androidX86,
  });

  /// Get the path for the current platform.
  String? get currentPlatformPath {
    if (Platform.isWindows) return windows;
    if (Platform.isLinux) return linux;
    if (Platform.isMacOS) return macOS;
    if (Platform.isIOS) return iOS;
    if (Platform.isAndroid) {
      // Try to detect Android ABI
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

  /// Attempts to detect Android ABI.
  String? _getAndroidABI() {
    // Try to get ABI from system property
    try {
      final abiList = Platform.version.contains('arm64')
          ? 'arm64-v8a'
          : Platform.version.contains('arm')
          ? 'armeabi-v7a'
          : Platform.version.contains('x86_64')
          ? 'x86_64'
          : Platform.version.contains('x86')
          ? 'x86'
          : null;
      return abiList;
    } catch (e) {
      return null;
    }
  }

  /// Creates a LibraryPaths instance with paths following your binary release structure.
  factory LibraryPaths.fromBinaryRoot(String binaryRoot) {
    return LibraryPaths(
      windows: '$binaryRoot/bin/oqs.dll',
      linux: '$binaryRoot/lib/liboqs.so',
      macOS: '$binaryRoot/lib/liboqs.dylib',
      // iOS uses XCFramework - path handling is different
      iOS: null,
      androidArm64: '$binaryRoot/lib/liboqs.so',
      androidArm32: '$binaryRoot/lib/liboqs.so',
      androidX64: '$binaryRoot/lib/liboqs.so',
      androidX86: '$binaryRoot/lib/liboqs.so',
    );
  }

  /// Creates a LibraryPaths instance with separate extracted platform directories.
  factory LibraryPaths.fromExtractedArchives({
    String? windowsRoot,
    String? linuxRoot,
    String? macOSRoot,
    String? androidArm64Root,
    String? androidArm32Root,
    String? androidX64Root,
    String? androidX86Root,
  }) {
    return LibraryPaths(
      windows: windowsRoot != null ? '$windowsRoot/bin/oqs.dll' : null,
      linux: linuxRoot != null ? '$linuxRoot/lib/liboqs.so' : null,
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
  /// Attempts to load the library using this strategy.
  /// Returns null if this strategy cannot load the library.
  DynamicLibrary? tryLoad();

  /// Returns a description of this strategy for debugging.
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
    final path = paths.currentPlatformPath;
    if (path == null) return null;

    try {
      // Special handling for iOS
      if (Platform.isIOS) {
        // iOS uses static linking via XCFramework
        return DynamicLibrary.process();
      }
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
    final packagePath = _getPackageLibraryPath();
    if (packagePath == null) return null;

    try {
      // iOS uses static linking
      if (Platform.isIOS) {
        return DynamicLibrary.process();
      }
      return DynamicLibrary.open(packagePath);
    } catch (e) {
      return null;
    }
  }

  String? _getPackageLibraryPath() {
    final currentDir = Directory.current.path;
    final fileName = _getLibraryFileName();

    // Try package structure matching your binary releases
    final possiblePaths = [
      // Standard structure from binary release
      '$currentDir/bin/$fileName', // Windows: bin/oqs.dll
      '$currentDir/lib/$fileName', // Linux/macOS: lib/liboqs.so or lib/liboqs.dylib
      // Flutter/Dart package structures
      '$currentDir/lib/native/$fileName',
      '$currentDir/native/$fileName',
      '$currentDir/blobs/$fileName',

      // Android-specific paths
      if (Platform.isAndroid) ...[
        '$currentDir/lib/arm64-v8a/$fileName',
        '$currentDir/lib/armeabi-v7a/$fileName',
        '$currentDir/lib/x86_64/$fileName',
        '$currentDir/lib/x86/$fileName',
      ],
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }

    return null;
  }

  @override
  String get description => 'Package-relative paths';
}

/// Strategy that loads library from platform-specific system locations.
class SystemLocationStrategy extends LibraryLoadStrategy {
  @override
  DynamicLibrary? tryLoad() {
    try {
      if (Platform.isIOS) {
        // iOS uses static linking via XCFramework
        return DynamicLibrary.process();
      } else {
        // Try to load from system library paths
        return DynamicLibrary.open(_getLibraryFileName());
      }
    } catch (e) {
      return null;
    }
  }

  @override
  String get description => 'System library locations';
}

/// Strategy that loads library from downloaded binary structure.
class BinaryReleaseStrategy extends LibraryLoadStrategy {
  final String binaryRoot;

  BinaryReleaseStrategy(this.binaryRoot);

  @override
  DynamicLibrary? tryLoad() {
    try {
      if (Platform.isIOS) {
        return DynamicLibrary.process();
      }

      String path;
      if (Platform.isWindows) {
        path = '$binaryRoot/bin/oqs.dll';
      } else if (Platform.isLinux || Platform.isAndroid) {
        path = '$binaryRoot/lib/liboqs.so';
      } else if (Platform.isMacOS) {
        path = '$binaryRoot/lib/liboqs.dylib';
      } else {
        return null;
      }

      if (File(path).existsSync()) {
        return DynamicLibrary.open(path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  String get description => 'Binary release structure at: $binaryRoot';
}

/// Legacy strategy that loads library from platform-specific default locations.
/// Kept for backward compatibility with apps using the old structure.
class DefaultLocationStrategy extends LibraryLoadStrategy {
  @override
  DynamicLibrary? tryLoad() {
    try {
      if (Platform.isAndroid) {
        return _tryAndroidPaths();
      } else if (Platform.isIOS) {
        return DynamicLibrary.process();
      } else {
        final path = _getDefaultLibraryPath();
        return DynamicLibrary.open(path);
      }
    } catch (e) {
      return null;
    }
  }

  DynamicLibrary? _tryAndroidPaths() {
    final currentDir = Directory.current.path;

    // Try architecture-specific paths (legacy structure)
    final androidPaths = [
      '$currentDir/bin/android/arm64-v8a/liboqs.so',
      '$currentDir/bin/android/armeabi-v7a/liboqs.so',
      '$currentDir/bin/android/x86_64/liboqs.so',
      '$currentDir/bin/android/x86/liboqs.so',
      // Fallback to generic Android path
      'liboqs.so',
    ];

    for (final path in androidPaths) {
      try {
        if (File(path).existsSync()) {
          return DynamicLibrary.open(path);
        }
      } catch (e) {
        continue;
      }
    }

    // Final fallback - let the system resolve
    try {
      return DynamicLibrary.open('liboqs.so');
    } catch (e) {
      return null;
    }
  }

  String _getDefaultLibraryPath() {
    final currentDir = Directory.current.path;

    if (Platform.isWindows) {
      return '$currentDir/bin/windows/oqs.dll';
    } else if (Platform.isLinux) {
      return '$currentDir/bin/linux/liboqs.so';
    } else if (Platform.isMacOS) {
      return '$currentDir/bin/macos/liboqs.dylib';
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }

  @override
  String get description => 'Legacy default platform-specific locations';
}

/// Helper function to get the appropriate library filename for the current platform.
String _getLibraryFileName() {
  if (Platform.isWindows) {
    return 'oqs.dll';
  } else if (Platform.isLinux || Platform.isAndroid) {
    return 'liboqs.so';
  } else if (Platform.isMacOS) {
    return 'liboqs.dylib';
  } else if (Platform.isIOS) {
    // iOS uses static linking - no separate file
    return 'liboqs.a';
  } else {
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} is not supported',
    );
  }
}

/// Main class for loading the liboqs library with multiple fallback strategies.
class LibOQSLoader {
  static DynamicLibrary? _cachedLibrary;
  static LibraryPaths? _customPaths;

  /// Optional custom path to the library (legacy - use customPaths instead).
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
  ///   linux: '/usr/local/lib/liboqs.so',
  ///   macOS: '/usr/local/lib/liboqs.dylib',
  ///   androidArm64: '/data/local/tmp/liboqs.so',
  /// );
  /// ```
  static set customPaths(LibraryPaths? paths) {
    _customPaths = paths;
    clearCache(); // Clear cache when paths change
  }

  static LibraryPaths? get customPaths => _customPaths;

  /// Loads the liboqs dynamic library using a strategy pattern with multiple fallbacks.
  ///
  /// The loading strategies are tried in the following order:
  /// 1. Explicit path (if provided)
  /// 2. Custom paths configuration (if set via LibOQSLoader.customPaths)
  /// 3. Legacy custom path (if set via LibOQSLoader.customPath)
  /// 4. Environment variable (LIBOQS_PATH)
  /// 5. Binary release structure (if binaryRoot provided)
  /// 6. Package-relative paths
  /// 7. System library locations
  ///
  /// [explicitPath] - Optional explicit path to the library
  /// [useCache] - Whether to cache the loaded library (default: true)
  /// [envVarName] - Name of environment variable to check (default: 'LIBOQS_PATH')
  /// [binaryRoot] - Root directory of extracted binary release
  ///
  /// Returns a [DynamicLibrary] instance on success.
  /// Throws [LibraryLoadException] if all strategies fail.
  static DynamicLibrary loadLibrary({
    String? explicitPath,
    bool useCache = true,
    String envVarName = 'LIBOQS_PATH',
    String? binaryRoot,
  }) {
    // Return cached library if available and caching is enabled
    if (useCache && _cachedLibrary != null) {
      return _cachedLibrary!;
    }

    final strategies = <LibraryLoadStrategy>[
      if (explicitPath != null) ExplicitPathStrategy(explicitPath),
      if (_customPaths != null) ConfiguredPathsStrategy(_customPaths!),
      // ignore: deprecated_member_use_from_same_package
      if (customPath != null) ExplicitPathStrategy(customPath!),
      EnvironmentVariableStrategy(envVarName),
      if (binaryRoot != null) BinaryReleaseStrategy(binaryRoot),
      PackageRelativeStrategy(),
      SystemLocationStrategy(),
      DefaultLocationStrategy(), // Legacy fallback for old app structures
    ];

    DynamicLibrary? library;
    final attemptedStrategies = <String>[];

    for (final strategy in strategies) {
      attemptedStrategies.add(strategy.description);
      library = strategy.tryLoad();
      if (library != null) {
        if (useCache) {
          _cachedLibrary = library;
        }
        return library;
      }
    }

    throw LibraryLoadException(
      'Failed to load liboqs library for platform ${Platform.operatingSystem}. '
      'Attempted strategies:\n${attemptedStrategies.map((s) => '  - $s').join('\n')}',
    );
  }

  /// Clears the cached library, forcing a fresh load on next call.
  static void clearCache() {
    _cachedLibrary = null;
  }

  /// Returns whether a library is currently cached.
  static bool get hasCachedLibrary => _cachedLibrary != null;
}

/// Legacy function for backward compatibility.
@Deprecated('Use LibOQSLoader.loadLibrary() instead')
DynamicLibrary loadLibOQS() {
  return LibOQSLoader.loadLibrary();
}

/// Legacy function for backward compatibility with error handling.
@Deprecated('Use LibOQSLoader.loadLibrary() instead')
DynamicLibrary loadLibOQSWithErrorHandling() {
  return LibOQSLoader.loadLibrary();
}
