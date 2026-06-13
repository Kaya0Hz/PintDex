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

From the project folder:

```bash
flutter pub get
flutter run -d linux
```

For Android:

```bash
flutter run -d android
```

## Build Linux

```bash
flutter build linux
```

The Linux app stores beer data locally in your app support directory.

## Notes

- You need Flutter installed and on your `PATH`
- On Linux, you also need the desktop build toolchain
- Android requires the Android SDK and a device or emulator
