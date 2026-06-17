# PintDex (beer_tracker)

Flutter 3.27.4 · Dart ^3.6.0 · Linux + Android

## Commands

```bash
flutter pub get
flutter run -d linux        # Linux desktop
flutter run -d android      # Android device/emulator
flutter build linux --release
flutter build apk --debug   # PR CI
flutter build apk --release # tag CI
flutter build appbundle --release
flutter test
flutter analyze
```

## Architecture

Single package (not a monorepo). No state management library — uses `ChangeNotifier` from Flutter SDK. No routing package — uses `Navigator.of(context).push`.

| Directory | Purpose |
|-----------|---------|
| `lib/main.dart` | Entrypoint: inits `BeerRepository` + `AppSettings`, pumps `BeerTrackerApp` |
| `lib/services/beer_repository.dart` | CRUD, JSON persistence in app support dir, backup import/export |
| `lib/services/app_settings.dart` | Settings JSON persistence + theme presets |
| `lib/models/beer_entry.dart` | Data model with `toJson`/`fromJson`, legacy field migration |
| `lib/screens/` | Home, detail, settings, stats pages |
| `lib/widgets/` | Editor sheet, bottle rating, image preview, feature log dialog |
| `test/widget_test.dart` | Single smoke test |

## CI

Two workflows in `.github/workflows/`, both trigger on `main` push, `v*` tags, and PRs to `main`:

- **`android-apk.yml`** — debug APK (always), release APK + AAB (push only), GitHub Release on `v*` tags
- **`docker-publish.yml`** — builds Linux desktop Docker image, pushes to `ghcr.io/<owner>/pintdex`

## Changelog

Update `CHANGELOG.md` when making user-facing changes (fixes, features, deprecations). Keep the format: `## [version] — date` with `Added`/`Fixed`/`Changed` sections.

## Gotchas

- `DropdownButtonFormField` uses `value:`, not `initialValue:` (removed in Flutter 3.27)
- NDK pinned to `27.0.12077973` in `android/app/build.gradle.kts` for plugin compat
- `path` dependency must be `^1.9.0` — flutter_test pins path to exact 1.9.0
- `flutter_lints` must be `^5.0.0` for Dart 3.6 compatibility
- Release build uses **debug signing key** (`signingConfigs.debug`) — needs a real keystore before Play Store distribution
- No network calls, no backend, no auth — everything stored as JSON + images in `getApplicationSupportDirectory()`
- App uses `dart:io` — web target won't compile

## Last session (Jun 16)

Added Docker + Android CI (`v0.1.0`), then fixed SDK/lib constraints and two source-level Flutter 3.27 regressions (`v0.1.1`). Created `AGENTS.md` and `CHANGELOG.md`.
