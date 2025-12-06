# Contributing Guide

## Getting Started
1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/diacare.git`
3. Create a branch: `git checkout -b feature/feature-name`
4. Follow code standards below

## Code Standards

### Naming Conventions
- **Classes**: PascalCase (e.g., `GlucoseBloc`)
- **Functions/Methods**: camelCase (e.g., `fetchGlucoseReadings`)
- **Files**: snake_case (e.g., `glucose_bloc.dart`)
- **Constants**: camelCase with leading underscore if private (e.g., `_defaultTimeout`)

### File Organization
```
lib/
├── blocs/
│   ├── feature_name/
│   │   ├── bloc.dart
│   │   ├── event.dart
│   │   └── state.dart
├── pages/
│   └── feature_page.dart
├── widgets/
│   └── feature_widget.dart
└── services/
    └── feature_service.dart
```

### Code Style
- Use `final` for variables that don't change
- Add documentation comments for public classes/methods
- Keep functions focused and small (< 50 lines preferred)
- Use meaningful variable names

### Example Code
```dart
/// Fetches glucose readings from the database
/// Returns a [Future] with list of [GlucoseReading] or error
Future<List<GlucoseReading>> fetchReadings() async {
  try {
    final readings = await _repository.getReadings();
    return readings;
  } catch (e) {
    Logger.error('Failed to fetch readings', e);
    rethrow;
  }
}
```

## Commit Messages

Format: `type: brief summary`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code restructuring
- `style`: Formatting
- `test`: Testing
- `chore`: Maintenance

Example:
```
feat: add glucose export functionality
```

## Pull Request Process

1. Ensure all tests pass: `flutter test`
2. Run analysis: `flutter analyze`
3. Format code: `flutter format .`
4. Update documentation
5. Create PR with description of changes

## Testing

- Write unit tests for BLoCs and repositories
- Use mockito for mocking dependencies
- Aim for >80% code coverage on critical features

```bash
flutter test --coverage
```

## Questions?
Open an issue or contact the maintainers.
