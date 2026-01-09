/// ============================================================================
/// API CLIENT - HTTP Client Wrapper
/// ============================================================================
///
/// Centralized HTTP client with automatic token management.
/// Features:
/// - Automatic token refresh on 401
/// - Consistent headers
/// - Timeout handling
/// - Error handling
/// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

/// HTTP method enum
enum HttpMethod { get, post, put, patch, delete }

/// API response wrapper
class ApiResponse {
  final int statusCode;
  final Map<String, dynamic>? data;
  final List<dynamic>? listData;
  final String? error;
  final bool success;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.listData,
    this.error,
    required this.success,
  });

  factory ApiResponse.fromResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return ApiResponse(
          statusCode: response.statusCode,
          listData: decoded,
          success: isSuccess,
        );
      } else if (decoded is Map<String, dynamic>) {
        return ApiResponse(
          statusCode: response.statusCode,
          data: decoded,
          success: isSuccess,
          error: isSuccess ? null : decoded['error']?.toString(),
        );
      }
    } catch (e) {
      // Response is not JSON
    }
    
    return ApiResponse(
      statusCode: response.statusCode,
      success: isSuccess,
      error: isSuccess ? null : response.body,
    );
  }

  factory ApiResponse.error(String message, {int statusCode = 500}) {
    return ApiResponse(
      statusCode: statusCode,
      success: false,
      error: message,
    );
  }
}

/// Centralized API client with token management
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  final String _baseUrl = ApiConfig.baseUrl;

  String? _accessToken;
  String? _refreshToken;

  /// Initialize tokens from SharedPreferences
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  /// Save tokens to SharedPreferences
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_id', userId);
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clear tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    _accessToken = null;
    _refreshToken = null;
  }

  /// Check if authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Get current user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Get headers with optional auth
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _client
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
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  /// Make an API request with automatic token refresh
  Future<ApiResponse> request(
    HttpMethod method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    await loadTokens();

    if (requiresAuth && !isAuthenticated) {
      return ApiResponse.error('Not authenticated', statusCode: 401);
    }

    var url = '$_baseUrl$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$queryString';
    }

    final uri = Uri.parse(url);
    final headers = _getHeaders(includeAuth: requiresAuth);

    http.Response response;

    try {
      response = await _executeRequest(method, uri, headers, body);

      // If token expired, try to refresh and retry
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          final newHeaders = _getHeaders(includeAuth: true);
          response = await _executeRequest(method, uri, newHeaders, body);
        } else {
          await clearTokens();
          return ApiResponse.error('Session expired', statusCode: 401);
        }
      }

      return ApiResponse.fromResponse(response);
    } catch (e) {
      debugPrint('API request failed: $e');
      return ApiResponse.error('Network error: ${e.toString()}', statusCode: 0);
    }
  }

  /// Execute the actual HTTP request
  Future<http.Response> _executeRequest(
    HttpMethod method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method) {
      case HttpMethod.get:
        return await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
      case HttpMethod.post:
        return await _client
            .post(uri, headers: headers, body: encodedBody)
            .timeout(ApiConfig.timeout);
      case HttpMethod.put:
        return await _client
            .put(uri, headers: headers, body: encodedBody)
            .timeout(ApiConfig.timeout);
      case HttpMethod.patch:
        return await _client
            .patch(uri, headers: headers, body: encodedBody)
            .timeout(ApiConfig.timeout);
      case HttpMethod.delete:
        return await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }
  }

  /// Convenience methods
  Future<ApiResponse> get(String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) => request(HttpMethod.get, endpoint, queryParams: queryParams, requiresAuth: requiresAuth);

  Future<ApiResponse> post(String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) => request(HttpMethod.post, endpoint, body: body, requiresAuth: requiresAuth);

  Future<ApiResponse> patch(String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) => request(HttpMethod.patch, endpoint, body: body, requiresAuth: requiresAuth);

  Future<ApiResponse> delete(String endpoint, {
    bool requiresAuth = true,
  }) => request(HttpMethod.delete, endpoint, requiresAuth: requiresAuth);

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}
