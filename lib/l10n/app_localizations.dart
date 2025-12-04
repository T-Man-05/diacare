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
  String get appTitle => translate('appTitle');
  String get welcome => translate('welcome');
  String get welcomeBack => translate('welcomeBack');

  // Authentication
  String get login => translate('login');
  String get signup => translate('signup');
  String get forgotPassword => translate('forgotPassword');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get email => translate('email');
  String get name => translate('name');
  String get fullName => translate('fullName');
  String get username => translate('profile.username');
  String get logout => translate('logout');
  String get logOut => translate('logout');

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
  String get dashboard => translate('dashboard');
  String get glucoseLevel => translate('glucoseLevel');
  String get bloodPressure => translate('bloodPressure');
  String get heartRate => translate('heartRate');
  String get steps => translate('steps');
  String get calories => translate('calories');
  String get sleep => translate('sleep');
  String get weight => translate('weight');
  String get height => translate('height');
  String get average => translate('average');
  String get today => translate('today');

  // Onboarding
  String get dateOfBirth => translate('dateOfBirth');
  String get gender => translate('gender');
  String get male => translate('male');
  String get female => translate('female');
  String get other => translate('other');
  String get diabetesType => translate('diabetesType');
  String get type1 => translate('type1');
  String get type2 => translate('type2');
  String get gestational => translate('gestational');
  String get prediabetes => translate('prediabetes');
  String get diagnosisDate => translate('diagnosisDate');
  String get treatmentType => translate('treatmentType');
  String get insulin => translate('insulin');
  String get oralMedication => translate('oralMedication');
  String get diet => translate('diet');
  String get exercise => translate('exercise');
  String get combination => translate('combination');

  // Glucose
  String get targetRange => translate('targetRange');
  String get lowGlucose => translate('lowGlucose');
  String get normalGlucose => translate('normalGlucose');
  String get highGlucose => translate('highGlucose');
  String get lowRange => translate('lowRange');
  String get normalRange => translate('normalRange');
  String get highRange => translate('highRange');
  String get minimum => translate('minimum');
  String get maximum => translate('maximum');
  String get mgdlUnit => translate('mgdlUnit');
  String get mmolUnit => translate('mmolUnit');

  // Profile
  String get profile => translate('profile');
  String get editProfile => translate('editProfile');
  String get myProfile => translate('profile.my_profile');
  String get saveChanges => translate('saveChanges');
  String get deleteAccount => translate('deleteAccount');
  String get deleteAccountConfirm => translate('deleteAccountConfirm');

  // Diabetic Profile
  String get diabeticProfile => translate('diabeticProfile');
  String get editDiabeticProfile => translate('editDiabeticProfile');

  // Settings
  String get settings => translate('settings');
  String get theme => translate('theme');
  String get darkTheme => translate('darkTheme');
  String get lightTheme => translate('lightTheme');
  String get systemTheme => translate('systemTheme');
  String get themeLight => translate('lightMode');
  String get themeDark => translate('darkMode');
  String get themeSystem => translate('systemDefault');
  String get notifications => translate('notifications');
  String get enableNotifications => translate('enableNotifications');
  String get language => translate('language');
  String get selectLanguage => translate('selectLanguage');
  String get selectTheme => translate('selectTheme');
  String get selectUnits => translate('selectUnits');
  String get units => translate('units');
  String get glucoseUnits => translate('glucoseUnits');
  String get mgdl => translate('mgdl');
  String get mmoll => translate('mmoll');

  // Languages
  String get languageEn => translate('language_en');
  String get languageFr => translate('language_fr');
  String get languageAr => translate('language_ar');

  // Insights
  String get insights => translate('insights');
  String get insightsTitle => translate('insightsTitle');
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
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get confirm => translate('confirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get noData => translate('noData');
  String get viewAll => translate('viewAll');
  String get done => translate('reminders.done');
  String get none => translate('none');
  String get years => translate('years');
  String get to => translate('to');

  // Dialogs
  String get logoutConfirm => translate('logoutConfirm');
  String get accountDeleted => translate('accountDeleted');
  String get loggedOut => translate('loggedOut');
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
