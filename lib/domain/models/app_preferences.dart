/// Domain model for user preferences
/// This model is backend-agnostic - no JSON keys, no infrastructure concepts
class AppPreferences {
  final String theme;
  final String locale;
  final String units;
  final bool notificationsEnabled;
  final bool onboardingComplete;

  const AppPreferences({
    required this.theme,
    required this.locale,
    required this.units,
    required this.notificationsEnabled,
    required this.onboardingComplete,
  });

  /// Default preferences for new users
  factory AppPreferences.defaultPreferences() {
    return const AppPreferences(
      theme: 'system',
      locale: 'en',
      units: 'mg/dL',
      notificationsEnabled: true,
      onboardingComplete: false,
    );
  }

  /// Check if light theme is selected
  bool get isLightTheme => theme == 'light';

  /// Check if dark theme is selected
  bool get isDarkTheme => theme == 'dark';

  /// Check if system theme is selected
  bool get isSystemTheme => theme == 'system';

  /// Check if using mg/dL units
  bool get isUsingMgDL => units == 'mg/dL';

  /// Check if using mmol/L units
  bool get isUsingMmolL => units == 'mmol/L';

  AppPreferences copyWith({
    String? theme,
    String? locale,
    String? units,
    bool? notificationsEnabled,
    bool? onboardingComplete,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
      units: units ?? this.units,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
