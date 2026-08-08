import 'package:oqs/oqs.dart';

const _liboqsArchiveRoot = 'liboqs-0.16.0';

void initTestLibOQS() {
  LibOQSLoader.customPaths = LibraryPaths.fromReleaseArchive(
    _liboqsArchiveRoot,
  );
  LibOQS.init();
}

/// Picks the first available KEM algorithm from a preference list, falling
/// back to whatever the build actually reports as supported.
String pickKEMAlgorithm(List<String> algorithms) {
  const preferred = ['ML-KEM-768', 'ML-KEM-512', 'Kyber768', 'Kyber512'];
  for (final candidate in preferred) {
    if (algorithms.contains(candidate)) {
      return candidate;
    }
  }
  return algorithms.first;
}

/// Picks the first available signature algorithm from a preference list,
/// falling back to whatever the build actually reports as supported.
String pickSignatureAlgorithm(List<String> algorithms) {
  const preferred = ['ML-DSA-65', 'ML-DSA-44', 'Dilithium3', 'Dilithium2'];
  for (final candidate in preferred) {
    if (algorithms.contains(candidate)) {
      return candidate;
    }
  }
  return algorithms.first;
}
