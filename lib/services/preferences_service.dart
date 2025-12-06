/// ============================================================================
/// PREFERENCES SERVICE - SharedPreferences Management
/// ============================================================================
///
/// This service manages all SharedPreferences operations for DiaCare.
/// It handles lightweight, fast-access data like:
/// - User session (logged in user ID)
/// - Theme preference
/// - Language/locale preference
/// - Glucose units preference
/// - Notification settings
/// - Onboarding completion status
/// - Last sync timestamp
///
/// Use this for data that needs to be accessed quickly and frequently.
/// ============================================================================

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  static SharedPreferences? _prefs;

  // Preference keys
  static const String keyLoggedInUserId = 'logged_in_user_id';
  static const String keyTheme = 'theme';
  static const String keyLocale = 'locale';
  static const String keyUnits = 'units';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyRememberMe = 'remember_me';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyFirstLaunch = 'first_launch';

  factory PreferencesService() => _instance;

  PreferencesService._internal();

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Save logged in user ID
  Future<bool> setLoggedInUserId(int userId) async {
    return await prefs.setInt(keyLoggedInUserId, userId);
  }

  /// Get logged in user ID (null if not logged in)
  int? getLoggedInUserId() {
    return prefs.getInt(keyLoggedInUserId);
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return prefs.containsKey(keyLoggedInUserId) &&
        prefs.getInt(keyLoggedInUserId) != null;
  }

  /// Clear session (logout)
  Future<bool> clearSession() async {
    return await prefs.remove(keyLoggedInUserId);
  }

  /// Set remember me preference
  Future<bool> setRememberMe(bool value) async {
    return await prefs.setBool(keyRememberMe, value);
  }

  /// Get remember me preference
  bool getRememberMe() {
    return prefs.getBool(keyRememberMe) ?? false;
  }

  // ============================================================================
  // THEME SETTINGS
  // ============================================================================

  /// Save theme preference
  Future<bool> setTheme(String theme) async {
    return await prefs.setString(keyTheme, theme);
  }

  /// Get theme preference (default: 'light')
  String getTheme() {
    return prefs.getString(keyTheme) ?? 'light';
  }

  /// Check if dark theme is enabled
  bool isDarkTheme() {
    return getTheme() == 'dark';
  }

  /// Check if system theme is enabled
  bool isSystemTheme() {
    return getTheme() == 'system';
  }

  // ============================================================================
  // LOCALE SETTINGS
  // ============================================================================

  /// Save locale preference
  Future<bool> setLocale(String languageCode) async {
    return await prefs.setString(keyLocale, languageCode);
  }

  /// Get locale preference (default: 'en')
  String getLocale() {
    return prefs.getString(keyLocale) ?? 'en';
  }

  /// Check if RTL language is selected
  bool isRtlLocale() {
    return getLocale() == 'ar';
  }

  // ============================================================================
  // UNITS SETTINGS
  // ============================================================================

  /// Save glucose units preference
  Future<bool> setUnits(String units) async {
    return await prefs.setString(keyUnits, units);
  }

  /// Get glucose units preference (default: 'mg/dL')
  String getUnits() {
    return prefs.getString(keyUnits) ?? 'mg/dL';
  }

  /// Check if using mmol/L units
  bool isUsingMmolL() {
    return getUnits() == 'mmol/L';
  }

  // ============================================================================
  // NOTIFICATION SETTINGS
  // ============================================================================

  /// Save notifications enabled preference
  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await prefs.setBool(keyNotificationsEnabled, enabled);
  }

  /// Get notifications enabled preference (default: true)
  bool getNotificationsEnabled() {
    return prefs.getBool(keyNotificationsEnabled) ?? true;
  }

  // ============================================================================
  // ONBOARDING SETTINGS
  // ============================================================================

  /// Mark onboarding as complete
  Future<bool> setOnboardingComplete(bool complete) async {
    return await prefs.setBool(keyOnboardingComplete, complete);
  }

  /// Check if onboarding is complete
  bool isOnboardingComplete() {
    return prefs.getBool(keyOnboardingComplete) ?? false;
  }

  /// Check if this is first launch
  bool isFirstLaunch() {
    return prefs.getBool(keyFirstLaunch) ?? true;
  }

  /// Mark first launch as complete
  Future<bool> setFirstLaunchComplete() async {
    return await prefs.setBool(keyFirstLaunch, false);
  }

  // ============================================================================
  // BIOMETRIC SETTINGS
  // ============================================================================

  /// Set biometric authentication enabled
  Future<bool> setBiometricEnabled(bool enabled) async {
    return await prefs.setBool(keyBiometricEnabled, enabled);
  }

  /// Check if biometric authentication is enabled
  bool isBiometricEnabled() {
    return prefs.getBool(keyBiometricEnabled) ?? false;
  }

  // ============================================================================
  // SYNC SETTINGS
  // ============================================================================

  /// Save last sync timestamp
  Future<bool> setLastSyncTime(DateTime time) async {
    return await prefs.setString(keyLastSyncTime, time.toIso8601String());
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    final timeStr = prefs.getString(keyLastSyncTime);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  // ============================================================================
  // ALL PREFERENCES
  // ============================================================================

  /// Get all preferences as a map
  Map<String, dynamic> getAllPreferences() {
    return {
      'theme': getTheme(),
      'locale': getLocale(),
      'units': getUnits(),
      'notifications_enabled': getNotificationsEnabled(),
      'onboarding_complete': isOnboardingComplete(),
      'biometric_enabled': isBiometricEnabled(),
      'remember_me': getRememberMe(),
    };
  }

  /// Set multiple preferences at once
  Future<void> setAllPreferences(Map<String, dynamic> prefs) async {
    if (prefs.containsKey('theme')) {
      await setTheme(prefs['theme']);
    }
    if (prefs.containsKey('locale')) {
      await setLocale(prefs['locale']);
    }
    if (prefs.containsKey('units')) {
      await setUnits(prefs['units']);
    }
    if (prefs.containsKey('notifications_enabled')) {
      await setNotificationsEnabled(prefs['notifications_enabled']);
    }
    if (prefs.containsKey('biometric_enabled')) {
      await setBiometricEnabled(prefs['biometric_enabled']);
    }
    if (prefs.containsKey('remember_me')) {
      await setRememberMe(prefs['remember_me']);
    }
  }

  // ============================================================================
  // CLEAR DATA
  // ============================================================================

  /// Clear all preferences (for logout or reset)
  Future<bool> clearAll() async {
    return await prefs.clear();
  }

  /// Clear only user-related preferences (keep app settings)
  Future<void> clearUserData() async {
    await prefs.remove(keyLoggedInUserId);
    await prefs.remove(keyOnboardingComplete);
    await prefs.remove(keyLastSyncTime);
    await prefs.remove(keyRememberMe);
  }
}
