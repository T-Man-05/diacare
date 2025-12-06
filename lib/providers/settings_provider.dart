import 'package:flutter/material.dart';

/// Provider to manage app settings (theme and units)
class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _units = 'mg/dL';

  // ============================================================================
  // THEME MANAGEMENT
  // ============================================================================

  ThemeMode get themeMode => _themeMode;

  String get themeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  bool get isLightTheme => _themeMode == ThemeMode.light;
  bool get isDarkTheme => _themeMode == ThemeMode.dark;
  bool get isSystemTheme => _themeMode == ThemeMode.system;

  /// Set theme from string value (light, dark, system)
  void setTheme(String theme) {
    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Set theme mode directly
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // ============================================================================
  // UNITS MANAGEMENT
  // ============================================================================

  String get units => _units;

  bool get isMgDl => _units == 'mg/dL';
  bool get isMmolL => _units == 'mmol/L';

  /// Set units preference
  void setUnits(String units) {
    if (units == 'mg/dL' || units == 'mmol/L') {
      _units = units;
      notifyListeners();
    }
  }

  /// Convert glucose value from mg/dL to the current unit
  double convertGlucose(double mgDlValue) {
    if (_units == 'mmol/L') {
      return mgDlValue / 18.0;
    }
    return mgDlValue;
  }

  /// Format glucose value with unit
  String formatGlucose(double mgDlValue, {int decimals = 1}) {
    if (_units == 'mmol/L') {
      return '${(mgDlValue / 18.0).toStringAsFixed(decimals)} mmol/L';
    }
    return '${mgDlValue.toStringAsFixed(0)} mg/dL';
  }

  /// Get just the converted value as string
  String formatGlucoseValue(double mgDlValue, {int decimals = 1}) {
    if (_units == 'mmol/L') {
      return (mgDlValue / 18.0).toStringAsFixed(decimals);
    }
    return mgDlValue.toStringAsFixed(0);
  }

  /// Get the current unit label
  String get unitLabel => _units;
}
