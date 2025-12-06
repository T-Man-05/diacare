# API Integration Guide

## Overview
This guide covers integrating backend APIs into DiaCare.

## Current Architecture
- **Local Storage**: SQLite + SharedPreferences
- **API Ready**: Structure in place for future API calls

## Adding API Endpoints

### 1. Create API Service
```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'https://api.example.com';
  
  Future<GlucoseReading> fetchGlucoseReadings() async {
    // API call implementation
  }
}
```

### 2. Create Repository
```dart
// lib/repositories/glucose_repository.dart
class GlucoseRepository {
  final ApiService apiService;
  
  Future<List<GlucoseReading>> getReadings() async {
    return apiService.fetchGlucoseReadings();
  }
}
```

### 3. Use in BLoC
```dart
// lib/blocs/glucose_bloc.dart
class GlucoseBloc extends Bloc<GlucoseEvent, GlucoseState> {
  final GlucoseRepository repository;
  
  // Handle events with repository
}
```

## API Response Handling

### Error Handling
- Implement retry logic for network failures
- Show user-friendly error messages
- Log errors for debugging

### Data Caching
- Cache API responses in SQLite
- Sync with server periodically
- Support offline mode

## Authentication

### JWT Token Management
```dart
// Store token in SharedPreferences
// Attach to API headers
// Refresh token when expired
```

## Testing APIs

### Mock Data
- Use test doubles for API calls
- Create fixtures in test directory
- Mock ApiService for BLoC tests
