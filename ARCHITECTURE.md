# DiaCare - Architecture Overview

## Project Structure

### `/lib` - Application Source Code
- **`main.dart`** - App entry point with BLoC initialization
- **`blocs/`** - State management (BLoC/Cubit pattern)
- **`pages/`** - UI screens and routes
- **`widgets/`** - Reusable UI components
- **`models/`** - Data models and entities
- **`services/`** - Business logic and data services
- **`repositories/`** - Data access layer
- **`providers/`** - Future data providers
- **`utils/`** - Utility functions and helpers
- **`l10n/`** - Localization strings

### `/android` - Android Native
- Gradle configuration and Android-specific code

### `/ios` - iOS Native
- Swift code and iOS configuration

## Architecture Pattern

**Clean Architecture with BLoC State Management**

```
UI Layer (Pages/Widgets)
    ↓
BLoC/Cubit Layer (State Management)
    ↓
Repository Layer (Data Access)
    ↓
Service Layer (SQLite, SharedPreferences)
```

## Key Technologies

- **State Management**: Flutter BLoC / Cubit
- **Storage**: SQLite (data), SharedPreferences (settings)
- **UI**: Material Design
- **Charts**: fl_chart for glucose trends
- **Localization**: intl package

## Development Guidelines

1. **Keep BLoCs/Cubits focused** - one responsibility per state manager
2. **Use repositories** - abstract data access from UI
3. **Avoid service locator** - prefer dependency injection
4. **Follow SOLID principles** - Single Responsibility, Open/Closed, etc.
5. **Test business logic** - write unit tests for cubits and repositories
