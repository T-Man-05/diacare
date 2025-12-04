/// ============================================================================
/// MAIN ENTRY POINT - DiaCare Application
/// ============================================================================
///
/// This is the main entry point for the DiaCare diabetic monitoring app.
/// It initializes the data service layer and sets up the app-wide configuration.
///
/// State Management: Uses BLoC/Cubit pattern with flutter_bloc package
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/login.dart';
import 'services/data_service.dart';
import 'l10n/app_localizations.dart';
import 'blocs/blocs.dart';
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
/// Configures theme, localization, and navigation using BLoC pattern
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Settings Cubit - manages theme and units
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(),
        ),
        // Locale Cubit - manages app language
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp(
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

                // Initial route - Login screen
                home: const LoginScreen(),

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
