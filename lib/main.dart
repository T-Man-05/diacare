/// ============================================================================
/// MAIN ENTRY POINT - DiaCare Application
/// ============================================================================
///
/// This is the main entry point for the DiaCare diabetic monitoring app.
/// It initializes the data service layer and sets up the app-wide configuration.
///
/// Data Storage:
/// - AppDataSource abstraction: Can use Supabase, Fake data, or any backend
/// - SharedPreferences: Theme, locale, units (local cache)
///
/// State Management: Uses BLoC/Cubit pattern with flutter_bloc package
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/alarm_ringing_page.dart';
import 'data/service_locator.dart';
import 'domain/app_data_source.dart';
import 'services/alarm_notification_service.dart';
import 'l10n/app_localizations.dart';
import 'blocs/blocs.dart';
import 'utils/constants.dart';

/// Global navigator key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Main function - Entry point of the application
/// Initializes the service locator before running the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (e.g., API_BASE_URL) before initializing
  // services that depend on ApiConfig.
  await dotenv.load(fileName: '.env');

  // Initialize the service locator with AppDataSource (Supabase)
  await setupServiceLocator();

  // Initialize alarm notification service
  await AlarmNotificationService.initialize();

  // Request notification permissions
  await AlarmNotificationService.requestPermissions();

  // Set up notification tap handler to show alarm screen
  AlarmNotificationService.onNotificationTap = _handleNotificationTap;

  runApp(const MyApp());
}

/// Handle notification tap - opens the alarm ringing screen
void _handleNotificationTap(String? payload) {
  if (payload != null && navigatorKey.currentState != null) {
    // Parse payload: "id|title|time"
    final parts = payload.split('|');
    final title = parts.length > 1 ? parts[1] : 'Reminder';
    final time = parts.length > 2 ? parts[2] : '00:00';

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AlarmRingingPage(
          alarmTime: time,
          alarmLabel: title,
          repeatType: 'Reminder',
          onStop: () {
            // Cancel the notification
            if (parts.isNotEmpty) {
              final id = AlarmNotificationService.generateAlarmId(parts[0]);
              AlarmNotificationService.cancelAlarm(id);
            }
          },
          onSnooze: () {
            // Reschedule for 9 minutes later
            debugPrint('Alarm snoozed');
          },
        ),
      ),
    );
  }
}

/// Root application widget
/// Configures theme, localization, and navigation using BLoC pattern
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final dataSource = getIt<AppDataSource>();
    final isLoggedIn = dataSource.isLoggedIn;

    return MultiBlocProvider(
      providers: [
        // Settings Cubit - manages theme and units
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(dataSource),
        ),
        // Locale Cubit - manages app language
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit(dataSource),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp(
                // Navigator key for handling notification taps
                navigatorKey: navigatorKey,

                // App title shown in task manager
                title: 'DiaCare',

                // App theme configuration
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: settingsState.themeMode,

                // Localization delegates for multi-language support
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // Supported locales
                supportedLocales: const [
                  Locale('en'),
                  Locale('fr'),
                  Locale('ar'),
                ],

                // Current locale from cubit state
                locale: localeState.locale,

                // Initial route - Login or Home based on session
                home: isLoggedIn
                    ? const MainNavigationPage()
                    : const LoginScreen(),

                // Hide debug banner in top right corner
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
