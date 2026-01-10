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
/// Settings are persisted to backend via AppDataSource and cached locally.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_state.dart';
import '../../services/preferences_service.dart';
import '../../domain/app_data_source.dart';

/// Cubit for managing application locale/language
///
/// This Cubit handles language preferences and switching.
/// It emits new states when locale is changed and persists to backend.
class LocaleCubit extends Cubit<LocaleState> {
  final PreferencesService _prefs = PreferencesService();
  final AppDataSource _dataSource;

  /// Supported language codes
  static const List<String> supportedLanguages = ['en', 'fr', 'ar'];

  /// Constructor initializes with default locale state, then loads saved locale
  LocaleCubit(this._dataSource) : super(const LocaleState()) {
    _loadSavedLocale();
  }

  /// Load saved locale from backend via AppDataSource
  Future<void> _loadSavedLocale() async {
    try {
      // Try to load from backend first
      try {
        final settingsData = await _dataSource.getSettingsData();
        if (supportedLanguages.contains(settingsData.locale)) {
          emit(state.copyWith(locale: Locale(settingsData.locale)));
        }
        return;
      } catch (e) {
        // Not being logged in is a normal startup state; don't treat it as an error.
        if (e is DataSourceException && e.code == 'not_authenticated') {
          // silent
        } else {
          debugPrint('Failed to load locale from backend, using local: $e');
        }
      }

      // Fallback to local storage if backend fails
      final savedLocale = _prefs.getLocale();
      if (supportedLanguages.contains(savedLocale)) {
        emit(state.copyWith(locale: Locale(savedLocale)));
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  /// Public method to reload locale from SharedPreferences
  Future<void> loadLocale() => _loadSavedLocale();

  // ============================================================================
  // LOCALE MANAGEMENT
  // ============================================================================

  /// Set locale from language code
  ///
  /// [languageCode] - Two-letter language code: 'en', 'fr', or 'ar'
  Future<void> setLocale(String languageCode) async {
    if (supportedLanguages.contains(languageCode)) {
      emit(state.copyWith(locale: Locale(languageCode)));

      try {
        await _dataSource.setLocale(languageCode);
      } catch (e) {
        debugPrint('Error persisting locale to backend: $e');
      }
    }
  }

  /// Set locale directly from Locale object
  ///
  /// [locale] - Locale object to set
  Future<void> setLocaleFromLocale(Locale locale) async {
    if (supportedLanguages.contains(locale.languageCode)) {
      emit(state.copyWith(locale: locale));

      try {
        await _dataSource.setLocale(locale.languageCode);
      } catch (e) {
        debugPrint('Error persisting locale to backend: $e');
      }
    }
  }

  /// Cycle through available languages
  Future<void> cycleLanguage() async {
    final currentIndex = supportedLanguages.indexOf(state.languageCode);
    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    final newLocale = Locale(supportedLanguages[nextIndex]);
    emit(state.copyWith(locale: newLocale));

    try {
      await _dataSource.setLocale(supportedLanguages[nextIndex]);
    } catch (e) {
      debugPrint('Error persisting locale to backend: $e');
    }
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
