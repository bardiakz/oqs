## 1.0.7

- Fix library caching issue by enabling useCache in LibOQSLoader
- Enhance memory safety in LibOQSUtils.pointerToUint8List with proper data copying
- Add Finalizer-based automatic resource cleanup for KEM and Signature instances
- Implement disposed state checking to prevent use-after-dispose crashes
- Improve error handling with enhanced LibOQSException and input validation
- Add auto-initialization to prevent initialization-related errors
- Replace nullable create() methods with exception-throwing versions for better error reporting

BREAKING CHANGES:
- KEM.create() and Signature.create() now throw LibOQSException instead of returning null on failure
- Enhanced input validation may throw ArgumentError for invalid inputs