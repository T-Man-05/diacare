/// ============================================================================
/// MAIN ENTRY POINT - DiaCare Application
/// ============================================================================
///
/// This is the main entry point for the DiaCare diabetic monitoring app.
/// It initializes the data service layer and sets up the app-wide configuration.
/// ============================================================================

import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'services/data_service.dart';
import 'services/app_localizations.dart';

/// Main function - Entry point of the application
/// Initializes the data service before running the app
void main() {
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
    return MaterialApp(
      // App title shown in task manager
      title: 'DiaCare',

      // App theme configuration
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Use Material 3 design
        useMaterial3: true,
        // Font family from assets
        fontFamily: 'Inter',
      ),

      // Localization delegates for multi-language support
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
      ],

      // Supported locales (currently English only)
      supportedLocales: const [
        Locale('en', ''),
      ],

      // Initial route - Login screen
      home: const LoginScreen(),

      // Hide debug banner in top right corner
      debugShowCheckedModeBanner: false,
    );
  }
}
