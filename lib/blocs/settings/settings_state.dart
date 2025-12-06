/// ============================================================================
/// SETTINGS STATE - BLoC State for App Settings
/// ============================================================================
///
/// This file defines the state class for settings management using BLoC pattern.
/// It handles theme mode and glucose units preferences.
/// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// State class for Settings Cubit
/// Uses Equatable for value comparison
class SettingsState extends Equatable {
  /// Current theme mode (light, dark, system)
  final ThemeMode themeMode;

  /// Current glucose units preference (mg/dL or mmol/L)
  final String units;

  /// Constructor with default values
  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.units = 'mg/dL',
  });

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Get theme as string for storage/display
  String get themeString {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Check if current theme is light
  bool get isLightTheme => themeMode == ThemeMode.light;

  /// Check if current theme is dark
  bool get isDarkTheme => themeMode == ThemeMode.dark;

  /// Check if current theme is system
  bool get isSystemTheme => themeMode == ThemeMode.system;

  /// Check if units are mg/dL
  bool get isMgDl => units == 'mg/dL';

  /// Check if units are mmol/L
  bool get isMmolL => units == 'mmol/L';

  /// Get the current unit label
  String get unitLabel => units;

  // ============================================================================
  // GLUCOSE CONVERSION METHODS
  // ============================================================================

  /// Convert glucose value from mg/dL to the current unit
  double convertGlucose(double mgDlValue) {
    if (units == 'mmol/L') {
      return mgDlValue / 18.0;
    }
    return mgDlValue;
  }

  /// Format glucose value with unit
  String formatGlucose(double mgDlValue, {int decimals = 1}) {
    if (units == 'mmol/L') {
      return '${(mgDlValue / 18.0).toStringAsFixed(decimals)} mmol/L';
    }
    return '${mgDlValue.toStringAsFixed(0)} mg/dL';
  }

  /// Get just the converted value as string
  String formatGlucoseValue(double mgDlValue, {int decimals = 1}) {
    if (units == 'mmol/L') {
      return (mgDlValue / 18.0).toStringAsFixed(decimals);
    }
    return mgDlValue.toStringAsFixed(0);
  }

  // ============================================================================
  // COPY WITH METHOD
  // ============================================================================

  /// Create a copy of the state with optional new values
  SettingsState copyWith({
    ThemeMode? themeMode,
    String? units,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      units: units ?? this.units,
    );
  }

  // ============================================================================
  // EQUATABLE PROPS
  // ============================================================================

  @override
  List<Object?> get props => [themeMode, units];
}
