/// ============================================================================
/// CACHE SERVICE UNIT TESTS
/// ============================================================================
///
/// Unit tests for the CacheService functionality.
/// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diabetic_monitoring_app/data/cache/cache_service.dart';

void main() {
  late CacheService cacheService;

  setUp(() async {
    // Setup SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    cacheService = CacheService();
    await cacheService.init();
  });

  group('CacheService Basic Operations', () {
    test('should store and retrieve string value', () async {
      const key = 'test_key';
      const value = {'name': 'Test', 'value': 123};

      final stored = await cacheService.put(key, value);
      expect(stored, isTrue);

      final retrieved = await cacheService.get(key);
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], equals('Test'));
      expect(retrieved['value'], equals(123));
    });

    test('should return null for non-existent key', () async {
      final result = await cacheService.get('non_existent_key');
      expect(result, isNull);
    });

    test('should overwrite existing value', () async {
      const key = 'overwrite_key';
      
      await cacheService.put(key, {'version': 1});
      await cacheService.put(key, {'version': 2});

      final retrieved = await cacheService.get(key);
      expect(retrieved!['version'], equals(2));
    });
  });

  group('CacheService TTL (Time-To-Live)', () {
    test('should respect TTL and return null for expired cache', () async {
      const key = 'ttl_test_key';
      final value = {'data': 'test'};
      
      // Store with very short TTL
      await cacheService.put(
        key, 
        value, 
        ttl: const Duration(milliseconds: 1),
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 10));

      final retrieved = await cacheService.get(key);
      expect(retrieved, isNull);
    });

    test('should return valid cache within TTL', () async {
      const key = 'valid_ttl_key';
      final value = {'data': 'valid'};
      
      await cacheService.put(
        key, 
        value, 
        ttl: const Duration(minutes: 5),
      );

      final retrieved = await cacheService.get(key);
      expect(retrieved, isNotNull);
      expect(retrieved!['data'], equals('valid'));
    });
  });

  group('CacheService Dashboard Caching', () {
    test('should cache dashboard data', () async {
      final dashboardData = {
        'greeting': 'Hello, User',
        'glucose': {'value': 120, 'unit': 'mg/dL'},
        'health_cards': [],
      };

      final stored = await cacheService.cacheDashboard(dashboardData);
      expect(stored, isTrue);

      final retrieved = await cacheService.getCachedDashboard();
      expect(retrieved, isNotNull);
      expect(retrieved!['greeting'], equals('Hello, User'));
    });

    test('should return null for uncached dashboard', () async {
      final retrieved = await cacheService.getCachedDashboard();
      expect(retrieved, isNull);
    });
  });

  group('CacheService Clear Operations', () {
    test('should clear all user cache', () async {
      // Store some values
      await cacheService.put('key1', {'value': 1});
      await cacheService.put('key2', {'value': 2});
      await cacheService.cacheDashboard({'greeting': 'test'});

      // Clear all
      await cacheService.clearUserCache();

      // Verify cleared
      expect(await cacheService.get('key1'), isNull);
      expect(await cacheService.get('key2'), isNull);
      expect(await cacheService.getCachedDashboard(), isNull);
    });
  });

  group('CacheService Edge Cases', () {
    test('should handle empty map', () async {
      const key = 'empty_map';
      
      await cacheService.put(key, {});
      final retrieved = await cacheService.get(key);
      
      expect(retrieved, isNotNull);
      expect(retrieved, isEmpty);
    });

    test('should handle nested objects', () async {
      const key = 'nested';
      final value = {
        'level1': {
          'level2': {
            'level3': {'value': 'deep'},
          },
        },
      };

      await cacheService.put(key, value);
      final retrieved = await cacheService.get(key);

      expect(retrieved!['level1']['level2']['level3']['value'], equals('deep'));
    });

    test('should handle list values', () async {
      const key = 'list_key';
      final value = {
        'items': [1, 2, 3, 'four', {'five': 5}],
      };

      await cacheService.put(key, value);
      final retrieved = await cacheService.get(key);

      expect(retrieved!['items'], hasLength(5));
      expect(retrieved['items'][3], equals('four'));
    });
  });
}
