/// Model for user preferences
class Preferences {
  String theme;
  bool notificationsEnabled;

  Preferences({
    required this.theme,
    required this.notificationsEnabled,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      theme: json['theme'] ?? 'light',
      notificationsEnabled: json['notifications_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
    };
  }
}
