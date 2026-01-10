/// ============================================================================
/// DJANGO DATA SOURCE - Django REST API Implementation of AppDataSource
/// ============================================================================
///
/// This class implements the AppDataSource interface using Django backend.
/// ALL JSON parsing, HTTP requests, and backend-specific logic is here.
/// UI code NEVER sees Maps, JSON, or HTTP types.
///
/// Features:
/// - JWT token management with automatic refresh
/// - BFF (Backend for Frontend) pattern for dashboard
/// - Proper error handling and retry logic
/// - Clean separation from UI code
/// ============================================================================

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../domain/app_data_source.dart';
import '../../domain/models/models.dart';
import '../../domain/inputs/inputs.dart';
import '../../services/preferences_service.dart';

/// Django REST API implementation of AppDataSource
class DjangoDataSource implements AppDataSource {
  final PreferencesService _prefs;
  final String _baseUrl = ApiConfig.baseUrl;

  String? _accessToken;
  String? _refreshToken;
  String? _currentUserId;

  // Token loading is async; many cubits call into the data source immediately
  // on startup. Track the in-flight load so we can await it before auth checks.
  Future<void>? _tokensLoadFuture;

  DjangoDataSource(this._prefs) {
    _tokensLoadFuture = _loadTokens();
  }

  /// Ensure the data source is fully initialized (tokens loaded from storage).
  ///
  /// Call this once during app startup (before reading `isLoggedIn`).
  Future<void> init() async {
    await (_tokensLoadFuture ??= _loadTokens());
  }

  Future<void> _ensureInitialized() async {
    await (_tokensLoadFuture ??= _loadTokens());
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  DataSourceException _fromNetworkException(
    Object error, {
    String? fallbackCode,
    String? fallbackMessage,
  }) {
    if (error is DataSourceException) return error;

    if (error is TimeoutException) {
      return DataSourceException(
        fallbackMessage ?? 'Request timed out',
        code: 'timeout',
        uiMessage: "We couldn't load your data in time. Please try refreshing.",
      );
    }

    if (error is SocketException) {
      return DataSourceException(
        fallbackMessage ?? 'No internet connection',
        code: 'no_internet',
        uiMessage:
            'No internet connection. Please check your Wi-Fi or data.',
      );
    }

    if (error is http.ClientException) {
      return DataSourceException(
        fallbackMessage ?? 'Network error',
        code: 'network_error',
        uiMessage:
            'No internet connection. Please check your Wi-Fi or data.',
      );
    }

    // Fallback
    return DataSourceException(
      fallbackMessage ?? 'Unexpected error',
      code: fallbackCode ?? 'unexpected_error',
      uiMessage:
          "We're having trouble connecting to the server right now. We are working on fixing it.",
    );
  }

  DataSourceException _fromErrorResponse(
    http.Response response, {
    required String fallbackMessage,
    String? fallbackCode,
  }) {
    // Try to parse our standardized error schema.
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'];
        final err = decoded['error'];

        if (success == false && err is Map<String, dynamic>) {
          final code = (err['code'] as String?) ?? fallbackCode;
          final uiMessage = (err['ui_message'] as String?) ??
              (err['message'] as String?) ??
              fallbackMessage;
          final devMessage = err['dev_message'] as String?;

          Map<String, List<String>>? fieldErrors;
          final fe = err['field_errors'];
          if (fe is Map) {
            fieldErrors = <String, List<String>>{};
            fe.forEach((key, value) {
              final k = key.toString();
              if (value is List) {
                fieldErrors![k] = value.map((e) => e.toString()).toList();
              } else if (value != null) {
                fieldErrors![k] = [value.toString()];
              }
            });
            if (fieldErrors!.isEmpty) fieldErrors = null;
          }

          return DataSourceException(
            fallbackMessage,
            code: code,
            uiMessage: uiMessage,
            devMessage: devMessage,
            fieldErrors: fieldErrors,
            httpStatus: response.statusCode,
          );
        }

        // Older backend schema (legacy): {success:false, error:{code,message,details}}
        if (success == false && err is Map<String, dynamic>) {
          final code = (err['code'] as String?) ?? fallbackCode;
          final uiMessage = (err['message'] as String?) ?? fallbackMessage;
          return DataSourceException(
            fallbackMessage,
            code: code,
            uiMessage: uiMessage,
            httpStatus: response.statusCode,
          );
        }
      }
    } catch (_) {
      // Ignore parse errors and fallback.
    }

    // Status-code based fallbacks (for non-standard responses).
    if (response.statusCode == 401) {
      return DataSourceException(
        fallbackMessage,
        code: 'session_expired',
        uiMessage: 'Your session has expired. Please log in again to continue.',
        httpStatus: response.statusCode,
      );
    }

    if (response.statusCode == 404) {
      return DataSourceException(
        fallbackMessage,
        code: 'not_found',
        uiMessage:
            "We couldn't find the information you were looking for. It may have been deleted.",
        httpStatus: response.statusCode,
      );
    }

    if (response.statusCode == 408 || response.statusCode == 504) {
      return DataSourceException(
        fallbackMessage,
        code: 'timeout',
        uiMessage: "We couldn't load your data in time. Please try refreshing.",
        httpStatus: response.statusCode,
      );
    }

    if (response.statusCode >= 500) {
      return DataSourceException(
        fallbackMessage,
        code: 'service_unavailable',
        uiMessage:
            "We're having trouble connecting to the server right now. We are working on fixing it.",
        httpStatus: response.statusCode,
      );
    }

    return DataSourceException(
      fallbackMessage,
      code: fallbackCode,
      uiMessage:
          'Some information seems to be missing or incorrect. Please check the highlighted fields.',
      httpStatus: response.statusCode,
    );
  }

  // ============================================================================
  // HELPER: Safe parsing for numbers (handles both strings and numbers)
  // ============================================================================
  
  /// Safely parse a value to double, handling both num and String types
  double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely parse a value to int, handling both num and String types
  int _safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Load tokens from SharedPreferences
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _currentUserId = prefs.getString('user_id');
  }

  /// Save tokens to SharedPreferences
  Future<void> _saveTokens(String access, String refresh, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    await prefs.setString('user_id', userId);
    _accessToken = access;
    _refreshToken = refresh;
    _currentUserId = userId;
  }

  /// Clear tokens from SharedPreferences
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    _accessToken = null;
    _refreshToken = null;
    _currentUserId = null;
  }

  /// Get headers with auth token
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  /// Ensure user is authenticated
  Future<void> _ensureAuthenticated() async {
    // If tokens were persisted from a previous session, make sure we load them
    // before concluding that the user is not authenticated.
    await _ensureInitialized();
    if (_accessToken == null) {
      throw const DataSourceException(
        'Not authenticated',
        code: 'not_authenticated',
      );
    }
  }

  Future<void> _patchSettings(Map<String, dynamic> body) async {
    await _ensureAuthenticated();

    final response = await _makeAuthenticatedRequest(() => http
        .patch(
          Uri.parse('$_baseUrl${ApiConfig.authSettingsUpdate}'),
          headers: _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _fromErrorResponse(
        response,
        fallbackMessage: 'Failed to update settings',
        fallbackCode: 'settings_update_failed',
      );
    }
  }

  /// Get auth headers for authenticated requests
  // Future<Map<String, String>> _getAuthHeaders() async {
  //   await _ensureAuthenticated();
  //   return {
  //     'Content-Type': 'application/json',
  //     'Authorization': 'Bearer $_accessToken',
  //   };
  // }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.authRefresh}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': _refreshToken}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        _accessToken = data['access'];
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Make authenticated request with auto token refresh
  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request();
    } on Object catch (e) {
      throw _fromNetworkException(e);
    }

    // If token expired, refresh and retry
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await request();
      } else {
        // Refresh failed, force logout
        await logout();
        throw const DataSourceException(
          'Session expired, please login again',
          code: 'session_expired',
        );
      }
    }

    return response;
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  @override
  bool get isLoggedIn => _accessToken != null && _currentUserId != null;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<UserProfile?> login(LoginInput input) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.authToken}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': input.email.toLowerCase().trim(),
              'password': input.password,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Get user profile to extract user ID
        _accessToken = data['access'];
        final profileResponse = await http
            .get(
              Uri.parse('$_baseUrl${ApiConfig.authProfile}'),
              headers: _getHeaders(),
            )
            .timeout(ApiConfig.timeout);

        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          await _saveTokens(
            data['access'],
            data['refresh'],
            profileData['id'].toString(),
          );
          // Keep PreferencesService session flag in sync (used by some flows).
          final id = int.tryParse(profileData['id'].toString());
          if (id != null) {
            await _prefs.setLoggedInUserId(id);
          }
          return _parseUserProfile(profileData);
        }
      }

      throw const DataSourceException(
        'Login failed: Invalid credentials',
        code: 'invalid_credentials',
      );
    } catch (e) {
      if (e is DataSourceException) rethrow;
      throw DataSourceException('Login failed: ${e.toString()}',
          code: 'network_error');
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await http
            .post(
              Uri.parse('$_baseUrl${ApiConfig.authLogout}'),
              headers: _getHeaders(),
              body: jsonEncode({'refresh': _refreshToken}),
            )
            .timeout(ApiConfig.timeout);
      }
    } catch (e) {
      // Ignore logout errors, always clear local tokens
    }
    await _clearTokens();
    await _prefs.clearSession();
  }

  @override
  Future<String> registerUser(RegisterUserInput input) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.authRegister}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': input.email.toLowerCase().trim(),
              'full_name': input.fullName,
              'password': input.password,
              'password_confirm': input.password,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final userId = data['user']['id'].toString();

        // Save tokens from registration
        await _saveTokens(
          data['tokens']['access'],
          data['tokens']['refresh'],
          userId,
        );

        // Update additional profile data
        await updateUserProfile(UpdateProfileInput(
          dateOfBirth: input.dateOfBirth,
          gender: input.gender,
          height: input.height,
          weight: input.weight,
        ));

        return userId;
      } else {
        final error = jsonDecode(response.body);
        throw DataSourceException(
          'Registration failed: ${error['error'] ?? error.toString()}',
          code: 'registration_failed',
        );
      }
    } catch (e) {
      if (e is DataSourceException) rethrow;
      throw DataSourceException('Registration failed: ${e.toString()}',
          code: 'network_error');
    }
  }

  @override
  Future<bool> emailExists(String email) async {
    // Django backend doesn't have this endpoint yet
    // For now, try to register and see if email already exists error is returned
    return false;
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  @override
  Future<UserProfile?> getCurrentUser() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.authProfile}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        return _parseUserProfile(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(UpdateProfileInput input) async {
    await _ensureAuthenticated();

    try {
      final body = <String, dynamic>{};
      if (input.fullName != null) body['full_name'] = input.fullName;
      if (input.username != null) body['username'] = input.username;
      if (input.dateOfBirth != null) body['date_of_birth'] = input.dateOfBirth;
      if (input.gender != null) body['gender'] = input.gender;
      if (input.height != null) body['height'] = input.height;
      if (input.weight != null) body['weight'] = input.weight;
      if (input.profileImageUrl != null) {
        body['profile_image_url'] = input.profileImageUrl;
      }

      await _makeAuthenticatedRequest(() => http
          .patch(
            Uri.parse('$_baseUrl${ApiConfig.authProfile}'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));
    } catch (e) {
      throw DataSourceException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _ensureAuthenticated();
    // Django backend doesn't have change password endpoint yet
    // This would be implemented when backend adds the endpoint
    throw const DataSourceException('Password change not implemented yet');
  }

  @override
  Future<void> deleteAccount() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .delete(
            Uri.parse('$_baseUrl${ApiConfig.authProfile}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _fromErrorResponse(
          response,
          fallbackMessage: 'Failed to delete account',
          fallbackCode: 'account_delete_failed',
        );
      }
      await _clearTokens();
      await _prefs.clearSession();
    } catch (e) {
      throw _fromNetworkException(
        e,
        fallbackCode: 'account_delete_failed',
        fallbackMessage: 'Failed to delete account',
      );
    }
  }

  // ============================================================================
  // DASHBOARD
  // ============================================================================

  @override
  Future<DashboardData> getDashboardData() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.dashboard}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseDashboardData(data);
      }

      throw _fromErrorResponse(
        response,
        fallbackMessage: 'Failed to load dashboard data',
        fallbackCode: 'dashboard_load_failed',
      );
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SETTINGS
  // ============================================================================

  @override
  Future<SettingsData> getSettingsData() async {
    await _ensureAuthenticated();

    try {
      // Preferred: backend BFF settings endpoint (profile + diabetic + preferences)
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.authSettings}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final payload = (decoded is Map<String, dynamic> && decoded['data'] is Map)
            ? decoded['data'] as Map<String, dynamic>
            : (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});

        final profileData = payload['profile'] as Map<String, dynamic>?;
        final diabeticData = payload['diabetic_profile'] as Map<String, dynamic>?;
        final prefsData = payload['preferences'] as Map<String, dynamic>?;

        final preferences = AppPreferences(
          theme: prefsData?['theme']?.toString() ?? _prefs.getTheme(),
          locale: prefsData?['locale']?.toString() ?? _prefs.getLocale(),
          units: prefsData?['units']?.toString() ?? _prefs.getUnits(),
          notificationsEnabled:
              (prefsData?['notifications_enabled'] as bool?) ?? _prefs.getNotificationsEnabled(),
          onboardingComplete:
              (prefsData?['onboarding_complete'] as bool?) ?? _prefs.getOnboardingComplete(),
        );

        // Keep local preferences in sync with server.
        await _prefs.setTheme(preferences.theme);
        await _prefs.setLocale(preferences.locale);
        await _prefs.setUnits(preferences.units);
        await _prefs.setNotificationsEnabled(preferences.notificationsEnabled);
        await _prefs.setOnboardingComplete(preferences.onboardingComplete);

        return SettingsData(
          profile: profileData != null ? _parseUserProfile(profileData) : (await getCurrentUser())!,
          diabeticProfile: diabeticData != null
              ? _parseDiabeticProfile(diabeticData)
              : (await getDiabeticProfile())!,
          preferences: preferences,
        );
      }

      throw _fromErrorResponse(
        response,
        fallbackMessage: 'Failed to load settings',
        fallbackCode: 'settings_load_failed',
      );
    } catch (e) {
      if (e is DataSourceException && e.code == 'not_authenticated') {
        // Normal when app starts before login or before session is restored.
      } else {
        debugPrint('Error loading settings: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateSettingsData(SettingsData settings) async {
    await _ensureAuthenticated();

    try {
      // Persist everything in one backend call (BFF settings write)
      await _patchSettings({
        'theme': settings.theme,
        'locale': settings.locale,
        'units': settings.units,
        'notifications_enabled': settings.notificationsEnabled,
        'profile': {
          'full_name': settings.fullName,
          'username': settings.username,
          'profile_image_url': settings.profileImageUrl,
        },
        'diabetic_profile': {
          'diabetic_type': settings.diabeticType,
          'treatment_type': settings.treatmentType,
          'min_glucose': settings.minGlucose,
          'max_glucose': settings.maxGlucose,
        },
      });

      // Update local cache too
      await _prefs.setTheme(settings.theme);
      await _prefs.setLocale(settings.locale);
      await _prefs.setUnits(settings.units);
      await _prefs.setNotificationsEnabled(settings.notificationsEnabled);
    } catch (e) {
      throw DataSourceException('Failed to update settings: ${e.toString()}');
    }
  }

  // ============================================================================
  // DIABETIC PROFILE
  // ============================================================================

  @override
  Future<DiabeticProfile?> getDiabeticProfile() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.diabeticProfile}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseDiabeticProfile(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting diabetic profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateDiabeticProfile(UpdateDiabeticProfileInput input) async {
    await _ensureAuthenticated();

    try {
      final body = <String, dynamic>{};
      if (input.diabeticType != null)
        body['diabetic_type'] = input.diabeticType;
      if (input.treatmentType != null)
        body['treatment_type'] = input.treatmentType;
      if (input.minGlucose != null) body['min_glucose'] = input.minGlucose;
      if (input.maxGlucose != null) body['max_glucose'] = input.maxGlucose;

      await _makeAuthenticatedRequest(() => http
          .patch(
            Uri.parse('$_baseUrl${ApiConfig.diabeticProfileUpdate}'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));
    } catch (e) {
      throw DataSourceException(
          'Failed to update diabetic profile: ${e.toString()}');
    }
  }

  // ============================================================================
  // PREFERENCES
  // ============================================================================

  @override
  AppPreferences getPreferences() {
    return AppPreferences(
      theme: _prefs.getTheme(),
      locale: _prefs.getLocale(),
      units: _prefs.getUnits(),
      notificationsEnabled: _prefs.getNotificationsEnabled(),
      onboardingComplete: _prefs.getOnboardingComplete(),
    );
  }

  @override
  Future<void> setTheme(String theme) async {
    await _prefs.setTheme(theme);
    // If user is logged in, also persist to backend
    try {
      if (isLoggedIn) {
        await _patchSettings({'theme': theme});
      }
    } catch (_) {
      // Don't block UI on backend sync; local cache is still updated.
    }
  }

  @override
  Future<void> setLocale(String locale) async {
    await _prefs.setLocale(locale);
    try {
      if (isLoggedIn) {
        await _patchSettings({'locale': locale});
      }
    } catch (_) {}
  }

  @override
  Future<void> setUnits(String units) async {
    await _prefs.setUnits(units);
    try {
      if (isLoggedIn) {
        await _patchSettings({'units': units});
      }
    } catch (_) {}
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    try {
      if (isLoggedIn) {
        await _patchSettings({'notifications_enabled': enabled});
      }
    } catch (_) {}
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setOnboardingComplete(complete);
  }

  // ============================================================================
  // GLUCOSE READINGS
  // ============================================================================

  @override
  Future<GlucoseReading> addGlucoseReading(
      CreateGlucoseReadingInput input) async {
    await _ensureAuthenticated();

    try {
      final body = {
        'value': input.value,
        'unit': input.unit,
        'reading_type': input.readingType,
        'notes': input.notes,
        'recorded_at': input.recordedAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      };

      final response = await _makeAuthenticatedRequest(() => http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.glucose}'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _parseGlucoseReading(data);
      }

      throw const DataSourceException('Failed to add glucose reading');
    } catch (e) {
      debugPrint('Error adding glucose reading: $e');
      rethrow;
    }
  }

  @override
  Future<List<GlucoseReading>> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    await _ensureAuthenticated();

    try {
      var url = '$_baseUrl${ApiConfig.glucose}';
      final queryParams = <String>[];

      if (startDate != null) {
        queryParams.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('end_date=${endDate.toIso8601String()}');
      }
      if (limit != null) queryParams.add('limit=$limit');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _makeAuthenticatedRequest(() => http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both paginated results and direct list
        final readings = data is List 
            ? data 
            : (data['results'] as List?) ?? [];
        return readings.map((r) => _parseGlucoseReading(r as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting glucose readings: $e');
      return [];
    }
  }

  @override
  Future<GlucoseReading?> getLatestGlucoseReading() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.glucoseLatest}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGlucoseReading(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting latest glucose reading: $e');
      return null;
    }
  }

  @override
  Future<GlucoseChartData> getGlucoseChartData() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.glucoseChart}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGlucoseChartData(data);
      }

      return const GlucoseChartData(
        beforeMealValues: [],
        afterMealValues: [],
        hours: [],
        hasData: false,
        totalRecords: 0,
      );
    } catch (e) {
      debugPrint('Error getting glucose chart data: $e');
      return const GlucoseChartData(
        beforeMealValues: [],
        afterMealValues: [],
        hours: [],
        hasData: false,
        totalRecords: 0,
      );
    }
  }

  // ============================================================================
  // HEALTH CARDS
  // ============================================================================

  @override
  Future<List<HealthCard>> getHealthCards() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.healthCards}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both paginated results and direct list
        final cards = data is List 
            ? data 
            : (data['results'] as List?) ?? [];
        return cards.map((c) => _parseHealthCard(c as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting health cards: $e');
      return [];
    }
  }

  @override
  Future<void> updateHealthCard(UpdateHealthCardInput input) async {
    await _ensureAuthenticated();

    try {
      final body = {
        'card_type': input.cardType,
        'increment': input.value,
      };

      final response = await _makeAuthenticatedRequest(() => http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.healthCardsIncrement}'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _fromErrorResponse(
          response,
          fallbackMessage: 'Failed to update health card',
          fallbackCode: 'health_card_update_failed',
        );
      }
    } catch (e) {
      throw _fromNetworkException(
        e,
        fallbackCode: 'health_card_update_failed',
        fallbackMessage: 'Failed to update health card',
      );
    }
  }

  // ============================================================================
  // REMINDERS
  // ============================================================================

  @override
  Future<List<Reminder>> getReminders() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.reminders}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle wrapped response: {'success': true, 'data': [...]}
        List<dynamic> reminders;
        if (data is Map<String, dynamic>) {
          if (data['data'] is List) {
            reminders = data['data'] as List;
          } else if (data['results'] is List) {
            reminders = data['results'] as List;
          } else {
            reminders = [];
          }
        } else if (data is List) {
          reminders = data;
        } else {
          reminders = [];
        }

        return reminders
            .map((r) => _parseReminder(r as Map<String, dynamic>))
            .toList();
      }

      throw _fromErrorResponse(
        response,
        fallbackMessage: 'Failed to load reminders',
        fallbackCode: 'reminders_load_failed',
      );
    } catch (e) {
      debugPrint('Error getting reminders: $e');
      throw _fromNetworkException(
        e,
        fallbackCode: 'reminders_load_failed',
        fallbackMessage: 'Failed to load reminders',
      );
    }
  }

  @override
  Future<Reminder> addReminder(CreateReminderInput input) async {
    await _ensureAuthenticated();

    try {
      // Ensure scheduled_time is in HH:MM:SS format for backend
      String scheduledTime = input.scheduledTime;
      if (scheduledTime.isNotEmpty && scheduledTime.split(':').length == 2) {
        scheduledTime = '$scheduledTime:00';  // Add seconds if missing
      }
      
      final body = {
        'title': input.title,
        'reminder_type': input.reminderType,
        'scheduled_time': scheduledTime,
        'description': input.description,
        'is_recurring': input.isRecurring,
        'recurrence_pattern': input.recurrencePattern,
      };

      final response = await _makeAuthenticatedRequest(() => http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.reminders}'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Handle wrapped response: {'success': true, 'data': {...}}
        final reminderData = data is Map<String, dynamic> && data['data'] != null
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        return _parseReminder(reminderData);
      }

      throw _fromErrorResponse(
        response,
        fallbackMessage: 'Failed to add reminder',
        fallbackCode: 'reminder_create_failed',
      );
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateReminder(
      String reminderId, UpdateReminderInput input) async {
    await _ensureAuthenticated();

    try {
      final body = <String, dynamic>{};
      if (input.title != null) body['title'] = input.title;
      if (input.reminderType != null)
        body['reminder_type'] = input.reminderType;
      if (input.scheduledTime != null) {
        // Ensure scheduled_time is in HH:MM:SS format for backend
        String scheduledTime = input.scheduledTime!;
        if (scheduledTime.isNotEmpty && scheduledTime.split(':').length == 2) {
          scheduledTime = '$scheduledTime:00';  // Add seconds if missing
        }
        body['scheduled_time'] = scheduledTime;
      }
      if (input.description != null) body['description'] = input.description;
      if (input.isEnabled != null) body['is_enabled'] = input.isEnabled;
      if (input.status != null) body['status'] = input.status;

      final response = await _makeAuthenticatedRequest(() => http
          .patch(
            Uri.parse('$_baseUrl${ApiConfig.reminders}$reminderId/'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _fromErrorResponse(
          response,
          fallbackMessage: 'Failed to update reminder',
          fallbackCode: 'reminder_update_failed',
        );
      }
    } catch (e) {
      throw _fromNetworkException(
        e,
        fallbackCode: 'reminder_update_failed',
        fallbackMessage: 'Failed to update reminder',
      );
    }
  }

  @override
  Future<void> updateReminderStatus(String reminderId, String status) async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .patch(
            Uri.parse('$_baseUrl${ApiConfig.reminders}$reminderId/'),
            headers: _getHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _fromErrorResponse(
          response,
          fallbackMessage: 'Failed to update reminder status',
          fallbackCode: 'reminder_status_update_failed',
        );
      }
    } catch (e) {
      throw _fromNetworkException(
        e,
        fallbackCode: 'reminder_status_update_failed',
        fallbackMessage: 'Failed to update reminder status',
      );
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .delete(
            Uri.parse('$_baseUrl${ApiConfig.reminders}$reminderId/'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _fromErrorResponse(
          response,
          fallbackMessage: 'Failed to delete reminder',
          fallbackCode: 'reminder_delete_failed',
        );
      }
    } catch (e) {
      throw _fromNetworkException(
        e,
        fallbackCode: 'reminder_delete_failed',
        fallbackMessage: 'Failed to delete reminder',
      );
    }
  }

  // ============================================================================
  // CHARTS
  // ============================================================================

  @override
  Future<CarbsChartData> getCarbsChartData() async {
    await _ensureAuthenticated();

    try {
      final healthCards = await getHealthCards();
      return _parseCarbsChartData(healthCards);
    } catch (e) {
      debugPrint('Error getting carbs chart data: $e');
      return const CarbsChartData(
        values: [],
        days: [],
        hasData: false,
        totalRecords: 0,
      );
    }
  }

  @override
  Future<ActivityChartData> getActivityChartData() async {
    await _ensureAuthenticated();

    try {
      final healthCards = await getHealthCards();
      return _parseActivityChartData(healthCards);
    } catch (e) {
      debugPrint('Error getting activity chart data: $e');
      return const ActivityChartData(
        values: [],
        hours: [],
        hasData: false,
        totalRecords: 0,
      );
    }
  }

  // ============================================================================
  // INSIGHTS
  // ============================================================================

  @override
  Future<InsightsData> getInsights() async {
    await _ensureAuthenticated();

    try {
      final response = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.insights}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseInsightsData(data);
      }

      throw _fromErrorResponse(
        response,
        fallbackMessage: 'Failed to load insights',
        fallbackCode: 'insights_load_failed',
      );
    } catch (e) {
      debugPrint('Error loading insights: $e');
      throw _fromNetworkException(
        e,
        fallbackCode: 'insights_load_failed',
        fallbackMessage: 'Failed to load insights',
      );
    }
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  @override
  Future<void> clearAllData() async {
    await _clearTokens();
    await _prefs.clearSession();
  }

  @override
  Future<Map<String, dynamic>> getAppStrings() async {
    return {};
  }

  // ============================================================================
  // JSON PARSING METHODS
  // ============================================================================

  UserProfile _parseUserProfile(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      profileImageUrl: json['profile_image_url'],
    );
  }

  DiabeticProfile _parseDiabeticProfile(Map<String, dynamic> json) {
    return DiabeticProfile(
      diabeticType: json['diabetic_type'] ?? 'Type 1',
      treatmentType: json['treatment_type'] ?? 'Insulin',
      minGlucose: json['min_glucose'] ?? 70,
      maxGlucose: json['max_glucose'] ?? 180,
    );
  }

  GlucoseReading _parseGlucoseReading(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id'].toString(),
      value: _safeDouble(json['value']),
      unit: json['unit'] ?? 'mg/dL',
      readingType: _parseGlucoseReadingType(json['reading_type']),
      notes: json['notes'],
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'])
          : DateTime.now(),
    );
  }

  GlucoseReadingType _parseGlucoseReadingType(String? type) {
    switch (type?.toLowerCase()) {
      case 'before_meal':
        return GlucoseReadingType.beforeMeal;
      case 'after_meal':
        return GlucoseReadingType.afterMeal;
      case 'fasting':
        return GlucoseReadingType.fasting;
      case 'bedtime':
        return GlucoseReadingType.bedtime;
      default:
        return GlucoseReadingType.random;
    }
  }

  HealthCard _parseHealthCard(Map<String, dynamic> json) {
    return HealthCard(
      id: json['id'].toString(),
      type: _parseHealthCardType(json['card_type']),
      value: _safeDouble(json['value']),
      unit: json['unit'] ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  HealthCardType _parseHealthCardType(String? type) {
    switch (type?.toLowerCase()) {
      case 'carbs':
        return HealthCardType.carbs;
      case 'activity':
        return HealthCardType.activity;
      case 'water':
        return HealthCardType.water;
      case 'pills':
        return HealthCardType.pills;
      case 'insulin':
        return HealthCardType.insulin;
      case 'weight':
        return HealthCardType.weight;
      default:
        return HealthCardType.water; // Default to water instead of carbs
    }
  }

  Reminder _parseReminder(Map<String, dynamic> json) {
    // Backend returns scheduled_time as "HH:MM:SS" format
    // Reminder model expects just "HH:MM" format
    String scheduledTime = '';
    final rawTime = json['scheduled_time'];
    if (rawTime != null && rawTime.toString().isNotEmpty) {
      final timeStr = rawTime.toString();
      // If it's in HH:MM:SS format, extract HH:MM
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          scheduledTime = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        } else {
          scheduledTime = timeStr;
        }
      } else {
        // Try parsing as ISO datetime (fallback)
        try {
          final parsed = DateTime.parse(timeStr);
          scheduledTime = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          scheduledTime = timeStr;
        }
      }
    }
    
    return Reminder(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      reminderType: json['reminder_type'] ?? '',
      scheduledTime: scheduledTime,
      description: json['description'],
      isEnabled: json['is_enabled'] ?? true,
      isRecurring: json['is_recurring'] ?? false,
      recurrencePattern: json['recurrence_pattern'],
      status: _parseReminderStatus(json['status']),
    );
  }

  ReminderStatus _parseReminderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'done':
        return ReminderStatus.done;
      case 'completed':
        return ReminderStatus.completed;
      case 'skipped':
        return ReminderStatus.skipped;
      case 'snoozed':
        return ReminderStatus.snoozed;
      default:
        return ReminderStatus.pending;
    }
  }

  DashboardData _parseDashboardData(Map<String, dynamic> json) {
    // Backend response structure:
    // {
    //   'user': { 'id', 'full_name', 'email', 'profile_image_url' },
    //   'glucose': { 'latest': {...}, 'trend': [...], 'stats': {...}, 'range_analysis': {...}, 'target_range': {...} },
    //   'health_cards': { 'water': {...}, 'pills': {...}, 'activity': {...}, 'weight': {...} },
    //   'reminders': [ ... ],
    //   'goals': { ... },
    //   'timestamp': '...'
    // }
    
    // Parse user info for greeting
    final user = json['user'] as Map<String, dynamic>?;
    final userName = user?['full_name'] ?? 'User';
    final greeting = _getTimeBasedGreeting(userName);

    // Parse glucose data - backend returns nested 'glucose' object
    final glucoseData = json['glucose'] as Map<String, dynamic>?;
    final latestGlucoseData = glucoseData?['latest'] as Map<String, dynamic>?;
    final targetRange = glucoseData?['target_range'] as Map<String, dynamic>?;
    
    final latestGlucose = latestGlucoseData != null
        ? LatestGlucose(
            value: _safeDouble(latestGlucoseData['value']),
            unit: latestGlucoseData['unit']?.toString() ?? 'mg/dL',
            status: latestGlucoseData['status']?.toString() ?? 'No data',
            readingType: latestGlucoseData['reading_type'] != null
                ? _parseGlucoseReadingType(latestGlucoseData['reading_type'].toString())
                : null,
          )
        : const LatestGlucose(
            value: 0.0,
            unit: 'mg/dL',
            status: 'No data',
          );

    // Parse next reminder
    // Prefer backend `next_reminder` (single closest reminder), but fall back to `reminders` list.
    final nextReminderJson = json['next_reminder'];
    Reminder? nextReminder;

    if (nextReminderJson is Map<String, dynamic>) {
      nextReminder = _parseReminder(nextReminderJson);
    } else {
      final remindersList = json['reminders'] as List?;
      if (remindersList != null && remindersList.isNotEmpty) {
        final reminders = remindersList
            .map((r) => _parseReminder(r as Map<String, dynamic>))
            .toList();

        // Defensive: pick the closest enabled + not-done reminder.
        final now = DateTime.now();
        final candidates = reminders.where((r) => r.isEnabled && !r.isDone).toList();
        if (candidates.isNotEmpty) {
          candidates.sort((a, b) {
            final aRemaining = a.timeRemaining(now) ?? const Duration(days: 9999);
            final bRemaining = b.timeRemaining(now) ?? const Duration(days: 9999);
            return aRemaining.compareTo(bRemaining);
          });
          nextReminder = candidates.first;
        }
      }
    }

    // Parse late reminders count
    // Prefer backend computed count; fall back to computing from reminders list if present.
    int lateRemindersCount = _safeInt(json['late_reminders_count'], 0);
    if (lateRemindersCount == 0) {
      final remindersList = json['reminders'] as List?;
      if (remindersList != null && remindersList.isNotEmpty) {
        final now = DateTime.now();
        final reminders = remindersList
            .map((r) => _parseReminder(r as Map<String, dynamic>))
            .toList();
        lateRemindersCount = reminders.where((r) => r.isLate(now)).length;
      }
    }

    // Parse health cards - backend returns Dict keyed by card_type
    final healthCardsData = json['health_cards'];
    List<HealthCard> healthCards = [];
    
    if (healthCardsData != null && healthCardsData is Map) {
      // Backend returns: { 'water': {...}, 'pills': {...}, ... }
      healthCardsData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          healthCards.add(_parseHealthCardFromDict(key.toString(), value));
        }
      });
    } else if (healthCardsData != null && healthCardsData is List) {
      // Fallback: handle as list if backend changes
      healthCards = healthCardsData
          .map((c) => _parseHealthCard(c as Map<String, dynamic>))
          .toList();
    }

    // Parse chart data from glucose.trend
    // Backend returns: glucose.trend = [ { 'id', 'value', 'recorded_at', 'reading_type' }, ... ]
    final trendData = glucoseData?['trend'] as List? ?? [];
    
    // Separate before/after meal values and build labels
    final List<double> beforeMealValues = [];
    final List<double> afterMealValues = [];
    final List<String> labels = [];
    
    for (final reading in trendData) {
      if (reading is Map<String, dynamic>) {
        final value = _safeDouble(reading['value']);
        final readingType = reading['reading_type']?.toString() ?? '';
        final recordedAt = reading['recorded_at']?.toString() ?? '';
        
        // Parse date for label
        String label = '';
        if (recordedAt.isNotEmpty) {
          try {
            final date = DateTime.parse(recordedAt);
            label = '${date.day}/${date.month}';
          } catch (_) {
            label = recordedAt.substring(0, 10);
          }
        }
        
        if (readingType.toLowerCase().contains('before')) {
          beforeMealValues.add(value);
          if (!labels.contains(label) && label.isNotEmpty) labels.add(label);
        } else if (readingType.toLowerCase().contains('after')) {
          afterMealValues.add(value);
          if (!labels.contains(label) && label.isNotEmpty) labels.add(label);
        } else {
          // Default to before meal
          beforeMealValues.add(value);
          if (!labels.contains(label) && label.isNotEmpty) labels.add(label);
        }
      }
    }
    
    final chartData = BloodSugarChartData(
      title: 'Blood Sugar (mg/dL)',
      beforeMealValues: beforeMealValues,
      afterMealValues: afterMealValues,
      labels: labels,
    );

    // Get min/max from target_range
    final minGlucose = targetRange != null 
        ? _safeInt(targetRange['min'], 70)
        : 70;
    final maxGlucose = targetRange != null
        ? _safeInt(targetRange['max'], 180)
        : 180;

    return DashboardData(
      greeting: greeting,
      glucose: latestGlucose,
      nextReminder: nextReminder,
      lateRemindersCount: lateRemindersCount,
      healthCards: healthCards,
      chartData: chartData,
      minGlucose: minGlucose,
      maxGlucose: maxGlucose,
    );
  }
  
  /// Helper: Get time-based greeting
  String _getTimeBasedGreeting(String name) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    return '$greeting, $name';
  }
  
  /// Helper: Parse health card from dict format (keyed by card_type)
  HealthCard _parseHealthCardFromDict(String cardType, Map<String, dynamic> data) {
    return HealthCard(
      id: '${cardType}_${DateTime.now().millisecondsSinceEpoch}',
      type: _parseHealthCardType(cardType),
      value: _safeDouble(data['value']),
      unit: data['unit']?.toString() ?? _getDefaultUnit(cardType),
      updatedAt: data['recorded_date'] != null
          ? DateTime.tryParse(data['recorded_date'].toString())
          : null,
    );
  }
  
  /// Helper: Get default unit for card type
  String _getDefaultUnit(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'water':
        return 'L';
      case 'pills':
        return 'pills';
      case 'activity':
        return 'min';
      case 'weight':
        return 'kg';
      case 'carbs':
        return 'g';
      default:
        return '';
    }
  }

  GlucoseChartData _parseGlucoseChartData(Map<String, dynamic> json) {
    // Backend returns: { success: true, data: [ { date, time, value, timestamp }, ... ] }
    // Or legacy format: { before_meal: [...], after_meal: [...], labels: [...] }
    
    // Check for new format (data array)
    if (json.containsKey('data') && json['data'] is List) {
      final readings = json['data'] as List;
      final beforeMealValues = <double>[];
      final afterMealValues = <double>[];
      final labels = <String>[];
      final labelSet = <String>{}; // To avoid duplicate labels
      
      for (final reading in readings) {
        if (reading is Map<String, dynamic>) {
          final value = _safeDouble(reading['value']);
          final date = reading['date']?.toString() ?? '';
          final time = reading['time']?.toString() ?? '';
          
          // Create label from date (e.g., "01/09")
          String label = date;
          if (date.length >= 10) {
            final parts = date.split('-');
            if (parts.length == 3) {
              label = '${parts[1]}/${parts[2]}';
            }
          }
          
          if (!labelSet.contains(label)) {
            labelSet.add(label);
            labels.add(label);
          }
          
          // Determine if before or after meal based on time
          // Morning readings (6-11) tend to be fasting/before meal
          // Afternoon/evening (12+) tend to be after meal
          final hour = int.tryParse(time.split(':').first) ?? 12;
          if (hour < 12) {
            beforeMealValues.add(value);
          } else {
            afterMealValues.add(value);
          }
        }
      }
      
      return GlucoseChartData(
        beforeMealValues: beforeMealValues,
        afterMealValues: afterMealValues,
        hours: labels,
        hasData: readings.isNotEmpty,
        totalRecords: readings.length,
      );
    }
    
    // Legacy format: { before_meal: [...], after_meal: [...], labels: [...] }
    return GlucoseChartData(
      beforeMealValues: (json['before_meal'] as List?)
              ?.map((v) => _safeDouble(v))
              .toList() ??
          [],
      afterMealValues: (json['after_meal'] as List?)
              ?.map((v) => _safeDouble(v))
              .toList() ??
          [],
      hours: (json['labels'] as List?)?.map((l) => l.toString()).toList() ?? [],
      hasData: (json['before_meal'] as List?)?.isNotEmpty ?? false,
      totalRecords: ((json['before_meal'] as List?)?.length ?? 0) +
          ((json['after_meal'] as List?)?.length ?? 0),
    );
  }

  CarbsChartData _parseCarbsChartData(List<HealthCard> healthCards) {
    final carbsCards =
        healthCards.where((c) => c.type == HealthCardType.carbs).toList();

    final values = carbsCards.map((c) => c.value).toList();
    final days = carbsCards
        .map((c) => c.updatedAt != null
            ? c.updatedAt!.day.toString()
            : DateTime.now().day.toString())
        .toList();

    return CarbsChartData(
      values: values,
      days: days,
      hasData: values.isNotEmpty,
      totalRecords: values.length,
    );
  }

  ActivityChartData _parseActivityChartData(List<HealthCard> healthCards) {
    final activityCards =
        healthCards.where((c) => c.type == HealthCardType.activity).toList();

    final values = activityCards.map((c) => c.value).toList();
    final hours = activityCards
        .map((c) => c.updatedAt != null
            ? c.updatedAt!.hour.toString()
            : DateTime.now().hour.toString())
        .toList();

    return ActivityChartData(
      values: values,
      hours: hours,
      hasData: values.isNotEmpty,
      totalRecords: values.length,
    );
  }

  InsightsData _parseInsightsData(Map<String, dynamic> json) {
    return InsightsData(
      sevenDayAverage: json['seven_day_average']?.toDouble() ?? 0.0,
      sevenDayMin: json['seven_day_min']?.toDouble() ?? 0.0,
      sevenDayMax: json['seven_day_max']?.toDouble() ?? 0.0,
      sevenDayCount: json['seven_day_count'] ?? 0,
      sevenDayInRange: json['seven_day_in_range']?.toDouble() ?? 0.0,
      sevenDayBelowRange: json['seven_day_below_range']?.toDouble() ?? 0.0,
      sevenDayAboveRange: json['seven_day_above_range']?.toDouble() ?? 0.0,
      thirtyDayAverage: json['thirty_day_average']?.toDouble() ?? 0.0,
      thirtyDayMin: json['thirty_day_min']?.toDouble() ?? 0.0,
      thirtyDayMax: json['thirty_day_max']?.toDouble() ?? 0.0,
      thirtyDayCount: json['thirty_day_count'] ?? 0,
      thirtyDayInRange: json['thirty_day_in_range']?.toDouble() ?? 0.0,
      thirtyDayBelowRange: json['thirty_day_below_range']?.toDouble() ?? 0.0,
      thirtyDayAboveRange: json['thirty_day_above_range']?.toDouble() ?? 0.0,
      morningAverage: json['morning_average']?.toDouble() ?? 0.0,
      morningCount: json['morning_count'] ?? 0,
      eveningAverage: json['evening_average']?.toDouble() ?? 0.0,
      eveningCount: json['evening_count'] ?? 0,
      trend: json['trend'] ?? 'insufficient_data',
      recommendations: (json['recommendations'] as List?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
      minGlucose: json['min_glucose'] ?? 70,
      maxGlucose: json['max_glucose'] ?? 180,
    );
  }
}
