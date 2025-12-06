# Development Setup Guide

## Prerequisites
- Flutter SDK 3.0+ ([Download](https://flutter.dev/docs/get-started/install))
- Android Studio or Xcode for mobile development
- Git for version control

## Local Setup

### 1. Clone Repository
```bash
git clone https://github.com/T-Man-05/diacare.git
cd diacare
```

### 2. Install Dependencies
```bash
flutter pub get
flutter pub upgrade
```

### 3. Database Setup
- SQLite database auto-initializes on first run
- Check `lib/services/data_service_new.dart`

### 4. Run Application
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Run on specific device
flutter run -d <device-id>
```

## Code Organization

### Creating New BLoCs
```dart
// Create folder: lib/blocs/feature_name/
// Files: event.dart, state.dart, bloc.dart
```

### Adding New Pages
```dart
// Create: lib/pages/feature_page.dart
// Wrap with BlocProvider or BlocListener
```

### Database Queries
```dart
// Extend DataService class
// Add methods in lib/services/data_service_new.dart
```

## Running Tests
```bash
flutter test
```

## Build APK/IPA
```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release
```

## Troubleshooting

### Build Cache Issues
```bash
flutter clean
flutter pub get
flutter run
```

### Gradle Download Issues
```bash
# Remove corrupted Gradle wrapper
rm -rf ~/.gradle/wrapper/dists/gradle-8.12-all
flutter run
```

### Dependency Conflicts
```bash
flutter pub outdated
flutter pub upgrade --major-versions
```
