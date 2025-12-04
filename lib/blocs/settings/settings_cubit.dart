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
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_state.dart';

/// Cubit for managing application settings
///
/// This Cubit handles theme and units preferences.
/// It emits new states when settings are changed.
class SettingsCubit extends Cubit<SettingsState> {
  /// Constructor initializes with default settings state
  SettingsCubit() : super(const SettingsState());

  // ============================================================================
  // THEME MANAGEMENT
  // ============================================================================

  /// Set theme from string value (light, dark, system)
  ///
  /// [theme] - String value: 'light', 'dark', or 'system'
  void setTheme(String theme) {
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
  }

  /// Set theme mode directly
  ///
  /// [mode] - ThemeMode enum value
  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  /// Toggle between light and dark themes
  void toggleTheme() {
    final newMode =
        state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(themeMode: newMode));
  }

  // ============================================================================
  // UNITS MANAGEMENT
  // ============================================================================

  /// Set units preference
  ///
  /// [units] - String value: 'mg/dL' or 'mmol/L'
  void setUnits(String units) {
    if (units == 'mg/dL' || units == 'mmol/L') {
      emit(state.copyWith(units: units));
    }
  }

  /// Toggle between mg/dL and mmol/L units
  void toggleUnits() {
    final newUnits = state.units == 'mg/dL' ? 'mmol/L' : 'mg/dL';
    emit(state.copyWith(units: newUnits));
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
