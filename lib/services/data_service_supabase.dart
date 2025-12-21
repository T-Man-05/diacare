/// ============================================================================
/// DATA SERVICE - Unified Data Access Layer with Supabase
/// ============================================================================
///
/// This service provides a unified interface for all data operations in DiaCare.
/// It uses the Service Locator pattern via GetIt for dependency injection.
///
/// Data Backend:
/// - Primary: Supabase (PostgreSQL + Auth)
/// - Fallback: Local SharedPreferences for offline preferences
///
/// Authentication:
/// - Supabase Auth handles all authentication
/// - JWT tokens are automatically managed
/// - Session persistence handled by supabase_flutter
///
/// Usage:
///   1. Call `await setupDataServiceLocator()` in main.dart before runApp()
///   2. Access via: `getIt<DataService>()` or `locator<DataService>()`
/// ============================================================================
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'preferences_service.dart';

/// Global GetIt instance - Service Locator
final GetIt getIt = GetIt.instance;

/// Alias for more readable service access
T locator<T extends Object>() => getIt<T>();

/// Setup all data services in the Service Locator
/// Call this in main.dart before runApp()
Future<void> setupDataServiceLocator() async {
  // Initialize Supabase
  await SupabaseService.initialize();
  getIt.registerSingleton<SupabaseService>(SupabaseService.instance);

  // Initialize SharedPreferences for local settings
  final prefs = PreferencesService();
  await prefs.init();
  getIt.registerSingleton<PreferencesService>(prefs);

  // Register DataService as singleton
  getIt.registerSingleton<DataService>(
    DataService(getIt<SupabaseService>(), getIt<PreferencesService>()),
  );
}

/// Reset all services (useful for testing)
Future<void> resetDataServiceLocator() async {
  await getIt.reset();
}

/// Check if services are registered
bool get isDataServiceLocatorReady => getIt.isRegistered<DataService>();

/// Main Data Service
/// Access via: getIt<DataService>() or locator<DataService>()
class DataService {
  final SupabaseService _supabase;
  final PreferencesService _prefs;

  /// Constructor - used by GetIt for dependency injection
  DataService(this._supabase, this._prefs);

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Get the currently logged in user ID
  String? get currentUserId => _supabase.currentUserId;

  /// Check if a user is logged in
  bool get isLoggedIn => _supabase.isLoggedIn;

  /// Get current user
  User? get currentUser => _supabase.currentUser;

  /// Login user with email and password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _supabase.signIn(email: email, password: password);
      if (response.user != null) {
        // Get full profile
        return await _supabase.getProfile();
      }
      return null;
    } on AuthException catch (e) {
      throw DataServiceException('Login failed: ${e.message}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _supabase.signOut();
    await _prefs.clearSession();
  }

  /// Register a new user
  Future<String> registerUser({
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
    try {
      // Check if email already exists
      if (await _supabase.emailExists(email)) {
        throw DataServiceException('Email already exists');
      }

      // Create the user
      final response = await _supabase.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        height: height,
        weight: weight,
      );

      if (response.user == null) {
        throw DataServiceException('Registration failed');
      }

      // Seed demo data for new user
      if (seedDemoData) {
        await _supabase.seedDemoData();
      }

      return response.user!.id;
    } on AuthException catch (e) {
      throw DataServiceException('Registration failed: ${e.message}');
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    return await _supabase.emailExists(email);
  }

  /// Authenticate user (without saving session) - for verification
  Future<Map<String, dynamic>?> authenticateUser(
      String email, String password) async {
    try {
      final response = await _supabase.signIn(email: email, password: password);
      if (response.user != null) {
        return await _supabase.getProfile();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // USER OPERATIONS
  // ============================================================================

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _supabase.getProfile();
  }

  /// Update current user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    await _supabase.updateProfile(data);
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.updatePassword(newPassword);
  }

  /// Delete account
  Future<void> deleteAccount() async {
    await _supabase.deleteAccount();
    await _prefs.clearAll();
  }

  // ============================================================================
  // PREFERENCES (Local + Synced)
  // ============================================================================

  /// Get theme preference
  String get theme => _prefs.getTheme();

  /// Set theme preference
  Future<void> setTheme(String theme) async {
    await _prefs.setTheme(theme);
    // Sync to Supabase if logged in
    if (isLoggedIn) {
      await _supabase.updateUserPreferences({'theme': theme});
    }
  }

  /// Get locale preference
  String get locale => _prefs.getLocale();

  /// Set locale preference
  Future<void> setLocale(String locale) async {
    await _prefs.setLocale(locale);
    if (isLoggedIn) {
      await _supabase.updateUserPreferences({'locale': locale});
    }
  }

  /// Get units preference
  String get units => _prefs.getUnits();

  /// Set units preference
  Future<void> setUnits(String units) async {
    await _prefs.setUnits(units);
    if (isLoggedIn) {
      await _supabase.updateUserPreferences({'units': units});
    }
  }

  /// Get notifications enabled
  bool get notificationsEnabled => _prefs.getNotificationsEnabled();

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    if (isLoggedIn) {
      await _supabase.updateUserPreferences({'notifications_enabled': enabled});
    }
  }

  /// Check if onboarding is complete
  bool get isOnboardingComplete => _prefs.isOnboardingComplete();

  /// Set onboarding complete
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setOnboardingComplete(complete);
    if (isLoggedIn) {
      await _supabase.updateUserPreferences({'onboarding_complete': complete});
    }
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
    if (!isLoggedIn) {
      return _getDefaultDashboardData();
    }
    return await _supabase.getDashboardData();
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
    if (!isLoggedIn) {
      throw DataServiceException('No user logged in');
    }
    return await _supabase.getSettingsData();
  }

  /// Update settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (!isLoggedIn) throw DataServiceException('No user logged in');

    // Update profile data
    if (settings.containsKey('full_name') ||
        settings.containsKey('username') ||
        settings.containsKey('email')) {
      await _supabase.updateProfile({
        if (settings.containsKey('full_name'))
          'full_name': settings['full_name'],
        if (settings.containsKey('username')) 'username': settings['username'],
      });
    }

    // Update diabetic profile
    if (settings.containsKey('diabetic_profile')) {
      final profile = settings['diabetic_profile'] as Map<String, dynamic>;
      await _supabase.updateDiabeticProfile(profile);
    }

    // Update preferences
    if (settings.containsKey('preferences')) {
      final prefs = settings['preferences'] as Map<String, dynamic>;
      await _supabase.updateUserPreferences(prefs);
      await _prefs.setAllPreferences(prefs);
    }
  }

  // ============================================================================
  // DIABETIC PROFILE
  // ============================================================================

  /// Get diabetic profile for current user
  Future<Map<String, dynamic>?> getDiabeticProfile() async {
    return await _supabase.getDiabeticProfile();
  }

  /// Update diabetic profile
  Future<void> updateDiabeticProfile(Map<String, dynamic> profile) async {
    await _supabase.updateDiabeticProfile(profile);
  }

  // ============================================================================
  // GLUCOSE READINGS
  // ============================================================================

  /// Add a glucose reading
  Future<Map<String, dynamic>> addGlucoseReading({
    required double value,
    String unit = 'mg/dL',
    String readingType = 'before_meal',
    String? notes,
    DateTime? recordedAt,
  }) async {
    return await _supabase.addGlucoseReading(
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
    return await _supabase.getGlucoseReadings(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Get latest glucose reading
  Future<Map<String, dynamic>?> getLatestGlucoseReading() async {
    return await _supabase.getLatestGlucoseReading();
  }

  /// Get glucose chart data (last 7 hours)
  Future<Map<String, dynamic>> getGlucoseChartData() async {
    return await _supabase.getGlucoseChartData();
  }

  /// Get carbs chart data for the week
  Future<Map<String, dynamic>> getCarbsChartData() async {
    return await _supabase.getCarbsChartData();
  }

  /// Get activity chart data for the week
  Future<Map<String, dynamic>> getActivityChartData() async {
    return await _supabase.getActivityChartData();
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
    await _supabase.upsertHealthCard(
      cardType: cardType,
      value: value,
      unit: unit,
    );
  }

  /// Get health cards for today
  Future<List<Map<String, dynamic>>> getHealthCards() async {
    return await _supabase.getHealthCards();
  }

  // ============================================================================
  // REMINDERS
  // ============================================================================

  /// Get reminders for current user
  Future<List<dynamic>> getReminders() async {
    return await _supabase.getReminders();
  }

  /// Add a reminder
  Future<Map<String, dynamic>> addReminder({
    required String title,
    required String reminderType,
    required String scheduledTime,
    String? description,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    return await _supabase.addReminder(
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
    await _supabase.updateReminder(reminderId, data);
  }

  /// Update reminder status
  Future<void> updateReminderStatus(String reminderId, String status) async {
    await _supabase.updateReminderStatus(reminderId, status);
  }

  /// Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    await _supabase.deleteReminder(reminderId);
  }

  // ============================================================================
  // CHARTS DATA
  // ============================================================================

  /// Get charts data
  Future<Map<String, dynamic>> getCharts() async {
    return await _supabase.getGlucoseChartData();
  }

  // ============================================================================
  // LEGACY COMPATIBILITY METHODS
  // ============================================================================

  /// Get app strings (loads from JSON asset)
  Future<Map<String, dynamic>> getAppStrings() async {
    try {
      // Keep using local JSON for static strings
      final data = await rootBundle.loadString('assets/data/app_data.json');
      final jsonData = json.decode(data) as Map<String, dynamic>;
      return jsonData['app_strings'] as Map<String, dynamic>? ?? {};
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

  /// Clear all local data
  Future<void> clearAllData() async {
    await _prefs.clearAll();
  }
}

/// Custom exception for data service errors
class DataServiceException implements Exception {
  final String message;
  DataServiceException(this.message);

  @override
  String toString() => 'DataServiceException: $message';
}

// Import for rootBundle and json
