/// ============================================================================
/// API CONFIGURATION
/// ============================================================================
///
/// Central configuration for Django backend API
/// Update baseUrl based on your development environment
/// ============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  /// Base URL for Django REST API
  ///
  /// For Web: Use localhost
  /// For Android Emulator: Use 10.0.2.2 (maps to host machine)
  /// For Physical Device: Use your computer's WiFi IP
  /// Make sure both devices are on the same WiFi network
  static String get baseUrl {
    // Prefer .env override so the app works across emulator/device without
    // editing code.
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      // Ensure no trailing slash because endpoints already start with '/'.
      return envUrl.trim().replaceAll(RegExp(r'/*$'), '');
    }

    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    // Default to Android emulator host mapping.
    return 'http://10.80.17.231:8000/api/v1';
  }

  // Alternative URLs for different platforms:
  // static const String _emulatorUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator

  /// API endpoints
  static const String authToken = '/auth/token/';
  static const String authRefresh = '/auth/token/refresh/';
  static const String authRegister = '/auth/register/';
  static const String authProfile = '/auth/profile/';
  static const String authLogout = '/auth/logout/';
  static const String diabeticProfile = '/auth/diabetic-profile/';
  static const String diabeticProfileUpdate = '/auth/diabetic-profile/update/';
  static const String authSettings = '/auth/settings/';
  static const String authSettingsUpdate = '/auth/settings/update/';

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

  static const String chat = '/chat/';  // POST to send message
  static const String chatHistory = '/chat/history/';
  static const String chatSessions = '/chat/sessions/';
  static const String chatDeleteSession = '/chat/sessions/';  // DELETE with session_id in path

  /// JWT token expiry times
  static const Duration accessTokenExpiry = Duration(minutes: 15);
  static const Duration refreshTokenExpiry = Duration(days: 7);

  /// Request timeout
  // Keep this near the UX threshold so timeouts surface quickly with a
  // user-friendly message.
  static const Duration timeout = Duration(seconds: 6);
}
