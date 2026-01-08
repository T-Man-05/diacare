import 'user_profile.dart';
import 'diabetic_profile.dart';
import 'app_preferences.dart';

/// Domain model for settings screen data
/// This model is backend-agnostic - aggregates all settings info
class SettingsData {
  final UserProfile profile;
  final DiabeticProfile diabeticProfile;
  final AppPreferences preferences;

  const SettingsData({
    required this.profile,
    required this.diabeticProfile,
    required this.preferences,
  });

  // Convenience getters
  String get email => profile.email;
  String get fullName => profile.fullName;
  String get username => profile.username;
  String? get profileImageUrl => profile.profileImageUrl;
  String get displayName => profile.displayName;

  String get diabeticType => diabeticProfile.diabeticType;
  String get treatmentType => diabeticProfile.treatmentType;
  int get minGlucose => diabeticProfile.minGlucose;
  int get maxGlucose => diabeticProfile.maxGlucose;

  String get theme => preferences.theme;
  String get units => preferences.units;
  bool get notificationsEnabled => preferences.notificationsEnabled;

  /// Formatted glucose range
  String get glucoseRangeFormatted =>
      diabeticProfile.glucoseRangeFormatted(preferences.units);

  SettingsData copyWith({
    UserProfile? profile,
    DiabeticProfile? diabeticProfile,
    AppPreferences? preferences,
  }) {
    return SettingsData(
      profile: profile ?? this.profile,
      diabeticProfile: diabeticProfile ?? this.diabeticProfile,
      preferences: preferences ?? this.preferences,
    );
  }
}
