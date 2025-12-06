/// ============================================================================
/// DATA SERVICE - Abstraction Layer for Future Database Compatibility
/// ============================================================================
///
/// This service provides a clean abstraction between the UI and data sources.
/// It can be easily extended to support:
/// - REST API calls
/// - SQL/NoSQL databases
/// - Firebase
/// - Local storage (SharedPreferences, Hive, etc.)
/// - GraphQL
///
/// The UI layer should NEVER directly access data sources - it must always
/// go through this service layer.
/// ============================================================================

import 'dart:convert';
import 'package:flutter/services.dart';

/// Abstract data source interface
/// Implement this interface for different data source types
abstract class DataSource {
  Future<Map<String, dynamic>> fetchData();
  Future<void> updateData(String key, dynamic value);
  Future<void> saveData(Map<String, dynamic> data);
}

/// JSON file data source implementation
/// Currently used for demo/local data
class JsonFileDataSource implements DataSource {
  final String _assetPath;
  Map<String, dynamic>? _cachedData;

  JsonFileDataSource(this._assetPath);

  @override
  Future<Map<String, dynamic>> fetchData() async {
    if (_cachedData != null) {
      return Map<String, dynamic>.from(_cachedData!);
    }

    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      _cachedData = json.decode(jsonString) as Map<String, dynamic>;
      return Map<String, dynamic>.from(_cachedData!);
    } catch (e) {
      throw DataServiceException('Failed to load data from $_assetPath: $e');
    }
  }

  @override
  Future<void> updateData(String key, dynamic value) async {
    if (_cachedData == null) {
      await fetchData();
    }
    _cachedData![key] = value;
  }

  @override
  Future<void> saveData(Map<String, dynamic> data) async {
    _cachedData = data;
    // Note: Assets are read-only, implement file writing for persistence
    // or use SharedPreferences/Hive for local storage
  }

  void clearCache() {
    _cachedData = null;
  }
}

/// REST API data source implementation (Future Use)
/// Uncomment and implement when connecting to a backend API
/*
class RestApiDataSource implements DataSource {
  final String baseUrl;
  final String authToken;

  RestApiDataSource(this.baseUrl, {required this.authToken});

  @override
  Future<Map<String, dynamic>> fetchData() async {
    // Implement HTTP GET request
    // Example: http.get(Uri.parse('$baseUrl/api/data'))
    throw UnimplementedError();
  }

  @override
  Future<void> updateData(String key, dynamic value) async {
    // Implement HTTP PATCH/PUT request
    throw UnimplementedError();
  }

  @override
  Future<void> saveData(Map<String, dynamic> data) async {
    // Implement HTTP POST request
    throw UnimplementedError();
  }
}
*/

/// SQL Database data source implementation (Future Use)
/// Uncomment and implement when connecting to SQLite
/*
class SqlDatabaseDataSource implements DataSource {
  final Database database;

  SqlDatabaseDataSource(this.database);

  @override
  Future<Map<String, dynamic>> fetchData() async {
    // Implement SQL queries to fetch all app data
    throw UnimplementedError();
  }

  @override
  Future<void> updateData(String key, dynamic value) async {
    // Implement SQL UPDATE query
    throw UnimplementedError();
  }

  @override
  Future<void> saveData(Map<String, dynamic> data) async {
    // Implement SQL INSERT/UPDATE queries
    throw UnimplementedError();
  }
}
*/

/// Main Data Service
/// This is the ONLY service the UI should interact with
class DataService {
  final DataSource _dataSource;

  // Singleton pattern for global access
  static DataService? _instance;

  DataService._(this._dataSource);

  /// Factory constructor to create or return existing instance
  factory DataService({required DataSource dataSource}) {
    _instance ??= DataService._(dataSource);
    return _instance!;
  }

  /// Get the current instance (must be initialized first)
  static DataService get instance {
    if (_instance == null) {
      throw DataServiceException(
          'DataService not initialized. Call DataService(dataSource: ...) first.');
    }
    return _instance!;
  }

  // ========================================================================
  // PUBLIC API METHODS
  // ========================================================================

  /// Fetch all application strings and labels
  Future<Map<String, dynamic>> getAppStrings() async {
    final data = await _dataSource.fetchData();
    return data['app_strings'] as Map<String, dynamic>;
  }

  /// Fetch dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    final data = await _dataSource.fetchData();
    return data['dashboard'] as Map<String, dynamic>;
  }

  /// Fetch user settings
  Future<Map<String, dynamic>> getSettings() async {
    final data = await _dataSource.fetchData();
    return data['settings'] as Map<String, dynamic>;
  }

  /// Update user settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _dataSource.updateData('settings', settings);
  }

  /// Fetch reminders list
  Future<List<dynamic>> getReminders() async {
    final data = await _dataSource.fetchData();
    return data['reminders'] as List<dynamic>;
  }

  /// Authenticate user with email and password
  /// Returns user data if successful, null if authentication fails
  Future<Map<String, dynamic>?> authenticateUser(
      String email, String password) async {
    final data = await _dataSource.fetchData();
    final users = data['users'] as List<dynamic>?;

    if (users == null) return null;

    for (final user in users) {
      if (user['email'] == email && user['password'] == password) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  /// Check if email already exists in users list
  Future<bool> emailExists(String email) async {
    final data = await _dataSource.fetchData();
    final users = data['users'] as List<dynamic>?;

    if (users == null) return false;

    for (final user in users) {
      if (user['email'] == email) {
        return true;
      }
    }
    return false;
  }

  /// Update a specific reminder
  Future<void> updateReminder(
      String reminderId, Map<String, dynamic> reminderData) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r['id'] == reminderId);

    if (index != -1) {
      reminders[index] = {...reminders[index], ...reminderData};
      await _dataSource.updateData('reminders', reminders);
    }
  }

  /// Fetch chart data
  Future<Map<String, dynamic>> getCharts() async {
    final data = await _dataSource.fetchData();
    return data['charts'] as Map<String, dynamic>;
  }

  /// Get specific app string by key path
  /// Example: getString('login.title') returns "Log In"
  Future<String> getString(String keyPath, {String defaultValue = ''}) async {
    try {
      final strings = await getAppStrings();
      final keys = keyPath.split('.');
      dynamic value = strings;

      for (final key in keys) {
        if (value is Map<String, dynamic> && value.containsKey(key)) {
          value = value[key];
        } else {
          return defaultValue;
        }
      }

      return value?.toString() ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Get list of options by key path
  /// Example: getOptions('options.genders') returns ["Male", "Female", "Other"]
  Future<List<String>> getOptions(String keyPath) async {
    try {
      final strings = await getAppStrings();
      final keys = keyPath.split('.');
      dynamic value = strings;

      for (final key in keys) {
        if (value is Map<String, dynamic> && value.containsKey(key)) {
          value = value[key];
        } else {
          return [];
        }
      }

      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Clear all cached data and force reload
  void clearCache() {
    if (_dataSource is JsonFileDataSource) {
      (_dataSource as JsonFileDataSource).clearCache();
    }
  }

  /// Save all data (useful when switching data sources)
  Future<void> saveAllData(Map<String, dynamic> data) async {
    await _dataSource.saveData(data);
  }
}

/// Custom exception for data service errors
class DataServiceException implements Exception {
  final String message;
  DataServiceException(this.message);

  @override
  String toString() => 'DataServiceException: $message';
}
