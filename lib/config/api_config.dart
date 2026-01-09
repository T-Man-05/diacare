/// ============================================================================
/// API CONFIGURATION
/// ============================================================================
///
/// Central configuration for Django backend API
/// Update baseUrl based on your development environment
/// ============================================================================

class ApiConfig {
  /// Base URL for Django REST API
  ///
  /// For Android Emulator: Use 10.0.2.2 (maps to host machine)
  /// For Physical Device: Use your computer's WiFi IP (10.80.17.223)
  /// Make sure both devices are on the same WiFi network
  static const String baseUrl = 'http://10.80.17.223:8000/api/v1';

  // Alternative URLs for different platforms:
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator
  // static const String baseUrl = 'http://10.68.21.126:8000/api/v1'; // Old IP

  /// API endpoints
  static const String authToken = '/auth/token/';
  static const String authRefresh = '/auth/token/refresh/';
  static const String authRegister = '/auth/register/';
  static const String authProfile = '/auth/profile/';
  static const String authLogout = '/auth/logout/';
  static const String diabeticProfile = '/auth/diabetic-profile/';
  static const String diabeticProfileUpdate = '/auth/diabetic-profile/update/';

  static const String dashboard = '/health/dashboard/';
  static const String glucose = '/health/glucose/';
  static const String glucoseStats = '/health/glucose/statistics/';
  static const String glucoseRangeAnalysis = '/health/glucose/range_analysis/';
  static const String glucoseLatest = '/health/glucose/latest/';
  static const String glucoseChart = '/health/glucose/chart/';
  static const String healthCards = '/health/cards/';
  static const String healthCardsIncrement = '/health/cards/increment/';
  static const String insights = '/health/insights/';

  static const String reminders = '/reminders/';
  static const String remindersUpcoming = '/reminders/upcoming/';

  static const String chat = '/chat/send/';
  static const String chatHistory = '/chat/history/';
  static const String chatSessions = '/chat/sessions/';
  static const String chatDeleteSession = '/chat/delete_session/';

  /// JWT token expiry times
  static const Duration accessTokenExpiry = Duration(minutes: 15);
  static const Duration refreshTokenExpiry = Duration(days: 7);

  /// Request timeout
  static const Duration timeout = Duration(seconds: 30);
}
