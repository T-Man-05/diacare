/// ============================================================================
/// DASHBOARD CUBIT TESTS
/// ============================================================================
///
/// Unit tests for the Dashboard Cubit state management.
/// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:diabetic_monitoring_app/blocs/dashboard/dashboard_cubit.dart';
import 'package:diabetic_monitoring_app/domain/app_data_source.dart';
import 'package:diabetic_monitoring_app/domain/models/models.dart';
import 'package:diabetic_monitoring_app/data/cache/cache_service.dart';

// Mock classes
class MockAppDataSource extends Mock implements AppDataSource {}
class MockCacheService extends Mock implements CacheService {}

void main() {
  late MockAppDataSource mockDataSource;
  late MockCacheService mockCacheService;

  final testDashboardData = DashboardData(
    greeting: 'Hello, Test User',
    glucose: const LatestGlucose(
      value: 120.0,
      unit: 'mg/dL',
      status: 'Normal',
    ),
    healthCards: const [],
    chartData: const BloodSugarChartData(
      title: 'Blood Sugar',
      beforeMealValues: [],
      afterMealValues: [],
      labels: [],
    ),
    minGlucose: 70,
    maxGlucose: 180,
  );

  setUp(() {
    mockDataSource = MockAppDataSource();
    mockCacheService = MockCacheService();
    
    // Setup default mock behaviors
    when(() => mockCacheService.getCachedDashboard())
        .thenAnswer((_) async => null);
    when(() => mockCacheService.cacheDashboard(any()))
        .thenAnswer((_) async => true);
  });

  // Note: blocTest handles its own cleanup, no tearDown needed

  group('DashboardCubit', () {
    blocTest<DashboardCubit, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when loadDashboard succeeds',
      build: () {
        when(() => mockDataSource.getDashboardData())
            .thenAnswer((_) async => testDashboardData);
        return DashboardCubit(mockDataSource, cacheService: mockCacheService);
      },
      act: (cubit) => cubit.loadDashboard(forceRefresh: true),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [DashboardLoading, DashboardError] when loadDashboard fails',
      build: () {
        when(() => mockDataSource.getDashboardData())
            .thenThrow(Exception('Network error'));
        return DashboardCubit(mockDataSource, cacheService: mockCacheService);
      },
      act: (cubit) => cubit.loadDashboard(forceRefresh: true),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>(),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'uses cached data when available and not forcing refresh',
      build: () {
        when(() => mockCacheService.getCachedDashboard())
            .thenAnswer((_) async => {
              'greeting': 'Cached Hello',
              'min_glucose': 70,
              'max_glucose': 180,
            });
        when(() => mockDataSource.getDashboardData())
            .thenAnswer((_) async => testDashboardData);
        return DashboardCubit(mockDataSource, cacheService: mockCacheService);
      },
      act: (cubit) => cubit.loadDashboard(forceRefresh: false),
      verify: (_) {
        verify(() => mockCacheService.getCachedDashboard()).called(greaterThan(0));
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'refresh forces network request',
      build: () {
        when(() => mockDataSource.getDashboardData())
            .thenAnswer((_) async => testDashboardData);
        return DashboardCubit(mockDataSource, cacheService: mockCacheService);
      },
      act: (cubit) => cubit.refresh(),
      verify: (_) {
        verify(() => mockDataSource.getDashboardData()).called(1);
      },
    );
  });

  group('DashboardState', () {
    test('DashboardInitial props are empty', () {
      expect(DashboardInitial().props, isEmpty);
    });

    test('DashboardLoading with previous data', () {
      final state = DashboardLoading(previousData: testDashboardData);
      expect(state.previousData, equals(testDashboardData));
    });

    test('DashboardLoaded contains data and timestamp', () {
      final loadedAt = DateTime.now();
      final state = DashboardLoaded(
        data: testDashboardData,
        isFromCache: false,
        loadedAt: loadedAt,
      );
      
      expect(state.data, equals(testDashboardData));
      expect(state.isFromCache, isFalse);
      expect(state.loadedAt, equals(loadedAt));
    });

    test('DashboardError contains message', () {
      const state = DashboardError(message: 'Test error');
      expect(state.message, equals('Test error'));
      expect(state.cachedData, isNull);
    });
  });
}
