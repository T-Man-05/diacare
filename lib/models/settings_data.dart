import 'diabetic_profile.dart';
import 'preferences.dart';

/// Main model for Settings screen data
///
/// This model represents all user settings including:
/// - Account information (email, password, profile details)
/// - Diabetic profile configuration
/// - App preferences (theme, notifications, units)
class SettingsData {
  String email;
  String password;
  String fullName;
  String username;
  String? profileImageUrl;
  DiabeticProfile diabeticProfile;
  Preferences preferences;

  SettingsData({
    required this.email,
    required this.password,
    this.fullName = 'Charlotte King',
    this.username = '@johnkinggraphics',
    this.profileImageUrl,
    required this.diabeticProfile,
    required this.preferences,
  });

  // ============================================================================
  // GETTERS - Provide convenient access to nested properties
  // ============================================================================

  /// Returns the current theme setting (light, dark, or system)
  String get theme => preferences.theme;

  /// Returns whether notifications are enabled
  bool get notificationsEnabled => preferences.notificationsEnabled;

  /// Returns the selected units for glucose measurements (g/dL or mmol/dL)
  String get units => preferences.units;

  /// Returns the diabetic type (Type 1, Type 2, or Gestational)
  String get diabeticType => diabeticProfile.diabeticType;

  /// Returns the treatment type (Diet, Pills, or Insulin)
  String get treatmentType => diabeticProfile.treatmentType;

  /// Returns the minimum glucose target value
  int get minGlucose => diabeticProfile.minGlucose;

  /// Returns the maximum glucose target value
  int get maxGlucose => diabeticProfile.maxGlucose;

  /// Returns the glucose target range as a formatted string
  /// Example: "70 - 180 g/dL"
  String get glucoseRangeFormatted => '$minGlucose - $maxGlucose $units';

  /// Returns true if a profile image URL is set
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Returns a display name, using full name if available or username as fallback
  String get displayName => fullName.isNotEmpty ? fullName : username;

  /// Returns the username without @ symbol if present
  String get usernameWithoutAt =>
      username.startsWith('@') ? username.substring(1) : username;

  // ============================================================================
  // SETTERS - Provide convenient ways to update nested properties
  // ============================================================================

  /// Updates the theme preference
  set theme(String value) {
    preferences.theme = value;
  }

  /// Updates the notifications enabled state
  set notificationsEnabled(bool value) {
    preferences.notificationsEnabled = value;
  }

  /// Updates the units preference
  set units(String value) {
    preferences.units = value;
  }

  /// Updates the diabetic type
  set diabeticType(String value) {
    diabeticProfile.diabeticType = value;
  }

  /// Updates the treatment type
  set treatmentType(String value) {
    diabeticProfile.treatmentType = value;
  }

  /// Updates the minimum glucose target value
  set minGlucose(int value) {
    diabeticProfile.minGlucose = value;
  }

  /// Updates the maximum glucose target value
  set maxGlucose(int value) {
    diabeticProfile.maxGlucose = value;
  }

  // ============================================================================
  // VALIDATION METHODS
  // ============================================================================

  /// Validates that the email format is correct
  bool get isEmailValid => email.contains('@') && email.contains('.');

  /// Validates that the password meets minimum requirements
  bool get isPasswordValid => password.length >= 6;

  /// Validates that glucose range is valid (min < max)
  bool get isGlucoseRangeValid => minGlucose < maxGlucose;

  /// Validates that all required fields are filled
  bool get isComplete =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      fullName.isNotEmpty &&
      username.isNotEmpty;

  // ============================================================================
  // JSON SERIALIZATION
  // ============================================================================

  /// Creates a SettingsData instance from JSON data
  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      fullName: json['full_name'] ?? 'Charlotte King',
      username: json['username'] ?? '@johnkinggraphics',
      profileImageUrl: json['profile_image_url'],
      diabeticProfile: DiabeticProfile.fromJson(json['diabetic_profile'] ?? {}),
      preferences: Preferences.fromJson(json['preferences'] ?? {}),
    );
  }

  /// Converts the SettingsData instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'username': username,
      'profile_image_url': profileImageUrl,
      'diabetic_profile': diabeticProfile.toJson(),
      'preferences': preferences.toJson(),
    };
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Creates a copy of the current settings with optional field updates
  SettingsData copyWith({
    String? email,
    String? password,
    String? fullName,
    String? username,
    String? profileImageUrl,
    DiabeticProfile? diabeticProfile,
    Preferences? preferences,
  }) {
    return SettingsData(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      diabeticProfile: diabeticProfile ?? this.diabeticProfile,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Returns a string representation of the settings data
  @override
  String toString() {
    return 'SettingsData(email: $email, fullName: $fullName, username: $username)';
  }
}
