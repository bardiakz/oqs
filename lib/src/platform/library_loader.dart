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
      return DynamicLibrary.open(packagePath);
    } catch (e) {
      return null;
    }
  }

  String? _getPackageLibraryPath() {
    final currentDir = Directory.current.path;
    final fileName = _getLibraryFileName();

    // Try common package structure paths
    final possiblePaths = [
      '$currentDir/lib/native/$fileName',
      '$currentDir/native/$fileName',
      '$currentDir/blobs/$fileName',
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
        // On iOS, use process() for static linking
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

/// Strategy that loads library from platform-specific default locations.
class DefaultLocationStrategy extends LibraryLoadStrategy {
  @override
  DynamicLibrary? tryLoad() {
    try {
      if (Platform.isAndroid) {
        return _tryAndroidPaths();
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

    // Try architecture-specific paths based on your bin structure
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
  String get description => 'Default platform-specific locations';
}

/// Helper function to get the appropriate library filename for the current platform.
String _getLibraryFileName() {
  if (Platform.isWindows) {
    return 'oqs.dll';
  } else if (Platform.isLinux || Platform.isAndroid) {
    return 'liboqs.so';
  } else if (Platform.isMacOS || Platform.isIOS) {
    return 'liboqs.dylib';
  } else {
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} is not supported',
    );
  }
}

/// Main class for loading the liboqs library with multiple fallback strategies.
class LibOQSLoader {
  static DynamicLibrary? _cachedLibrary;

  /// Optional custom path to the library, set this before calling loadLibrary to use a custom path.
  static String? customPath;

  /// Loads the liboqs dynamic library using a strategy pattern with multiple fallbacks.
  ///
  /// The loading strategies are tried in the following order:
  /// 1. Explicit path (if provided)
  /// 2. Custom path (if set via LibOQSLoader.customPath)
  /// 3. Environment variable (LIBOQS_PATH)
  /// 4. Package-relative paths
  /// 5. System library locations
  /// 6. Default platform-specific locations
  ///
  /// [explicitPath] - Optional explicit path to the library
  /// [useCache] - Whether to cache the loaded library (default: true)
  /// [envVarName] - Name of environment variable to check (default: 'LIBOQS_PATH')
  ///
  /// Returns a [DynamicLibrary] instance on success.
  /// Throws [LibraryLoadException] if all strategies fail.
  static DynamicLibrary loadLibrary({
    String? explicitPath,
    bool useCache = true,
    String envVarName = 'LIBOQS_PATH',
  }) {
    // Return cached library if available and caching is enabled
    if (useCache && _cachedLibrary != null) {
      return _cachedLibrary!;
    }

    final strategies = <LibraryLoadStrategy>[
      if (explicitPath != null) ExplicitPathStrategy(explicitPath),
      if (customPath != null) ExplicitPathStrategy(customPath!),
      EnvironmentVariableStrategy(envVarName),
      PackageRelativeStrategy(),
      SystemLocationStrategy(),
      DefaultLocationStrategy(),
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
      'Attempted strategies: ${attemptedStrategies.join(', ')}',
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
