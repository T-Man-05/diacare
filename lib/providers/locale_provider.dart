import 'package:flutter/material.dart';

/// Provider to manage app locale/language
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isEnglish => _locale.languageCode == 'en';
  bool get isFrench => _locale.languageCode == 'fr';
  bool get isArabic => _locale.languageCode == 'ar';

  /// Set locale from language code
  void setLocale(String languageCode) {
    if (['en', 'fr', 'ar'].contains(languageCode)) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  /// Set locale directly
  void setLocaleFromLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  /// Get language name for display
  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }
}
