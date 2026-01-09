/// ============================================================================
/// SERVICE LOCATOR - Dependency Injection Setup
/// ============================================================================
///
/// This file sets up the GetIt service locator for Django backend.
/// UI code accesses ONLY AppDataSource interface, never implementations.
/// ============================================================================

import 'package:get_it/get_it.dart';
import '../domain/app_data_source.dart';
import '../services/preferences_service.dart';
import '../services/django_chat_service.dart';
import '../blocs/dashboard/dashboard_cubit.dart';
import 'sources/django_data_source.dart';
import 'cache/cache_service.dart';
import 'api/api_client.dart';

/// Global GetIt instance
final GetIt getIt = GetIt.instance;

/// Alias for more readable service access
T locator<T extends Object>() => getIt<T>();

/// Setup all services in the Service Locator
/// Call this in main.dart before runApp()
Future<void> setupServiceLocator() async {
  // Initialize SharedPreferences
  final prefs = PreferencesService();
  await prefs.init();
  getIt.registerSingleton<PreferencesService>(prefs);

  // Initialize Cache Service
  final cacheService = CacheService();
  await cacheService.init();
  getIt.registerSingleton<CacheService>(cacheService);

  // Initialize API Client
  final apiClient = ApiClient();
  await apiClient.loadTokens();
  getIt.registerSingleton<ApiClient>(apiClient);

  // Setup Django backend
  await _setupDjangoDataSource(prefs);
}

/// Setup Django-based data source
Future<void> _setupDjangoDataSource(PreferencesService prefs) async {
  // Register Django data source implementation
  getIt.registerLazySingleton<AppDataSource>(
    () => DjangoDataSource(prefs),
  );

  // Register Django chat service for AI conversations
  getIt.registerLazySingleton<DjangoChatService>(
    () => DjangoChatService(),
  );

  // Register Dashboard Cubit
  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(
      getIt<AppDataSource>(),
      cacheService: getIt<CacheService>(),
    ),
  );
}

/// Reset all services (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}

/// Check if services are registered
bool get isServiceLocatorReady => getIt.isRegistered<AppDataSource>();
