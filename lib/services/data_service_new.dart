/// ============================================================================
/// DATA SERVICE - Unified Data Access Layer
/// ============================================================================
///
/// This service provides a unified interface for all data operations in DiaCare.
/// It combines:
/// - SQLite (via DatabaseHelper) for persistent structured data
/// - SharedPreferences (via PreferencesService) for quick-access settings
///
/// Data Distribution:
/// ┌─────────────────────────────────────────────────────────────────────┐
/// │                        DataService                                   │
/// ├─────────────────────────────┬───────────────────────────────────────┤
/// │   PreferencesService        │        DatabaseHelper                  │
/// │   (SharedPreferences)       │        (SQLite)                        │
/// ├─────────────────────────────┼───────────────────────────────────────┤
/// │ • Theme                     │ • Users                               │
/// │ • Locale                    │ • Glucose readings                    │
/// │ • Units                     │ • Health cards                        │
/// │ • Session (user ID)         │ • Reminders                           │
/// │ • Notifications             │ • Diabetic profiles                   │
/// │ • Onboarding status         │ • Chart data                          │
/// └─────────────────────────────┴───────────────────────────────────────┘
///
/// Usage:
///   await DataService.initialize();
///   final service = DataService.instance;
/// ============================================================================

import 'dart:convert';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'preferences_service.dart';

/// Main Data Service - Singleton
class DataService {
  static DataService? _instance;

  final DatabaseHelper _db;
  final PreferencesService _prefs;

  DataService._(this._db, this._prefs);

  /// Initialize the data service (call once at app startup)
  static Future<DataService> initialize() async {
    if (_instance != null) return _instance!;

    final prefs = PreferencesService();
    await prefs.init();

    final db = DatabaseHelper();
    // Database initializes lazily on first access

    _instance = DataService._(db, prefs);
    return _instance!;
  }

  /// Get the singleton instance
  static DataService get instance {
    if (_instance == null) {
      throw DataServiceException(
        'DataService not initialized. Call DataService.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Check if service is initialized
  static bool get isInitialized => _instance != null;

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Get the currently logged in user ID
  int? get currentUserId => _prefs.getLoggedInUserId();

  /// Check if a user is logged in
  bool get isLoggedIn => _prefs.isLoggedIn();

  /// Login user and save session
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final user = await _db.authenticateUser(email, password);
    if (user != null) {
      await _prefs.setLoggedInUserId(user['id'] as int);
    }
    return user;
  }

  /// Logout current user
  Future<void> logout() async {
    await _prefs.clearSession();
  }

  /// Register a new user
  Future<int> registerUser({
    required String email,
    required String password,
    required String username,
    String fullName = '',
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    bool seedDemoData = false,
  }) async {
    // Check if email already exists
    if (await _db.emailExists(email)) {
      throw DataServiceException('Email already exists');
    }

    // Create the user
    final userId = await _db.createUser(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      height: height,
      weight: weight,
    );

    // Seed demo data for new user
    if (seedDemoData) {
      await _db.seedDemoData(userId);
    }

    // Auto-login after registration
    await _prefs.setLoggedInUserId(userId);

    return userId;
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    return await _db.emailExists(email);
  }

  /// Authenticate user (without saving session)
  Future<Map<String, dynamic>?> authenticateUser(
      String email, String password) async {
    return await _db.authenticateUser(email, password);
  }

  // ============================================================================
  // USER OPERATIONS
  // ============================================================================

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return await _db.getUserById(userId);
  }

  /// Update current user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');
    await _db.updateUser(userId, data);
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');
    await _db.updatePassword(userId, newPassword);
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');
    await _db.deleteUser(userId);
    await logout();
  }

  // ============================================================================
  // PREFERENCES (SharedPreferences)
  // ============================================================================

  /// Get theme preference
  String get theme => _prefs.getTheme();

  /// Set theme preference
  Future<void> setTheme(String theme) async {
    await _prefs.setTheme(theme);
  }

  /// Get locale preference
  String get locale => _prefs.getLocale();

  /// Set locale preference
  Future<void> setLocale(String locale) async {
    await _prefs.setLocale(locale);
  }

  /// Get units preference
  String get units => _prefs.getUnits();

  /// Set units preference
  Future<void> setUnits(String units) async {
    await _prefs.setUnits(units);
  }

  /// Get notifications enabled
  bool get notificationsEnabled => _prefs.getNotificationsEnabled();

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
  }

  /// Check if onboarding is complete
  bool get isOnboardingComplete => _prefs.isOnboardingComplete();

  /// Set onboarding complete
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setOnboardingComplete(complete);
  }

  /// Get all preferences
  Map<String, dynamic> getAllPreferences() {
    return _prefs.getAllPreferences();
  }

  // ============================================================================
  // DASHBOARD DATA
  // ============================================================================

  /// Get dashboard data for current user
  Future<Map<String, dynamic>> getDashboardData() async {
    final userId = currentUserId;
    if (userId == null) {
      return _getDefaultDashboardData();
    }
    return await _db.getDashboardData(userId);
  }

  /// Get default dashboard data (for non-logged-in state)
  Map<String, dynamic> _getDefaultDashboardData() {
    return {
      'greeting': 'Welcome',
      'glucose': {'value': 0, 'unit': 'mg/dL', 'status': 'Please log in'},
      'reminder': 'Log in to see reminders',
      'health_cards': [
        {'title': 'Water', 'value': 0.0, 'unit': 'L'},
        {'title': 'Pills', 'value': 0.0, 'unit': 'taken'},
        {'title': 'Activity', 'value': 0.0, 'unit': 'steps'},
        {'title': 'Carbs', 'value': 0.0, 'unit': 'cal'},
        {'title': 'Insulin', 'value': 0.0, 'unit': 'units'},
      ],
      'chart': {
        'title': 'Blood Sugar (mg/dL)',
        'data': {'before_meal': <double>[], 'after_meal': <double>[]},
        'days': ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      },
    };
  }

  // ============================================================================
  // SETTINGS DATA
  // ============================================================================

  /// Get settings data for current user
  Future<Map<String, dynamic>> getSettings() async {
    final userId = currentUserId;
    if (userId == null) {
      throw DataServiceException('No user logged in');
    }

    final settings = await _db.getSettingsData(userId);

    // Override preferences from SharedPreferences
    settings['preferences'] = {
      'theme': _prefs.getTheme(),
      'notifications_enabled': _prefs.getNotificationsEnabled(),
      'units': _prefs.getUnits(),
    };

    return settings;
  }

  /// Update settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');

    // Update user data in SQLite
    if (settings.containsKey('full_name') ||
        settings.containsKey('username') ||
        settings.containsKey('email')) {
      await _db.updateUser(userId, {
        if (settings.containsKey('full_name'))
          'full_name': settings['full_name'],
        if (settings.containsKey('username')) 'username': settings['username'],
        if (settings.containsKey('email')) 'email': settings['email'],
      });
    }

    // Update diabetic profile in SQLite
    if (settings.containsKey('diabetic_profile')) {
      final profile = settings['diabetic_profile'] as Map<String, dynamic>;
      await _db.updateDiabeticProfile(userId, {
        if (profile.containsKey('diabetic_type'))
          'diabetic_type': profile['diabetic_type'],
        if (profile.containsKey('treatment_type'))
          'treatment_type': profile['treatment_type'],
        if (profile.containsKey('min_glucose'))
          'min_glucose': profile['min_glucose'],
        if (profile.containsKey('max_glucose'))
          'max_glucose': profile['max_glucose'],
      });
    }

    // Update preferences in SharedPreferences
    if (settings.containsKey('preferences')) {
      final prefs = settings['preferences'] as Map<String, dynamic>;
      await _prefs.setAllPreferences(prefs);
    }
  }

  // ============================================================================
  // DIABETIC PROFILE
  // ============================================================================

  /// Get diabetic profile for current user
  Future<Map<String, dynamic>?> getDiabeticProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return await _db.getDiabeticProfile(userId);
  }

  /// Update diabetic profile
  Future<void> updateDiabeticProfile(Map<String, dynamic> profile) async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');
    await _db.updateDiabeticProfile(userId, profile);
  }

  // ============================================================================
  // GLUCOSE READINGS
  // ============================================================================

  /// Add a glucose reading
  Future<int> addGlucoseReading({
    required double value,
    String unit = 'mg/dL',
    String readingType = 'before_meal',
    String? notes,
    DateTime? recordedAt,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');

    return await _db.addGlucoseReading(
      userId: userId,
      value: value,
      unit: unit,
      readingType: readingType,
      notes: notes,
      recordedAt: recordedAt,
    );
  }

  /// Get glucose readings
  Future<List<Map<String, dynamic>>> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    return await _db.getGlucoseReadings(
      userId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Get latest glucose reading
  Future<Map<String, dynamic>?> getLatestGlucoseReading() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return await _db.getLatestGlucoseReading(userId);
  }

  /// Get glucose chart data
  Future<Map<String, List<double>>> getGlucoseChartData() async {
    final userId = currentUserId;
    if (userId == null) return {'before_meal': [], 'after_meal': []};
    return await _db.getGlucoseChartData(userId);
  }

  // ============================================================================
  // HEALTH CARDS
  // ============================================================================

  /// Update health card value
  Future<void> updateHealthCard({
    required String cardType,
    required double value,
    required String unit,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');

    await _db.upsertHealthCard(
      userId: userId,
      cardType: cardType,
      value: value,
      unit: unit,
    );
  }

  /// Get health cards for today
  Future<List<Map<String, dynamic>>> getHealthCards() async {
    final userId = currentUserId;
    if (userId == null) return _db.getDefaultHealthCards();
    return await _db.getHealthCards(userId);
  }

  // ============================================================================
  // REMINDERS
  // ============================================================================

  /// Get reminders for current user
  Future<List<dynamic>> getReminders() async {
    final userId = currentUserId;
    if (userId == null) return [];
    return await _db.getReminders(userId);
  }

  /// Add a reminder
  Future<int> addReminder({
    required String title,
    required String reminderType,
    required String scheduledTime,
    String? description,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw DataServiceException('No user logged in');

    return await _db.addReminder(
      userId: userId,
      title: title,
      reminderType: reminderType,
      scheduledTime: scheduledTime,
      description: description,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
    );
  }

  /// Update reminder
  Future<void> updateReminder(
      String reminderId, Map<String, dynamic> data) async {
    await _db.updateReminder(int.parse(reminderId), data);
  }

  /// Update reminder status
  Future<void> updateReminderStatus(int reminderId, String status) async {
    await _db.updateReminderStatus(reminderId, status);
  }

  /// Delete reminder
  Future<void> deleteReminder(int reminderId) async {
    await _db.deleteReminder(reminderId);
  }

  // ============================================================================
  // CHARTS DATA
  // ============================================================================

  /// Get charts data
  Future<Map<String, dynamic>> getCharts() async {
    final userId = currentUserId;
    if (userId == null) {
      return {
        'blood_sugar': {'before_meal': <double>[], 'after_meal': <double>[]},
      };
    }

    final glucoseData = await _db.getGlucoseChartData(userId);
    return {
      'blood_sugar': glucoseData,
    };
  }

  // ============================================================================
  // LEGACY COMPATIBILITY METHODS
  // (For backward compatibility with existing code)
  // ============================================================================

  /// Get app strings (loads from JSON asset for now)
  Future<Map<String, dynamic>> getAppStrings() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/app_data.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return data['app_strings'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Get specific string by key path
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

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    await _db.clearAllData();
    await _prefs.clearAll();
  }

  /// Close database connection
  Future<void> close() async {
    await _db.close();
  }
}

/// Custom exception for data service errors
class DataServiceException implements Exception {
  final String message;
  DataServiceException(this.message);

  @override
  String toString() => 'DataServiceException: $message';
}
