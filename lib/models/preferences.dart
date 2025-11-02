/// Model for user preferences
class Preferences {
  String theme;
  bool notificationsEnabled;
  String units;

  Preferences({
    this.theme = 'light',
    this.notificationsEnabled = true,
    this.units = 'g/dL',
  });

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Returns true if light theme is selected
  bool get isLightTheme => theme == 'light';

  /// Returns true if dark theme is selected
  bool get isDarkTheme => theme == 'dark';

  /// Returns true if system theme is selected
  bool get isSystemTheme => theme == 'system';

  /// Returns true if using g/dL units
  bool get isUsingGDL => units == 'g/dL';

  /// Returns true if using mmol/dL units
  bool get isUsingMmolDL => units == 'mmol/dL';

  // ============================================================================
  // JSON SERIALIZATION
  // ============================================================================

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      theme: json['theme'] ?? 'light',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      units: json['units'] ?? 'g/dL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
      'units': units,
    };
  }

  /// Creates a copy with optional field updates
  Preferences copyWith({
    String? theme,
    bool? notificationsEnabled,
    String? units,
  }) {
    return Preferences(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      units: units ?? this.units,
    );
  }
}
