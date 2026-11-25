# Cineplay Example App

Multi-platform example application demonstrating `cineplay`, `cineplay_fvp`, and `cineplay_pip`.

## Running

```bash
cd packages/cineplay/example
flutter pub get

# Web
flutter run -d chrome

# Desktop
flutter run -d macos
flutter run -d windows
flutter run -d linux

# Mobile
flutter run -d ios
flutter run -d android
```

## Testing

```bash
flutter analyze --fatal-infos
flutter test
```
