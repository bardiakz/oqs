# Repository Guidelines

## Project Structure & Module Organization
- Core package source is in `lib/`.
  - Public API entrypoint: `lib/oqs.dart`
  - Runtime modules: `lib/src/kem.dart`, `lib/src/signature.dart`, `lib/src/random.dart`, `lib/src/oqs_base.dart`
  - Platform loading: `lib/src/platform/library_loader.dart`
  - Generated FFI bindings: `lib/src/bindings/liboqs_bindings.dart`
- Tests live in `test/` (for example `test/liboqs_test.dart`, `test/kem_deterministic_test.dart`).
- Usage samples live in `example/`.
- Package metadata/docs: `pubspec.yaml`, `README.md`, `CHANGELOG.md`.

## Build, Test, and Development Commands
- `dart pub get` - install dependencies.
- `dart test` - run all tests.
- `dart test test/liboqs_test.dart` - run a focused test file.
- `dart analyze` - static analysis and lint checks.
- `dart format lib test example` - format project code.
- `dart run ffigen` - regenerate bindings after updating liboqs headers/config.

## Coding Style & Naming Conventions
- Use 2-space indentation and keep code `dart format` clean.
- Follow Dart naming conventions:
  - `UpperCamelCase` for classes (`LibOQSBase`)
  - `lowerCamelCase` for methods/variables (`generateKeyPair`)
  - `snake_case.dart` for file names (`library_loader.dart`)
- Keep public APIs stable and prefer runtime capability checks over hard-coded algorithm assumptions.
- Do not hand-edit generated binding sections unless absolutely necessary; regenerate instead.

## Testing Guidelines
- Test framework: `package:test`.
- Add/adjust tests for any behavior change in `lib/src/*`.
- Prefer behavior/capability-based assertions (algorithm enabled, reported lengths) over fixed constants tied to one liboqs build.
- Name tests descriptively, e.g. `key generation and encapsulation for an enabled algorithm`.

## Commit & Pull Request Guidelines
- Use concise, imperative commit messages. Prefer `type: summary` style (`feat: ...`, `fix: ...`, `release: ...`).
- Avoid vague messages like `lazyCommit`.
- PRs should include:
  - clear summary of change and rationale
  - impacted files/modules
  - test/analyze results (`dart test`, `dart analyze`)
  - migration notes for breaking changes (README + CHANGELOG updates).

## Security & Configuration Tips
- This package depends on native `liboqs`; verify target binary/version compatibility.
- Never commit private keys, test secrets, or local absolute library paths.
