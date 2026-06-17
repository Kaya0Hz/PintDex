# Changelog

## [0.1.1] — 2026-06-16

### Fixed
- `DropdownButtonFormField` compatibility with Flutter 3.27 (`initialValue` → `value`)
- Android NDK pinned to 27.0.12077973 for plugin compatibility
- Dart SDK constraint lowered to `^3.6.0` for local toolchain compat
- `flutter_lints` downgraded to `^5.0.0` (Dart 3.6 compat)
- `path` dependency pinned to `^1.9.0` (flutter_test SDK constraint)
- Docker image build: switched from upstream `cirruslabs/flutter` image to self-contained Flutter install
- CI workflow permissions syntax fixed
- HEALTHCHECK changed to verify binary exists instead of `--help` on GUI app

### Added
- `AGENTS.md` — context file for future OpenCode sessions
- `CHANGELOG.md`

## [0.1.0] — 2026-06-16

### Added
- Initial release
- Local-only beer tracking (photos, ratings, notes, purchase details)
- Drink history logging
- Search, sort, and filter
- Stats page
- Theme presets (6 themes)
- Backup/import
- CI: Docker image publish to GHCR
- CI: Android APK + AAB build with GitHub Release on tags
