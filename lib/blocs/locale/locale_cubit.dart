/// ============================================================================
/// LOCALE CUBIT - State Management for App Localization
/// ============================================================================
///
/// This Cubit manages app-wide localization including:
/// - Current locale/language
/// - Language switching
/// - RTL support for Arabic
///
/// Uses the Cubit pattern from flutter_bloc for simpler state management.
/// Settings are persisted to SharedPreferences automatically.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_state.dart';
import '../../services/preferences_service.dart';

/// Cubit for managing application locale/language
///
/// This Cubit handles language preferences and switching.
/// It emits new states when locale is changed and persists to SharedPreferences.
class LocaleCubit extends Cubit<LocaleState> {
  final PreferencesService _prefs = PreferencesService();

  /// Supported language codes
  static const List<String> supportedLanguages = ['en', 'fr', 'ar'];

  /// Constructor initializes with default locale state, then loads saved locale
  LocaleCubit() : super(const LocaleState()) {
    _loadSavedLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadSavedLocale() async {
    try {
      final savedLocale = _prefs.getLocale();
      if (supportedLanguages.contains(savedLocale)) {
        emit(state.copyWith(locale: Locale(savedLocale)));
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  // ============================================================================
  // LOCALE MANAGEMENT
  // ============================================================================

  /// Set locale from language code
  ///
  /// [languageCode] - Two-letter language code: 'en', 'fr', or 'ar'
  void setLocale(String languageCode) {
    if (supportedLanguages.contains(languageCode)) {
      emit(state.copyWith(locale: Locale(languageCode)));
      _prefs.setLocale(languageCode); // Save to SharedPreferences
    }
  }

  /// Set locale directly from Locale object
  ///
  /// [locale] - Locale object to set
  void setLocaleFromLocale(Locale locale) {
    if (supportedLanguages.contains(locale.languageCode)) {
      emit(state.copyWith(locale: locale));
      _prefs.setLocale(locale.languageCode); // Save to SharedPreferences
    }
  }

  /// Cycle through available languages
  void cycleLanguage() {
    final currentIndex = supportedLanguages.indexOf(state.languageCode);
    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    final newLocale = Locale(supportedLanguages[nextIndex]);
    emit(state.copyWith(locale: newLocale));
    _prefs
        .setLocale(supportedLanguages[nextIndex]); // Save to SharedPreferences
  }

  // ============================================================================
  // CONVENIENCE GETTERS (delegating to state)
  // ============================================================================

  /// Get the current locale
  Locale get locale => state.locale;

  /// Get the current language code
  String get languageCode => state.languageCode;

  /// Check if current language is English
  bool get isEnglish => state.isEnglish;

  /// Check if current language is French
  bool get isFrench => state.isFrench;

  /// Check if current language is Arabic
  bool get isArabic => state.isArabic;

  /// Check if current language is RTL
  bool get isRtl => state.isRtl;

  /// Get language name for display
  String getLanguageName(String code) => state.getLanguageName(code);
}
