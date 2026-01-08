/// ============================================================================
/// SERVICE LOCATOR - Dependency Injection Setup
/// ============================================================================
///
/// This file sets up the GetIt service locator with proper abstractions.
/// UI code accesses ONLY AppDataSource interface, never implementations.
///
/// To switch backends:
/// 1. Change the implementation registered for AppDataSource
/// 2. No UI code changes required
/// ============================================================================

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide HealthCard;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../domain/app_data_source.dart';
import '../services/preferences_service.dart';
import 'sources/supabase_data_source.dart';

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

  // Setup Supabase data source
  await _setupSupabaseDataSource(prefs);
}

/// Setup Supabase-based data source
Future<void> _setupSupabaseDataSource(PreferencesService prefs) async {
  // Load environment variables
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw const DataSourceException(
      'Missing Supabase credentials. Please check your .env file.',
      code: 'missing_credentials',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Register the interface with Supabase implementation
  getIt.registerLazySingleton<AppDataSource>(
    () => SupabaseDataSource(
      Supabase.instance.client,
      prefs,
    ),
  );
}

/// Reset all services (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}

/// Check if services are registered
bool get isServiceLocatorReady => getIt.isRegistered<AppDataSource>();
