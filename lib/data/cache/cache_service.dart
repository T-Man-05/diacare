/// ============================================================================
/// CACHE SERVICE - Local Data Caching with TTL
/// ============================================================================
///
/// Provides offline-first caching for API responses.
/// Uses SharedPreferences for simple JSON caching with TTL.
/// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache entry with timestamp for TTL
class CacheEntry {
  final String data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

/// Cache service for offline data access
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _cachePrefix = 'cache_';

  // Default TTL values
  static const Duration defaultTTL = Duration(minutes: 5);
  static const Duration dashboardTTL = Duration(minutes: 2);
  static const Duration settingsTTL = Duration(minutes: 10);
  static const Duration profileTTL = Duration(minutes: 15);

  // Cache keys
  static const String dashboardKey = 'dashboard';
  static const String settingsKey = 'settings';
  static const String profileKey = 'profile';
  static const String diabeticProfileKey = 'diabetic_profile';
  static const String remindersKey = 'reminders';
  static const String healthCardsKey = 'health_cards';
  static const String glucoseReadingsKey = 'glucose_readings';
  static const String insightsKey = 'insights';

  SharedPreferences? _prefs;

  /// Initialize the cache service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('CacheService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Store data in cache with timestamp
  Future<bool> put(String key, dynamic data, {Duration? ttl}) async {
    try {
      await init();
      final jsonData = jsonEncode(data);
      final entry = CacheEntry(data: jsonData, timestamp: DateTime.now());
      return await prefs.setString(
        '$_cachePrefix$key',
        jsonEncode(entry.toJson()),
      );
    } catch (e) {
      debugPrint('Cache put error: $e');
      return false;
    }
  }

  /// Retrieve data from cache if not expired
  Future<T?> get<T>(String key, {Duration ttl = defaultTTL}) async {
    try {
      await init();
      final entryJson = prefs.getString('$_cachePrefix$key');
      if (entryJson == null) return null;

      final entry = CacheEntry.fromJson(jsonDecode(entryJson));
      if (entry.isExpired(ttl)) {
        await remove(key);
        return null;
      }

      return jsonDecode(entry.data) as T;
    } catch (e) {
      debugPrint('Cache get error: $e');
      return null;
    }
  }

  /// Get raw cached data without type casting
  Future<dynamic> getRaw(String key, {Duration ttl = defaultTTL}) async {
    try {
      await init();
      final entryJson = prefs.getString('$_cachePrefix$key');
      if (entryJson == null) return null;

      final entry = CacheEntry.fromJson(jsonDecode(entryJson));
      if (entry.isExpired(ttl)) {
        await remove(key);
        return null;
      }

      return jsonDecode(entry.data);
    } catch (e) {
      debugPrint('Cache getRaw error: $e');
      return null;
    }
  }

  /// Remove a specific cache entry
  Future<bool> remove(String key) async {
    await init();
    return await prefs.remove('$_cachePrefix$key');
  }

  /// Clear all cache entries
  Future<void> clearAll() async {
    await init();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isValid(String key, {Duration ttl = defaultTTL}) async {
    try {
      await init();
      final entryJson = prefs.getString('$_cachePrefix$key');
      if (entryJson == null) return false;

      final entry = CacheEntry.fromJson(jsonDecode(entryJson));
      return !entry.isExpired(ttl);
    } catch (e) {
      return false;
    }
  }

  /// Get cache timestamp
  Future<DateTime?> getTimestamp(String key) async {
    try {
      await init();
      final entryJson = prefs.getString('$_cachePrefix$key');
      if (entryJson == null) return null;

      final entry = CacheEntry.fromJson(jsonDecode(entryJson));
      return entry.timestamp;
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // CONVENIENCE METHODS FOR COMMON OPERATIONS
  // ============================================================================

  /// Cache dashboard data
  Future<bool> cacheDashboard(Map<String, dynamic> data) {
    return put(dashboardKey, data);
  }

  /// Get cached dashboard data
  Future<Map<String, dynamic>?> getCachedDashboard() async {
    final data = await getRaw(dashboardKey, ttl: dashboardTTL);
    return data as Map<String, dynamic>?;
  }

  /// Cache settings data
  Future<bool> cacheSettings(Map<String, dynamic> data) {
    return put(settingsKey, data);
  }

  /// Get cached settings data
  Future<Map<String, dynamic>?> getCachedSettings() async {
    final data = await getRaw(settingsKey, ttl: settingsTTL);
    return data as Map<String, dynamic>?;
  }

  /// Cache user profile
  Future<bool> cacheProfile(Map<String, dynamic> data) {
    return put(profileKey, data);
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> getCachedProfile() async {
    final data = await getRaw(profileKey, ttl: profileTTL);
    return data as Map<String, dynamic>?;
  }

  /// Cache reminders
  Future<bool> cacheReminders(List<dynamic> data) {
    return put(remindersKey, data);
  }

  /// Get cached reminders
  Future<List<dynamic>?> getCachedReminders() async {
    final data = await getRaw(remindersKey, ttl: defaultTTL);
    return data as List<dynamic>?;
  }

  /// Clear user-specific cache on logout
  Future<void> clearUserCache() async {
    await remove(dashboardKey);
    await remove(settingsKey);
    await remove(profileKey);
    await remove(diabeticProfileKey);
    await remove(remindersKey);
    await remove(healthCardsKey);
    await remove(glucoseReadingsKey);
    await remove(insightsKey);
  }
}
