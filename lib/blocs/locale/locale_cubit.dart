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
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_state.dart';

/// Cubit for managing application locale/language
///
/// This Cubit handles language preferences and switching.
/// It emits new states when locale is changed.
class LocaleCubit extends Cubit<LocaleState> {
  /// Supported language codes
  static const List<String> supportedLanguages = ['en', 'fr', 'ar'];

  /// Constructor initializes with default locale state (English)
  LocaleCubit() : super(const LocaleState());

  // ============================================================================
  // LOCALE MANAGEMENT
  // ============================================================================

  /// Set locale from language code
  ///
  /// [languageCode] - Two-letter language code: 'en', 'fr', or 'ar'
  void setLocale(String languageCode) {
    if (supportedLanguages.contains(languageCode)) {
      emit(state.copyWith(locale: Locale(languageCode)));
    }
  }

  /// Set locale directly from Locale object
  ///
  /// [locale] - Locale object to set
  void setLocaleFromLocale(Locale locale) {
    if (supportedLanguages.contains(locale.languageCode)) {
      emit(state.copyWith(locale: locale));
    }
  }

  /// Cycle through available languages
  void cycleLanguage() {
    final currentIndex = supportedLanguages.indexOf(state.languageCode);
    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    emit(state.copyWith(locale: Locale(supportedLanguages[nextIndex])));
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
