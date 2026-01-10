/// ============================================================================
/// SETTINGS CUBIT - State Management for App Settings
/// ============================================================================
///
/// This Cubit manages app-wide settings including:
/// - Theme mode (light, dark, system)
/// - Glucose units preference (mg/dL, mmol/L)
///
/// Uses the Cubit pattern from flutter_bloc for simpler state management
/// when complex events are not needed.
///
/// Settings are persisted to backend via AppDataSource and cached locally.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_state.dart';
import '../../services/preferences_service.dart';
import '../../domain/app_data_source.dart';

/// Cubit for managing application settings
///
/// This Cubit handles theme and units preferences.
/// It emits new states when settings are changed and persists to backend.
class SettingsCubit extends Cubit<SettingsState> {
  final PreferencesService _prefs = PreferencesService();
  final AppDataSource _dataSource;

  /// Constructor initializes with default settings state, then loads saved settings
  SettingsCubit(this._dataSource) : super(const SettingsState()) {
    _loadSavedSettings();
  }

  /// Load saved settings from backend via AppDataSource
  Future<void> _loadSavedSettings() async {
    try {
      // Try to load from backend first
      try {
        final settingsData = await _dataSource.getSettingsData();

        ThemeMode themeMode;
        switch (settingsData.theme) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          case 'system':
            themeMode = ThemeMode.system;
            break;
          default:
            themeMode = ThemeMode.light;
        }

        emit(state.copyWith(
          themeMode: themeMode,
          units: settingsData.units,
        ));

        return;
      } catch (e) {
        // Not being logged in is a normal startup state; don't treat it as an error.
        if (e is DataSourceException && e.code == 'not_authenticated') {
          // silent
        } else {
          debugPrint('Failed to load settings from backend, using local: $e');
        }
      }

      // Fallback to local storage if backend fails
      final savedTheme = _prefs.getTheme();
      final savedUnits = _prefs.getUnits();

      ThemeMode themeMode;
      switch (savedTheme) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'system':
          themeMode = ThemeMode.system;
          break;
        default:
          themeMode = ThemeMode.light;
      }

      emit(state.copyWith(themeMode: themeMode, units: savedUnits));
    } catch (e) {
      debugPrint('Error loading saved settings: $e');
    }
  }

  /// Public method to reload settings from SharedPreferences
  Future<void> loadSettings() => _loadSavedSettings();

  // ============================================================================
  // THEME MANAGEMENT
  // ============================================================================

  /// Set theme from string value (light, dark, system)
  ///
  /// [theme] - String value: 'light', 'dark', or 'system'
  Future<void> setTheme(String theme) async {
    ThemeMode newMode;
    switch (theme) {
      case 'light':
        newMode = ThemeMode.light;
        break;
      case 'dark':
        newMode = ThemeMode.dark;
        break;
      case 'system':
        newMode = ThemeMode.system;
        break;
      default:
        newMode = ThemeMode.light;
    }
    emit(state.copyWith(themeMode: newMode));

    try {
      await _dataSource.setTheme(theme);
    } catch (e) {
      debugPrint('Error persisting theme to backend: $e');
    }
  }

  /// Set theme mode directly
  ///
  /// [mode] - ThemeMode enum value
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    // Save to backend
    String themeStr;
    switch (mode) {
      case ThemeMode.light:
        themeStr = 'light';
        break;
      case ThemeMode.dark:
        themeStr = 'dark';
        break;
      case ThemeMode.system:
        themeStr = 'system';
        break;
    }

    try {
      await _dataSource.setTheme(themeStr);
    } catch (e) {
      debugPrint('Error persisting theme to backend: $e');
    }
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    final newMode =
        state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  // ============================================================================
  // UNITS MANAGEMENT
  // ============================================================================

  /// Set units preference
  ///
  /// [units] - String value: 'mg/dL' or 'mmol/L'
  Future<void> setUnits(String units) async {
    if (units == 'mg/dL' || units == 'mmol/L') {
      emit(state.copyWith(units: units));

      try {
        await _dataSource.setUnits(units);
      } catch (e) {
        debugPrint('Error persisting units to backend: $e');
      }
    }
  }

  /// Toggle between mg/dL and mmol/L units
  Future<void> toggleUnits() async {
    final newUnits = state.units == 'mg/dL' ? 'mmol/L' : 'mg/dL';
    await setUnits(newUnits);
  }

  // ============================================================================
  // CONVENIENCE GETTERS (delegating to state)
  // ============================================================================

  /// Get the current theme mode
  ThemeMode get themeMode => state.themeMode;

  /// Get the current units
  String get units => state.units;

  /// Format glucose value using current units
  String formatGlucoseValue(double mgDlValue, {int decimals = 1}) {
    return state.formatGlucoseValue(mgDlValue, decimals: decimals);
  }

  /// Format glucose with unit label
  String formatGlucose(double mgDlValue, {int decimals = 1}) {
    return state.formatGlucose(mgDlValue, decimals: decimals);
  }

  /// Convert glucose value
  double convertGlucose(double mgDlValue) {
    return state.convertGlucose(mgDlValue);
  }
}
