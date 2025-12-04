/// ============================================================================
/// MAIN ENTRY POINT - DiaCare Application
/// ============================================================================
///
/// This is the main entry point for the DiaCare diabetic monitoring app.
/// It initializes the data service layer and sets up the app-wide configuration.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/login.dart';
import 'services/data_service.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'providers/locale_provider.dart';
import 'utils/constants.dart';

/// Main function - Entry point of the application
/// Initializes the data service before running the app
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the data service with JSON file data source
  // This can be easily swapped for API, database, or other data sources
  DataService(
    dataSource: JsonFileDataSource('assets/data/app_data.json'),
  );

  runApp(const MyApp());
}

/// Root application widget
/// Configures theme, localization, and navigation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<SettingsProvider, LocaleProvider>(
        builder: (context, settingsProvider, localeProvider, child) {
          return MaterialApp(
            // App title shown in task manager
            title: 'DiaCare',

            // App theme configuration
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: settingsProvider.themeMode,

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

            // Current locale from provider
            locale: localeProvider.locale,

            // Initial route - Login screen
            home: const LoginScreen(),

            // Hide debug banner in top right corner
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
