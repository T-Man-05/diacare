# DiaCare BLoC/Cubit State Management Documentation

## Table of Contents

1. [Overview](#overview)
2. [Migration Summary](#migration-summary)
3. [Architecture](#architecture)
4. [Cubit Classes](#cubit-classes)
5. [State Classes](#state-classes)
6. [Usage Examples](#usage-examples)
7. [Best Practices](#best-practices)

---

## Overview

DiaCare has been migrated from **Provider** to **BLoC/Cubit** state management pattern. The Cubit pattern was chosen over full BLoC because:

- **Simpler API**: No need to define separate event classes
- **Less boilerplate**: Direct method calls instead of event dispatching
- **Easier to understand**: More intuitive for simple state changes
- **Still reactive**: Uses streams under the hood

### Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3 # BLoC/Cubit state management
  equatable: ^2.0.5 # Value equality for state comparison
```

---

## Migration Summary

| Old (Provider)            | New (BLoC/Cubit)                                          |
| ------------------------- | --------------------------------------------------------- |
| `ChangeNotifier`          | `Cubit<State>`                                            |
| `ChangeNotifierProvider`  | `BlocProvider`                                            |
| `MultiProvider`           | `MultiBlocProvider`                                       |
| `Consumer<T>`             | `BlocBuilder<Cubit, State>`                               |
| `Provider.of<T>(context)` | `context.read<Cubit>()` or `context.watch<Cubit>().state` |
| `notifyListeners()`       | `emit(newState)`                                          |

---

## Architecture

### File Structure

```
lib/
├── blocs/
│   ├── blocs.dart              # Barrel file (exports all blocs)
│   ├── settings/
│   │   ├── settings_cubit.dart # Business logic for settings
│   │   └── settings_state.dart # Immutable state for settings
│   └── locale/
│       ├── locale_cubit.dart   # Business logic for locale
│       └── locale_state.dart   # Immutable state for locale
└── main.dart                   # App entry with BlocProviders
```

### Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Widget    │────▶│    Cubit    │────▶│    State    │
│  (UI Layer) │     │  (Logic)    │     │ (Immutable) │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       │   method call     │    emit()         │
       └───────────────────┘                   │
       ◀───────────────────────────────────────┘
              BlocBuilder rebuilds on state change
```

---

## Cubit Classes

### SettingsCubit

**Location**: `lib/blocs/settings/settings_cubit.dart`

**Purpose**: Manages app-wide settings including theme mode and glucose units.

```dart
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  // Available Methods:
  void setTheme(String theme);        // 'light', 'dark', or 'system'
  void setThemeMode(ThemeMode mode);  // ThemeMode.light/dark/system
  void toggleTheme();                 // Cycles through themes
  void setUnits(String units);        // 'mg/dL' or 'mmol/L'
  void toggleUnits();                 // Switches between units
}
```

#### Method Details

| Method         | Parameters       | Description                                        |
| -------------- | ---------------- | -------------------------------------------------- |
| `setTheme`     | `String theme`   | Sets theme using string: 'light', 'dark', 'system' |
| `setThemeMode` | `ThemeMode mode` | Sets theme using Flutter's ThemeMode enum          |
| `toggleTheme`  | none             | Cycles: light → dark → system → light              |
| `setUnits`     | `String units`   | Sets glucose units: 'mg/dL' or 'mmol/L'            |
| `toggleUnits`  | none             | Toggles between mg/dL and mmol/L                   |

---

### LocaleCubit

**Location**: `lib/blocs/locale/locale_cubit.dart`

**Purpose**: Manages app localization and language settings.

```dart
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(const LocaleState());

  // Available Methods:
  void setLocale(String languageCode);    // 'en', 'fr', 'ar'
  void setLocaleFromLocale(Locale locale); // Locale object
  void cycleLanguage();                    // Cycles through languages
}
```

#### Supported Languages

| Language Code | Language | RTL Support |
| ------------- | -------- | ----------- |
| `en`          | English  | No          |
| `fr`          | French   | No          |
| `ar`          | Arabic   | Yes         |

---

## State Classes

### SettingsState

**Location**: `lib/blocs/settings/settings_state.dart`

```dart
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String units;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.units = 'mg/dL',
  });

  // Computed Properties:
  bool get isDarkMode;    // True if theme is dark
  bool get isLightMode;   // True if theme is light
  bool get isSystemMode;  // True if following system

  // Utility Methods:
  double formatGlucoseValue(double mgdL);    // Converts mg/dL to current unit
  double convertGlucose(double value, String fromUnit, String toUnit);
  String formatGlucose(double mgdL);         // Formatted string with unit

  // Immutable Copy:
  SettingsState copyWith({ThemeMode? themeMode, String? units});
}
```

#### Glucose Conversion Formula

```
mmol/L = mg/dL ÷ 18.0182
mg/dL = mmol/L × 18.0182
```

---

### LocaleState

**Location**: `lib/blocs/locale/locale_state.dart`

```dart
class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState({this.locale = const Locale('en')});

  // Computed Properties:
  String get languageCode;        // 'en', 'fr', 'ar'
  bool get isEnglish;
  bool get isFrench;
  bool get isArabic;
  bool get isRtl;                 // True for Arabic
  TextDirection get textDirection; // RTL or LTR

  // Immutable Copy:
  LocaleState copyWith({Locale? locale});
}
```

---

## Usage Examples

### 1. Setting Up BlocProviders (main.dart)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/blocs.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 2. Reading State with BlocBuilder

```dart
// Rebuilds widget when state changes
BlocBuilder<SettingsCubit, SettingsState>(
  builder: (context, state) {
    return Text('Current units: ${state.units}');
  },
)
```

### 3. Multiple Cubits with Nested BlocBuilders

```dart
BlocBuilder<SettingsCubit, SettingsState>(
  builder: (context, settingsState) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        return MaterialApp(
          themeMode: settingsState.themeMode,
          locale: localeState.locale,
          // ...
        );
      },
    );
  },
)
```

### 4. Calling Cubit Methods

```dart
// Using context.read (doesn't listen to changes)
ElevatedButton(
  onPressed: () {
    context.read<SettingsCubit>().setTheme('dark');
  },
  child: Text('Dark Mode'),
)

// Toggle example
IconButton(
  onPressed: () => context.read<SettingsCubit>().toggleUnits(),
  icon: Icon(Icons.swap_horiz),
)
```

### 5. Conditional Building with buildWhen

```dart
BlocBuilder<SettingsCubit, SettingsState>(
  // Only rebuild when units change, ignore theme changes
  buildWhen: (previous, current) => previous.units != current.units,
  builder: (context, state) {
    return Text('Units: ${state.units}');
  },
)
```

### 6. Using BlocListener (Side Effects)

```dart
BlocListener<SettingsCubit, SettingsState>(
  listenWhen: (previous, current) => previous.units != current.units,
  listener: (context, state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Units changed to ${state.units}')),
    );
  },
  child: MyWidget(),
)
```

### 7. BlocConsumer (Builder + Listener)

```dart
BlocConsumer<LocaleCubit, LocaleState>(
  listener: (context, state) {
    // Side effect: show notification
    print('Language changed to ${state.languageCode}');
  },
  builder: (context, state) {
    return Text('Current: ${state.languageCode}');
  },
)
```

---

## Best Practices

### 1. State Immutability

Always use `copyWith` to create new state objects:

```dart
// ✅ Correct
emit(state.copyWith(units: 'mmol/L'));

// ❌ Wrong - mutating state directly
state.units = 'mmol/L';
emit(state);
```

### 2. Equatable for State Comparison

Extend `Equatable` and list all properties in `props`:

```dart
class MyState extends Equatable {
  final String value;
  const MyState({required this.value});

  @override
  List<Object?> get props => [value]; // Include ALL fields
}
```

### 3. Use context.read for Actions

Use `context.read<Cubit>()` when triggering actions (doesn't subscribe):

```dart
// ✅ In callbacks/event handlers
onPressed: () => context.read<SettingsCubit>().toggleTheme()

// ❌ Don't use watch in callbacks
onPressed: () => context.watch<SettingsCubit>().toggleTheme() // BAD!
```

### 4. Use BlocBuilder for UI

Use `BlocBuilder` to reactively rebuild UI:

```dart
// ✅ Widget rebuilds on state change
BlocBuilder<SettingsCubit, SettingsState>(
  builder: (context, state) => Text(state.units),
)
```

### 5. Organize with Barrel Files

Export all bloc-related files from a single barrel file:

```dart
// blocs/blocs.dart
export 'settings/settings_cubit.dart';
export 'settings/settings_state.dart';
export 'locale/locale_cubit.dart';
export 'locale/locale_state.dart';

// Usage
import 'package:diacare/blocs/blocs.dart';
```

### 6. Keep Cubits Focused

Each Cubit should manage one domain:

```dart
// ✅ Focused
SettingsCubit  // Theme + Units
LocaleCubit    // Language/Locale

// ❌ Too broad
AppCubit       // Everything
```

---

## Troubleshooting

### Common Issues

| Issue                                                        | Solution                                              |
| ------------------------------------------------------------ | ----------------------------------------------------- |
| `BlocProvider.of() called with context without BlocProvider` | Ensure BlocProvider is above the widget in the tree   |
| State not updating UI                                        | Check that all fields are in `props` list (Equatable) |
| `context.read` returns null                                  | Cubit not provided in ancestor widget                 |
| Multiple unnecessary rebuilds                                | Use `buildWhen` to limit rebuilds                     |

### Debug Tips

```dart
// Enable BLoC observer for debugging
Bloc.observer = SimpleBlocObserver();

class SimpleBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }
}
```

---

## Migration Checklist

- [x] Add `flutter_bloc` and `equatable` to pubspec.yaml
- [x] Create `SettingsState` with Equatable
- [x] Create `SettingsCubit` extending Cubit
- [x] Create `LocaleState` with Equatable
- [x] Create `LocaleCubit` extending Cubit
- [x] Create barrel file `blocs/blocs.dart`
- [x] Update `main.dart` with MultiBlocProvider
- [x] Update `dashboard_page.dart` with BlocBuilder
- [x] Update `settings_page.dart` with BlocBuilder
- [x] Update `diabetics_profile_page.dart` with BlocBuilder
- [x] Remove Provider dependency from pubspec.yaml
- [x] Delete old provider files

---

## Additional Resources

- [Official BLoC Documentation](https://bloclibrary.dev/)
- [flutter_bloc Package](https://pub.dev/packages/flutter_bloc)
- [Equatable Package](https://pub.dev/packages/equatable)
- [BLoC Pattern Explained](https://bloclibrary.dev/architecture/)

---

_Documentation generated for DiaCare v1.0 - BLoC/Cubit Migration_
