/// ============================================================================
/// APP DATA SOURCE - Abstract Interface for All Data Operations
/// ============================================================================
///
/// This is the ONLY abstraction through which UI accesses data.
/// All methods return typed domain models - NO Maps, NO JSON, NO backend types.
///
/// Implementation rules:
/// 1. All fromJson/parsing happens INSIDE implementations
/// 2. All backend-specific logic is encapsulated in implementations
/// 3. UI imports ONLY this interface, never implementations
/// ============================================================================

import 'models/models.dart';
import 'inputs/inputs.dart';

/// Abstract interface for all data operations
/// UI code depends ONLY on this interface
abstract class AppDataSource {
  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Check if a user is currently logged in
  bool get isLoggedIn;

  /// Get the current user's ID (null if not logged in)
  String? get currentUserId;

  /// Login with email and password
  /// Returns the user profile on success, null on failure
  Future<UserProfile?> login(LoginInput input);

  /// Logout the current user
  Future<void> logout();

  /// Register a new user
  /// Returns the new user's ID on success
  Future<String> registerUser(RegisterUserInput input);

  /// Check if an email is already registered
  Future<bool> emailExists(String email);

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  /// Get the current user's profile
  Future<UserProfile?> getCurrentUser();

  /// Update the current user's profile
  Future<void> updateUserProfile(UpdateProfileInput input);

  /// Update the user's password
  Future<void> updatePassword(String newPassword);

  /// Delete the current user's account
  Future<void> deleteAccount();

  // ============================================================================
  // DASHBOARD
  // ============================================================================

  /// Get complete dashboard data (glucose, reminders, health cards, chart)
  Future<DashboardData> getDashboardData();

  // ============================================================================
  // SETTINGS
  // ============================================================================

  /// Get complete settings data (profile, diabetic profile, preferences)
  Future<SettingsData> getSettingsData();

  /// Update settings data
  Future<void> updateSettingsData(SettingsData settings);

  // ============================================================================
  // DIABETIC PROFILE
  // ============================================================================

  /// Get the current user's diabetic profile
  Future<DiabeticProfile?> getDiabeticProfile();

  /// Update the diabetic profile
  Future<void> updateDiabeticProfile(UpdateDiabeticProfileInput input);

  // ============================================================================
  // PREFERENCES
  // ============================================================================

  /// Get current preferences
  AppPreferences getPreferences();

  /// Set theme preference
  Future<void> setTheme(String theme);

  /// Set locale preference
  Future<void> setLocale(String locale);

  /// Set units preference
  Future<void> setUnits(String units);

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled);

  /// Set onboarding complete
  Future<void> setOnboardingComplete(bool complete);

  // ============================================================================
  // GLUCOSE READINGS
  // ============================================================================

  /// Add a new glucose reading
  Future<GlucoseReading> addGlucoseReading(CreateGlucoseReadingInput input);

  /// Get glucose readings with optional filters
  Future<List<GlucoseReading>> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Get the latest glucose reading
  Future<GlucoseReading?> getLatestGlucoseReading();

  /// Get glucose chart data
  Future<GlucoseChartData> getGlucoseChartData();

  // ============================================================================
  // HEALTH CARDS
  // ============================================================================

  /// Get today's health cards
  Future<List<HealthCard>> getHealthCards();

  /// Update a health card value
  Future<void> updateHealthCard(UpdateHealthCardInput input);

  // ============================================================================
  // REMINDERS
  // ============================================================================

  /// Get all reminders for the current user
  Future<List<Reminder>> getReminders();

  /// Add a new reminder
  Future<Reminder> addReminder(CreateReminderInput input);

  /// Update an existing reminder
  Future<void> updateReminder(String reminderId, UpdateReminderInput input);

  /// Update reminder status
  Future<void> updateReminderStatus(String reminderId, String status);

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId);

  // ============================================================================
  // CHARTS
  // ============================================================================

  /// Get carbs chart data for insights
  Future<CarbsChartData> getCarbsChartData();

  /// Get activity chart data for insights
  Future<ActivityChartData> getActivityChartData();

  // ============================================================================
  // INSIGHTS
  // ============================================================================

  /// Get comprehensive health insights including statistics, trends, and patterns
  Future<InsightsData> getInsights();

  // ============================================================================
  // UTILITY
  // ============================================================================

  /// Clear all local data
  Future<void> clearAllData();

  /// Get app localization strings
  Future<Map<String, dynamic>> getAppStrings();
}

/// Exception thrown by data source operations
class DataSourceException implements Exception {
  final String message;
  final String? code;

  /// Human-friendly message ready for UI display (preferred when present).
  final String? uiMessage;

  /// Internal/dev-only message (optional; typically only present in debug).
  final String? devMessage;

  /// Optional field validation errors.
  final Map<String, List<String>>? fieldErrors;

  /// Optional HTTP status code when the error comes from an API response.
  final int? httpStatus;

  const DataSourceException(
    this.message, {
    this.code,
    this.uiMessage,
    this.devMessage,
    this.fieldErrors,
    this.httpStatus,
  });

  String get displayMessage => uiMessage ?? message;

  @override
  String toString() =>
      'DataSourceException: $message${code != null ? ' ($code)' : ''}';
}
