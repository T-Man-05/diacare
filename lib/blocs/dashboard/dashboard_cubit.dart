/// ============================================================================
/// DASHBOARD CUBIT - State Management for Dashboard
/// ============================================================================
///
/// Manages dashboard data loading, caching, and refresh.
/// Provides offline-first data access with background sync.
/// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/app_data_source.dart';
import '../../domain/models/models.dart';
import '../../data/cache/cache_service.dart';
import '../../data/mappers/mappers.dart';

// ============================================================================
// DASHBOARD STATE
// ============================================================================

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {
  final DashboardData? previousData;

  const DashboardLoading({this.previousData});

  @override
  List<Object?> get props => [previousData];
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final bool isFromCache;
  final DateTime loadedAt;

  DashboardLoaded({
    required this.data,
    this.isFromCache = false,
    DateTime? loadedAt,
  }) : loadedAt = loadedAt ?? DateTime.now();

  @override
  List<Object?> get props => [data, isFromCache, loadedAt];
}

class DashboardError extends DashboardState {
  final String message;
  final DashboardData? cachedData;

  const DashboardError({
    required this.message,
    this.cachedData,
  });

  @override
  List<Object?> get props => [message, cachedData];
}

// ============================================================================
// DASHBOARD CUBIT
// ============================================================================

class DashboardCubit extends Cubit<DashboardState> {
  final AppDataSource _dataSource;
  final CacheService _cacheService;

  DashboardCubit(this._dataSource, {CacheService? cacheService})
      : _cacheService = cacheService ?? CacheService(),
        super(DashboardInitial());

  /// Load dashboard data with cache-first strategy
  Future<void> loadDashboard({bool forceRefresh = false}) async {
    // If not forcing refresh, try cache first
    if (!forceRefresh) {
      final cachedData = await _tryLoadFromCache();
      if (cachedData != null) {
        emit(DashboardLoaded(data: cachedData, isFromCache: true));
        // Continue to refresh in background
        _refreshInBackground();
        return;
      }
    }

    // Show loading state
    final currentData = state is DashboardLoaded
        ? (state as DashboardLoaded).data
        : null;
    emit(DashboardLoading(previousData: currentData));

    try {
      final data = await _dataSource.getDashboardData();
      
      // Cache the response
      await _cacheResponse(data);
      
      emit(DashboardLoaded(data: data, isFromCache: false));
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      
      // Try to serve cached data on error
      final cachedData = await _tryLoadFromCache();
      if (cachedData != null) {
        emit(DashboardError(
          message: 'Using cached data: ${e.toString()}',
          cachedData: cachedData,
        ));
      } else {
        emit(DashboardError(message: e.toString()));
      }
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboard(forceRefresh: true);
  }

  /// Try to load dashboard data from cache
  Future<DashboardData?> _tryLoadFromCache() async {
    try {
      final cachedJson = await _cacheService.getCachedDashboard();
      if (cachedJson != null) {
        return DashboardMapper.parseDashboardData(cachedJson);
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  /// Cache the dashboard response
  Future<void> _cacheResponse(DashboardData data) async {
    try {
      // Convert to JSON-serializable map for caching
      await _cacheService.cacheDashboard({
        'greeting': data.greeting,
        'latest_glucose': data.glucose.value > 0
            ? {
                'value': data.glucose.value,
                'unit': data.glucose.unit,
                'status': data.glucose.status,
              }
            : null,
        'next_reminder': data.nextReminder != null
            ? {
                'id': data.nextReminder!.id,
                'title': data.nextReminder!.title,
                'scheduled_time': data.nextReminder!.scheduledTime,
                'reminder_type': data.nextReminder!.reminderType,
              }
            : null,
        'late_reminders_count': data.lateRemindersCount,
        'health_cards': data.healthCards
            .map((c) => {
                  'id': c.id,
                  'card_type': c.type.name,
                  'value': c.value,
                  'unit': c.unit,
                })
            .toList(),
        'chart_data': {
          'before_meal': data.chartData.beforeMealValues,
          'after_meal': data.chartData.afterMealValues,
          'labels': data.chartData.labels,
        },
        'min_glucose': data.minGlucose,
        'max_glucose': data.maxGlucose,
      });
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Refresh in background without showing loading state
  Future<void> _refreshInBackground() async {
    try {
      final data = await _dataSource.getDashboardData();
      await _cacheResponse(data);
      
      // Only emit if still showing cached data
      if (state is DashboardLoaded && (state as DashboardLoaded).isFromCache) {
        emit(DashboardLoaded(data: data, isFromCache: false));
      }
    } catch (e) {
      // Silently fail for background refresh
      debugPrint('Background refresh failed: $e');
    }
  }

  /// Clear cached dashboard data
  Future<void> clearCache() async {
    await _cacheService.remove(CacheService.dashboardKey);
  }
}
