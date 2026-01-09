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
  final http.Client _client = http.Client();
  final String _baseUrl = ApiConfig.baseUrl;

  String? _accessToken;
  String? _refreshToken;
  String? _currentUserId;

  DjangoDataSource(this._prefs) {
    _loadTokens();
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
    if (_accessToken == null) {
      throw const DataSourceException(
        'Not authenticated',
        code: 'not_authenticated',
      );
    }
  }

  /// Get auth headers for authenticated requests
  Future<Map<String, String>> _getAuthHeaders() async {
    await _ensureAuthenticated();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
  }

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
    var response = await request();

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
      await _makeAuthenticatedRequest(() => http
          .delete(
            Uri.parse('$_baseUrl${ApiConfig.authProfile}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));
      await _clearTokens();
      await _prefs.clearSession();
    } catch (e) {
      throw DataSourceException('Failed to delete account: ${e.toString()}');
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

      throw const DataSourceException('Failed to load dashboard data');
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
      // Get profile
      final profileResponse = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.authProfile}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      // Get diabetic profile
      final diabeticResponse = await _makeAuthenticatedRequest(() => http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.diabeticProfile}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));

      if (profileResponse.statusCode == 200 &&
          diabeticResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        final diabeticData = jsonDecode(diabeticResponse.body);

        return SettingsData(
          profile: _parseUserProfile(profileData),
          diabeticProfile: _parseDiabeticProfile(diabeticData),
          preferences: getPreferences(),
        );
      }

      throw const DataSourceException('Failed to load settings');
    } catch (e) {
      debugPrint('Error loading settings: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSettingsData(SettingsData settings) async {
    await _ensureAuthenticated();

    try {
      // Update profile
      await updateUserProfile(UpdateProfileInput(
        fullName: settings.fullName,
        username: settings.username,
      ));

      // Update diabetic profile
      await updateDiabeticProfile(UpdateDiabeticProfileInput(
        diabeticType: settings.diabeticType,
        treatmentType: settings.treatmentType,
        minGlucose: settings.minGlucose,
        maxGlucose: settings.maxGlucose,
      ));

      // Update local preferences
      await setTheme(settings.theme);
      await setLocale(settings.locale);
      await setUnits(settings.units);
      await setNotificationsEnabled(settings.notificationsEnabled);
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
  }

  @override
  Future<void> setLocale(String locale) async {
    await _prefs.setLocale(locale);
  }

  @override
  Future<void> setUnits(String units) async {
    await _prefs.setUnits(units);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
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
        final readings = data['results'] as List;
        return readings.map((r) => _parseGlucoseReading(r)).toList();
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
        final cards = data['results'] as List;
        return cards.map((c) => _parseHealthCard(c)).toList();
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

      await _makeAuthenticatedRequest(() => http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.healthCardsIncrement}'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));
    } catch (e) {
      throw DataSourceException(
          'Failed to update health card: ${e.toString()}');
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
        final reminders = data['results'] as List;
        return reminders.map((r) => _parseReminder(r)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting reminders: $e');
      return [];
    }
  }

  @override
  Future<Reminder> addReminder(CreateReminderInput input) async {
    await _ensureAuthenticated();

    try {
      final body = {
        'title': input.title,
        'reminder_type': input.reminderType,
        'scheduled_time': input.scheduledTime,
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
        return _parseReminder(data);
      }

      throw const DataSourceException('Failed to add reminder');
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
      if (input.scheduledTime != null)
        body['scheduled_time'] = input.scheduledTime;
      if (input.description != null) body['description'] = input.description;
      if (input.isEnabled != null) body['is_enabled'] = input.isEnabled;
      if (input.status != null) body['status'] = input.status;

      await _makeAuthenticatedRequest(() => http
          .patch(
            Uri.parse('$_baseUrl${ApiConfig.reminders}$reminderId/'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout));
    } catch (e) {
      throw DataSourceException('Failed to update reminder: ${e.toString()}');
    }
  }

  @override
  Future<void> updateReminderStatus(String reminderId, String status) async {
    await _ensureAuthenticated();

    try {
      await _makeAuthenticatedRequest(() => http
          .patch(
            Uri.parse('$_baseUrl${ApiConfig.reminders}$reminderId/'),
            headers: _getHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(ApiConfig.timeout));
    } catch (e) {
      throw DataSourceException(
          'Failed to update reminder status: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    await _ensureAuthenticated();

    try {
      await _makeAuthenticatedRequest(() => http
          .delete(
            Uri.parse('$_baseUrl${ApiConfig.reminders}$reminderId/'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout));
    } catch (e) {
      throw DataSourceException('Failed to delete reminder: ${e.toString()}');
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

      throw const DataSourceException('Failed to load insights');
    } catch (e) {
      debugPrint('Error loading insights: $e');
      rethrow;
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
      value: json['value']?.toDouble() ?? 0.0,
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
      value: json['value']?.toDouble() ?? 0.0,
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
      default:
        return HealthCardType.carbs;
    }
  }

  Reminder _parseReminder(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      reminderType: json['reminder_type'] ?? '',
      scheduledTime: json['scheduled_time'] ?? '',
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
    // Parse latest glucose
    final latestGlucose = json['latest_glucose'] != null
        ? LatestGlucose(
            value: json['latest_glucose']['value']?.toDouble() ?? 0.0,
            unit: json['latest_glucose']['unit'] ?? 'mg/dL',
            status: json['latest_glucose']['status'] ?? 'No data',
            readingType: json['latest_glucose']['reading_type'] != null
                ? _parseGlucoseReadingType(
                    json['latest_glucose']['reading_type'])
                : null,
          )
        : const LatestGlucose(
            value: 0.0,
            unit: 'mg/dL',
            status: 'No data',
          );

    // Parse next reminder
    final nextReminder = json['next_reminder'] != null
        ? _parseReminder(json['next_reminder'])
        : null;

    // Parse health cards
    final healthCards = json['health_cards'] != null
        ? (json['health_cards'] as List)
            .map((c) => _parseHealthCard(c))
            .toList()
        : <HealthCard>[];

    // Parse chart data
    final chartData = json['chart_data'] != null
        ? BloodSugarChartData(
            title: 'Blood Sugar (mg/dL)',
            beforeMealValues: (json['chart_data']['before_meal'] as List?)
                    ?.map((v) => (v as num).toDouble())
                    .toList() ??
                [],
            afterMealValues: (json['chart_data']['after_meal'] as List?)
                    ?.map((v) => (v as num).toDouble())
                    .toList() ??
                [],
            labels: (json['chart_data']['labels'] as List?)
                    ?.map((l) => l.toString())
                    .toList() ??
                [],
          )
        : const BloodSugarChartData(
            title: 'Blood Sugar (mg/dL)',
            beforeMealValues: [],
            afterMealValues: [],
            labels: [],
          );

    return DashboardData(
      greeting: json['greeting'] ?? 'Hello',
      glucose: latestGlucose,
      nextReminder: nextReminder,
      lateRemindersCount: json['late_reminders_count'] ?? 0,
      healthCards: healthCards,
      chartData: chartData,
      minGlucose: json['min_glucose'] ?? 70,
      maxGlucose: json['max_glucose'] ?? 180,
    );
  }

  GlucoseChartData _parseGlucoseChartData(Map<String, dynamic> json) {
    return GlucoseChartData(
      beforeMealValues: (json['before_meal'] as List?)
              ?.map((v) => (v as num).toDouble())
              .toList() ??
          [],
      afterMealValues: (json['after_meal'] as List?)
              ?.map((v) => (v as num).toDouble())
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
