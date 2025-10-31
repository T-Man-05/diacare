import 'diabetic_profile.dart';
import 'preferences.dart';

/// Main model for Settings screen data
class SettingsData {
  String email;
  String password;
  DiabeticProfile diabeticProfile;
  Preferences preferences;

  SettingsData({
    required this.email,
    required this.password,
    required this.diabeticProfile,
    required this.preferences,
  });

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      diabeticProfile: DiabeticProfile.fromJson(json['diabetic_profile'] ?? {}),
      preferences: Preferences.fromJson(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'diabetic_profile': diabeticProfile.toJson(),
      'preferences': preferences.toJson(),
    };
  }
}
