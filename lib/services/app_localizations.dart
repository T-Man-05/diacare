/// ============================================================================
/// APP LOCALIZATIONS - Centralized String Management
/// ============================================================================
///
/// This class provides easy access to all app strings from the centralized
/// JSON data file. It eliminates hardcoded strings throughout the app.
///
/// Usage in widgets:
/// ```dart
/// final strings = AppLocalizations.of(context);
/// Text(strings.login.title) // Displays "Log In"
/// ```
/// ============================================================================

import 'package:flutter/material.dart';
import 'data_service.dart';

class AppLocalizations {
  final Map<String, dynamic> _strings;

  AppLocalizations._(this._strings);

  /// Factory method to create AppLocalizations from data service
  static Future<AppLocalizations> load() async {
    final dataService = DataService.instance;
    final strings = await dataService.getAppStrings();
    return AppLocalizations._(strings);
  }

  /// Get localized strings from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // ========================================================================
  // APP-WIDE STRINGS
  // ========================================================================

  String get appName => _strings['app_name'] ?? 'DiaCare';
  String get welcome => _strings['welcome'] ?? 'Welcome!';

  // ========================================================================
  // LOGIN SCREEN STRINGS
  // ========================================================================

  LoginStrings get login => LoginStrings(_strings['login'] ?? {});

  // ========================================================================
  // SIGNUP SCREEN STRINGS
  // ========================================================================

  SignupStrings get signup => SignupStrings(_strings['signup'] ?? {});

  // ========================================================================
  // ONBOARDING STRINGS
  // ========================================================================

  OnboardingStrings get onboarding =>
      OnboardingStrings(_strings['onboarding'] ?? {});

  // ========================================================================
  // DASHBOARD STRINGS
  // ========================================================================

  DashboardStrings get dashboard =>
      DashboardStrings(_strings['dashboard'] ?? {});

  // ========================================================================
  // PROFILE STRINGS
  // ========================================================================

  ProfileStrings get profile => ProfileStrings(_strings['profile'] ?? {});

  // ========================================================================
  // DIABETIC PROFILE STRINGS
  // ========================================================================

  DiabeticProfileStrings get diabeticProfile =>
      DiabeticProfileStrings(_strings['diabetic_profile'] ?? {});

  // ========================================================================
  // SETTINGS STRINGS
  // ========================================================================

  SettingsStrings get settings => SettingsStrings(_strings['settings'] ?? {});

  // ========================================================================
  // INSIGHTS STRINGS
  // ========================================================================

  InsightsStrings get insights => InsightsStrings(_strings['insights'] ?? {});

  // ========================================================================
  // REMINDERS STRINGS
  // ========================================================================

  RemindersStrings get reminders =>
      RemindersStrings(_strings['reminders'] ?? {});

  // ========================================================================
  // CHAT STRINGS
  // ========================================================================

  ChatStrings get chat => ChatStrings(_strings['chat'] ?? {});

  // ========================================================================
  // DIALOG STRINGS
  // ========================================================================

  DialogStrings get dialogs => DialogStrings(_strings['dialogs'] ?? {});

  // ========================================================================
  // MESSAGE STRINGS
  // ========================================================================

  MessageStrings get messages => MessageStrings(_strings['messages'] ?? {});

  // ========================================================================
  // VALIDATION STRINGS
  // ========================================================================

  ValidationStrings get validation =>
      ValidationStrings(_strings['validation'] ?? {});

  // ========================================================================
  // OPTIONS (DROPDOWNS, LISTS)
  // ========================================================================

  OptionsData get options => OptionsData(_strings['options'] ?? {});
}

// ============================================================================
// TYPED STRING CLASSES FOR BETTER IDE SUPPORT
// ============================================================================

class LoginStrings {
  final Map<String, dynamic> _data;
  LoginStrings(this._data);

  String get title => _data['title'] ?? 'Log In';
  String get emailLabel => _data['email_label'] ?? 'Email Address';
  String get emailHint => _data['email_hint'] ?? 'Enter your email';
  String get passwordLabel => _data['password_label'] ?? 'Password';
  String get passwordHint => _data['password_hint'] ?? 'Enter your password';
  String get loginButton => _data['login_button'] ?? 'Log In';
  String get signupButton => _data['signup_button'] ?? 'Sign Up';
  String get forgotPassword =>
      _data['forgot_password'] ?? 'Forgot your password?';
}

class SignupStrings {
  final Map<String, dynamic> _data;
  SignupStrings(this._data);

  String get title => _data['title'] ?? 'Sign Up';
  String get usernameLabel => _data['username_label'] ?? 'Username';
  String get usernameHint => _data['username_hint'] ?? 'choose an @Username';
  String get emailLabel => _data['email_label'] ?? 'Email Address';
  String get emailHint => _data['email_hint'] ?? 'Enter your email';
  String get passwordLabel => _data['password_label'] ?? 'Password';
  String get passwordHint => _data['password_hint'] ?? 'Enter your password';
  String get signupButton => _data['signup_button'] ?? 'Sign up';
}

class OnboardingStrings {
  final Map<String, dynamic> _data;
  OnboardingStrings(this._data);

  String get dateOfBirthLabel =>
      _data['date_of_birth_label'] ?? 'Date of birth';
  String get dateOfBirthHint =>
      _data['date_of_birth_hint'] ?? 'Select your date of birth';
  String get genderLabel => _data['gender_label'] ?? 'Gender';
  String get genderHint => _data['gender_hint'] ?? 'Select your gender';
  String get heightLabel => _data['height_label'] ?? 'Height';
  String get heightHint => _data['height_hint'] ?? 'Enter your height';
  String get weightLabel => _data['weight_label'] ?? 'Weight';
  String get weightHint => _data['weight_hint'] ?? 'Enter your weight';
  String get diabetesTypeLabel =>
      _data['diabetes_type_label'] ?? 'Type of diabetes';
  String get diabetesTypeHint =>
      _data['diabetes_type_hint'] ?? 'Select your type of diabetes';
  String get unitPreferencesLabel =>
      _data['unit_preferences_label'] ?? 'Unit preferences';
  String get unitPreferencesHint =>
      _data['unit_preferences_hint'] ?? 'Select your measure unit';
  String get diagnosisDurationLabel =>
      _data['diagnosis_duration_label'] ?? 'Duration of the diagnosis';
  String get treatmentTypeLabel =>
      _data['treatment_type_label'] ?? 'Usual treatment type';
  String get continueButton => _data['continue_button'] ?? 'Continue';
}

class DashboardStrings {
  final Map<String, dynamic> _data;
  DashboardStrings(this._data);

  String get glucoseLabel => _data['glucose_label'] ?? 'Glucose';
  String get nextReminder => _data['next_reminder'] ?? 'Next Reminder';
  String get seeDetails => _data['see_details'] ?? 'See Details';
}

class ProfileStrings {
  final Map<String, dynamic> _data;
  ProfileStrings(this._data);

  String get myProfile => _data['my_profile'] ?? 'My Profile';
  String get editProfile => _data['edit_profile'] ?? 'Edit Profile';
  String get diabeticsProfile =>
      _data['diabetics_profile'] ?? 'Diabetics Profile';
  String get settings => _data['settings'] ?? 'Settings';
  String get deleteAccount => _data['delete_account'] ?? 'Delete account';
  String get logOut => _data['log_out'] ?? 'Log out';
  String get fullNameLabel => _data['full_name_label'] ?? 'Full Name';
  String get usernameLabel => _data['username_label'] ?? 'Username';
  String get emailLabel => _data['email_label'] ?? 'Email';
  String get saveChanges => _data['save_changes'] ?? 'Save Changes';
}

class DiabeticProfileStrings {
  final Map<String, dynamic> _data;
  DiabeticProfileStrings(this._data);

  String get title => _data['title'] ?? 'Diabetics Profile';
  String get diabeticTypeLabel =>
      _data['diabetic_type_label'] ?? 'Diabetic Type';
  String get treatmentTypeLabel =>
      _data['treatment_type_label'] ?? 'Treatment Type';
  String get glucoseRangeLabel =>
      _data['glucose_range_label'] ?? 'Glucose Target Range (mg/dL)';
  String get minLabel => _data['min_label'] ?? 'Min';
  String get maxLabel => _data['max_label'] ?? 'Max';
  String get saveButton => _data['save_button'] ?? 'Save Changes';
}

class SettingsStrings {
  final Map<String, dynamic> _data;
  SettingsStrings(this._data);

  String get title => _data['title'] ?? 'Settings';
  String get themeSection => _data['theme_section'] ?? 'Theme';
  String get notificationsSection =>
      _data['notifications_section'] ?? 'Notifications';
  String get unitsSection => _data['units_section'] ?? 'Units Preference';
  String get themeLight => _data['theme_light'] ?? 'Light';
  String get themeDark => _data['theme_dark'] ?? 'Dark';
  String get themeSystem => _data['theme_system'] ?? 'System';
  String get notificationsEnable =>
      _data['notifications_enable'] ?? 'Enable Notifications';
}

class InsightsStrings {
  final Map<String, dynamic> _data;
  InsightsStrings(this._data);

  String get title => _data['title'] ?? 'Insights';
  String get bloodSugarChart => _data['blood_sugar_chart'] ?? 'Blood Sugar';
  String get carbsChart => _data['carbs_chart'] ?? 'Carbs';
  String get carbsUnit => _data['carbs_unit'] ?? '(calories)';
  String get activityChart => _data['activity_chart'] ?? 'Daily Activity';
  String get activityUnit => _data['activity_unit'] ?? '(km)';
  String get legendBeforeMeal => _data['legend_before_meal'] ?? 'Before Meal';
  String get legendAfterMeal => _data['legend_after_meal'] ?? 'After Meal';
  String get legendNormal => _data['legend_normal'] ?? 'Normal';
  String get legendAboveNormal =>
      _data['legend_above_normal'] ?? 'Above Normal';
  String get legendAboveUsual => _data['legend_above_usual'] ?? 'Above Usual';
}

class RemindersStrings {
  final Map<String, dynamic> _data;
  RemindersStrings(this._data);

  String get title => _data['title'] ?? 'Reminder';
  String get dateFormat => _data['date_format'] ?? 'Fri, 24 Oct  15:54';
  String get statusDone => _data['status_done'] ?? 'Done';
  String get statusNotDone => _data['status_not_done'] ?? 'Not Done';
  String get statusLater => _data['status_later'] ?? 'Later';
  String get dialogTitle => _data['dialog_title'] ?? 'Mark Reminder Status';
}

class ChatStrings {
  final Map<String, dynamic> _data;
  ChatStrings(this._data);

  String get title => _data['title'] ?? 'Chat';
  String get description =>
      _data['description'] ?? ' AI assistant support for diabetes management.';
}

class DialogStrings {
  final Map<String, dynamic> _data;
  DialogStrings(this._data);

  String get deleteAccountTitle =>
      _data['delete_account_title'] ?? 'Delete Account';
  String get deleteAccountMessage =>
      _data['delete_account_message'] ??
      'Are you sure you want to delete your account? This action cannot be undone.';
  String get logoutTitle => _data['logout_title'] ?? 'Log Out';
  String get logoutMessage =>
      _data['logout_message'] ?? 'Are you sure you want to log out?';
  String get cancel => _data['cancel'] ?? 'Cancel';
  String get confirm => _data['confirm'] ?? 'Sure';
  String get done => _data['done'] ?? 'Done';
}

class MessageStrings {
  final Map<String, dynamic> _data;
  MessageStrings(this._data);

  String get profileUpdated =>
      _data['profile_updated'] ?? 'Profile updated successfully';
  String get diabeticProfileUpdated =>
      _data['diabetic_profile_updated'] ??
      'Diabetic profile updated successfully';
  String get accountDeleted => _data['account_deleted'] ?? 'Account deleted';
  String get loggedOut => _data['logged_out'] ?? 'Logged out successfully';
  String get notificationsEnabled =>
      _data['notifications_enabled'] ?? 'Notifications enabled';
  String get notificationsDisabled =>
      _data['notifications_disabled'] ?? 'Notifications disabled';
  String get reminderDone =>
      _data['reminder_done'] ?? 'Reminder marked as done';
  String get reminderNotDone =>
      _data['reminder_not_done'] ?? 'Reminder marked as not done';
  String get reminderLater => _data['reminder_later'] ?? 'Reminder postponed';
}

class ValidationStrings {
  final Map<String, dynamic> _data;
  ValidationStrings(this._data);

  String get emailRequired => _data['email_required'] ?? 'Email is required';
  String get emailInvalid =>
      _data['email_invalid'] ?? 'Please enter a valid email address';
  String get passwordRequired =>
      _data['password_required'] ?? 'Password is required';
  String get passwordTooShort =>
      _data['password_too_short'] ?? 'Password must be at least 6 characters';
  String get usernameRequired =>
      _data['username_required'] ?? 'Username is required';
  String get fieldRequired =>
      _data['field_required'] ?? 'This field is required';
  String get invalidGlucoseRange =>
      _data['invalid_glucose_range'] ??
      'Min glucose must be less than max glucose';
}

class OptionsData {
  final Map<String, dynamic> _data;
  OptionsData(this._data);

  List<String> get genders =>
      (_data['genders'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
      ['Male', 'Female', 'Other'];

  List<String> get diabetesTypes =>
      (_data['diabetes_types'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      ['Type 1', 'Type 2', 'Gestational'];

  List<String> get treatmentTypes =>
      (_data['treatment_types'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      ['Diet', 'Pills', 'Insulin'];

  List<String> get unitOptions =>
      (_data['unit_options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      ['mg/dL', 'mmol/L'];

  List<String> get themeOptions =>
      (_data['theme_options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      ['light', 'dark', 'system'];
}

/// ============================================================================
/// LOCALIZATIONS DELEGATE
/// ============================================================================

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load();

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
