# PintDex

Local-only beer tracking app for Linux and Android.

## What it does

- Add beers with a label photo
- Rate them on a 10-point scale
- Track sweetness, bitterness, body, acidity, and overall
- Log drinks, favorites, and drink history
- Sort, search, and filter your list
- Use list or grid views
- View stats and export or import backups
- Switch between theme presets
- Store everything locally on your device

## How to run

You can use PintDex without installing Flutter — just grab the prebuilt release.

### Docker (Linux desktop)

```bash
docker pull ghcr.io/Kaya0Hz/pintdex:latest
docker run --rm -it -v pintdex-data:/data ghcr.io/Kaya0Hz/pintdex:latest
```

### Android APK

Download the latest APK from the [Releases](https://github.com/Kaya0Hz/PintDex/releases) page and install it on your device.

### Local development

From the project folder:

```bash
flutter pub get
flutter run -d linux    # Linux desktop
flutter run -d android  # Android device/emulator
```

The Linux app stores beer data locally in your app support directory.

## Notes

- You need Flutter installed and on your `PATH` for local development
- On Linux, you also need the desktop build toolchain
- Android requires the Android SDK and a device or emulator

## Release process

Tag a commit and push it to trigger the CI pipelines:

```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
```

This will:
1. **Docker** — Build and publish a Linux desktop image to `ghcr.io/<owner>/pintdex`
2. **Android** — Build release APK + AAB, upload them as artifacts, and create a **GitHub Release** with the binaries attached
