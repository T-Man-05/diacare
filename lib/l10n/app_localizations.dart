import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Localization service for multi-language support
class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  /// Access instance from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Delegate for MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  /// Load translations from JSON file
  Future<bool> load() async {
    String jsonString =
        await rootBundle.loadString('assets/l10n/${locale.languageCode}.json');
    _localizedStrings = json.decode(jsonString);
    return true;
  }

  /// Get a simple translation
  String translate(String key) {
    return _getNestedValue(key) ?? key;
  }

  /// Get a translation with parameters
  String translateWithParams(String key, Map<String, String> params) {
    String translation = translate(key);
    params.forEach((paramKey, value) {
      translation = translation.replaceAll('{$paramKey}', value);
    });
    return translation;
  }

  /// Access nested values (e.g., "login.title")
  String? _getNestedValue(String key) {
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;

    for (String k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return null;
      }
    }

    return value is String ? value : null;
  }

  /// Check if language is RTL
  bool get isRtl => locale.languageCode == 'ar';

  /// Get text direction
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  // ============================================================================
  // TRANSLATION SHORTCUTS
  // ============================================================================

  // App
  String get appTitle => translate('app_name');
  String get welcome => translate('welcome');
  String get welcomeBack => translate('welcome');

  // Authentication
  String get login => translate('login.title');
  String get signup => translate('signup.title');
  String get forgotPassword => translate('login.forgot_password');
  String get password => translate('login.password_label');
  String get confirmPassword => translate('confirmPassword');
  String get email => translate('login.email_label');
  String get name => translate('name');
  String get fullName => translate('profile.full_name');
  String get username => translate('profile.username');
  String get logout => translate('profile.log_out');
  String get logOut => translate('profile.log_out');

  // Validation Messages
  String get emailRequired => translate('errors.email_required');
  String get invalidEmail => translate('errors.invalid_email');
  String get emailInvalid => translate('errors.invalid_email');
  String get passwordRequired => translate('errors.password_required');
  String get passwordTooShort => translate('errors.password_too_short');
  String get passwordsDoNotMatch => translate('errors.passwords_do_not_match');
  String get nameRequired => translate('errors.name_required');
  String get nameTooShort => translate('errors.name_too_short');
  String get fieldRequired => translate('errors.field_required');
  String get invalidNumber => translate('errors.invalid_number');
  String get numberTooLow => translate('errors.number_too_low');
  String get numberTooHigh => translate('errors.number_too_high');
  String get invalidCredentials => translate('errors.invalid_credentials');
  String get accountNotFound => translate('errors.account_not_found');
  String get emailAlreadyExists => translate('errors.email_already_exists');
  String get invalidRange => translate('errors.invalid_range');
  String get minGreaterThanMax => translate('errors.min_greater_than_max');
  String get validationError => translate('errors.validation_error');
  String get pleaseFixErrors => translate('errors.please_fix_errors');
  String get fullNameRequired => translate('errors.full_name_required');
  String get fullNameMinLength => translate('errors.full_name_min_length');
  String get usernameRequired => translate('errors.username_required');
  String get usernameMinLength => translate('errors.username_min_length');
  String get usernameInvalid => translate('errors.username_invalid');

  // Success Messages
  String get loginSuccess => translate('loginSuccess');
  String get signupSuccess => translate('signupSuccess');
  String get profileUpdateSuccess => translate('profileUpdateSuccess');
  String get profileUpdateError => translate('profileUpdateError');
  String get profileUpdated => translate('profile.profile_updated');

  // Dashboard
  String get dashboard => translate('home');
  String get glucoseLevel => translate('dashboard.glucose');
  String get bloodPressure => translate('bloodPressure');
  String get heartRate => translate('heartRate');
  String get steps => translate('steps');
  String get calories => translate('calories');
  String get sleep => translate('sleep');
  String get weight => translate('onboarding.weight');
  String get height => translate('onboarding.height');
  String get average => translate('average');
  String get today => translate('today');
  String get youAreFine => translate('dashboard.you_are_fine');
  String greeting(String name) =>
      translateWithParams('dashboard.greeting', {'name': name});
  String get nextReminder => translate('dashboard.next_reminder');

  // Health Cards
  String get water => translate('health_cards.water');
  String get pills => translate('health_cards.pills');
  String get activity => translate('health_cards.activity');
  String get insulinCard => translate('health_cards.insulin');

  // Onboarding
  String get dateOfBirth => translate('onboarding.date_of_birth');
  String get gender => translate('onboarding.gender');
  String get male => translate('onboarding.gender_male');
  String get female => translate('onboarding.gender_female');
  String get other => translate('onboarding.gender_other');
  String get diabetesType => translate('onboarding.diabetes_type');
  String get type1 => translate('onboarding.diabetes_type_1');
  String get type2 => translate('onboarding.diabetes_type_2');
  String get gestational => translate('onboarding.diabetes_gestational');
  String get prediabetes => translate('prediabetes');
  String get diagnosisDate => translate('onboarding.diagnosis_duration');
  String get treatmentType => translate('onboarding.treatment_type');
  String get insulin => translate('diabetics_profile.treatment_insulin');
  String get oralMedication => translate('diabetics_profile.treatment_pills');
  String get diet => translate('diabetics_profile.treatment_diet');
  String get exercise => translate('exercise');
  String get combination => translate('combination');

  // Glucose
  String get targetRange => translate('diabetics_profile.glucose_target');
  String get lowGlucose => translate('lowGlucose');
  String get normalGlucose => translate('chart.normal');
  String get highGlucose => translate('chart.above_normal');
  String get lowRange => translate('lowRange');
  String get normalRange => translate('chart.normal');
  String get highRange => translate('chart.above_normal');
  String get minimum => translate('diabetics_profile.min');
  String get maximum => translate('diabetics_profile.max');
  String get mgdlUnit => translate('settings.unit_mgdl');
  String get mmolUnit => translate('settings.unit_mmol');

  // Profile
  String get profile => translate('profile.title');
  String get editProfile => translate('profile.edit_profile');
  String get myProfile => translate('profile.my_profile');
  String get saveChanges => translate('profile.save_changes');
  String get deleteAccount => translate('profile.delete_account');
  String get deleteAccountConfirm =>
      translate('dialogs.delete_account_confirm');
  String get profileLogOut => translate('profile.log_out');
  String get profileFullName => translate('profile.full_name');
  String get profileUsername => translate('profile.username');
  String get profileEmail => translate('profile.email');

  // Diabetic Profile
  String get diabeticProfile => translate('profile.diabetics_profile');
  String get editDiabeticProfile => translate('diabetics_profile.title');
  String get diabeticType => translate('diabetics_profile.diabetic_type');
  String get glucoseTarget => translate('diabetics_profile.glucose_target');
  String get minGlucose => translate('diabetics_profile.min');
  String get maxGlucose => translate('diabetics_profile.max');
  String get selectDiabeticType =>
      translate('diabetics_profile.select_diabetic_type');
  String get selectTreatmentType =>
      translate('diabetics_profile.select_treatment_type');
  String get treatmentDiet => translate('diabetics_profile.treatment_diet');
  String get treatmentPills => translate('diabetics_profile.treatment_pills');
  String get treatmentInsulin =>
      translate('diabetics_profile.treatment_insulin');
  String get diabeticProfileUpdated => translate('diabetics_profile.updated');

  // Settings
  String get settings => translate('profile.settings');
  String get settingsTitle => translate('settings.title');
  String get theme => translate('settings.theme');
  String get darkTheme => translate('settings.theme_dark');
  String get lightTheme => translate('settings.theme_light');
  String get systemTheme => translate('settings.theme_system');
  String get themeLight => translate('settings.theme_light');
  String get themeDark => translate('settings.theme_dark');
  String get themeSystem => translate('settings.theme_system');
  String get notifications => translate('settings.notifications');
  String get enableNotifications => translate('settings.enable_notifications');
  String get language => translate('settings.language');
  String get selectLanguage => translate('settings.select_language');
  String get selectTheme => translate('selectTheme');
  String get selectUnits => translate('selectUnits');
  String get units => translate('settings.units');
  String get glucoseUnits => translate('settings.units_preference');
  String get mgdl => translate('settings.unit_mgdl');
  String get mmoll => translate('settings.unit_mmol');

  // Languages
  String get languageEn => translate('languages.english');
  String get languageFr => translate('languages.french');
  String get languageAr => translate('languages.arabic');

  // Insights
  String get insights => translate('insights.title');
  String get insightsTitle => translate('insights.title');
  String get weeklyReport => translate('weeklyReport');
  String get monthlyReport => translate('monthlyReport');
  String get glucoseTrends => translate('glucoseTrends');
  String get averageGlucose => translate('averageGlucose');

  // Chat
  String get chat => translate('chat.title');
  String get chatDescription => translate('chat.description');
  String get chatWithAi => translate('chatWithAi');
  String get aiInsights => translate('aiInsights');
  String get askAboutDiabetes => translate('askAboutDiabetes');
  String get noMessages => translate('noMessages');
  String get startConversation => translate('startConversation');

  // Insights
  String get insightsPageTitle => translate('insights.title');

  // Reminders
  String get reminders => translate('reminders.title');
  String get addReminder => translate('addReminder');
  String get editReminder => translate('editReminder');
  String get deleteReminder => translate('deleteReminder');
  String get reminderTitle => translate('reminderTitle');
  String get noReminders => translate('noReminders');
  String get checkGlucose => translate('reminders.check_glucose');
  String get drinkWater => translate('reminders.drink_water');
  String get takePill => translate('reminders.take_pill');
  String get nextTime => translate('reminders.next_time');
  String get notificationsEnabled =>
      translate('reminders.notifications_enabled');
  String get notificationsDisabled =>
      translate('reminders.notifications_disabled');
  String get reminderDone => translate('reminders.done');
  String get reminderNotDone => translate('reminders.not_done');
  String get reminderDoLater => translate('reminders.do_later');
  String get markedDone => translate('reminders.marked_done');
  String get markedNotDone => translate('reminders.marked_not_done');
  String get reminderPostponed => translate('reminders.postponed');

  // Chart
  String get bloodSugar => translate('chart.blood_sugar');
  String get beforeMeal => translate('chart.before_meal');
  String get afterMeal => translate('chart.after_meal');
  String get normal => translate('chart.normal');
  String get aboveNormal => translate('chart.above_normal');
  String get aboveUsual => translate('chart.above_usual');
  String get dailyActivity => translate('chart.daily_activity');
  String get day => translate('chart.day');
  String get seeDetails => translate('dashboard.see_details');
  String get carbs => translate('health_cards.carbs');

  // Days
  String get daySat => translate('days.sat');
  String get daySun => translate('days.sun');
  String get dayMon => translate('days.mon');
  String get dayTue => translate('days.tue');
  String get dayWed => translate('days.wed');
  String get dayThu => translate('days.thu');
  String get dayFri => translate('days.fri');

  // Common
  String get save => translate('profile.save_changes');
  String get cancel => translate('dialogs.cancel');
  String get delete => translate('profile.delete_account');
  String get edit => translate('profile.edit_profile');
  String get confirm => translate('dialogs.confirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get loading => translate('loading');
  String get error => translate('errors.loading_error');
  String get retry => translate('retry');
  String get noData => translate('noData');
  String get viewAll => translate('viewAll');
  String get done => translate('reminders.done');
  String get none => translate('none');
  String get years => translate('years');
  String get to => translate('to');

  // Dialogs
  String get logoutConfirm => translate('dialogs.logout_confirm');
  String get accountDeleted => translate('dialogs.account_deleted');
  String get loggedOut => translate('dialogs.logged_out');
  String get dialogCancel => translate('dialogs.cancel');
  String get dialogConfirm => translate('dialogs.confirm');
}

/// Delegate for loading localizations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
