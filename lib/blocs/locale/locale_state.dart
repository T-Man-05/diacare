/// ============================================================================
/// LOCALE STATE - BLoC State for App Localization
/// ============================================================================
///
/// This file defines the state class for locale/language management.
/// It handles the current locale and provides helper methods for language info.
/// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// State class for Locale Cubit
/// Uses Equatable for value comparison
class LocaleState extends Equatable {
  /// Current app locale
  final Locale locale;

  /// Constructor with default English locale
  const LocaleState({
    this.locale = const Locale('en'),
  });

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Get the current language code
  String get languageCode => locale.languageCode;

  /// Check if current language is English
  bool get isEnglish => locale.languageCode == 'en';

  /// Check if current language is French
  bool get isFrench => locale.languageCode == 'fr';

  /// Check if current language is Arabic
  bool get isArabic => locale.languageCode == 'ar';

  /// Check if current language is RTL (Right-to-Left)
  bool get isRtl => locale.languageCode == 'ar';

  /// Get text direction based on current locale
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

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

  /// Get current language name
  String get currentLanguageName => getLanguageName(languageCode);

  // ============================================================================
  // COPY WITH METHOD
  // ============================================================================

  /// Create a copy of the state with optional new locale
  LocaleState copyWith({
    Locale? locale,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
    );
  }

  // ============================================================================
  // EQUATABLE PROPS
  // ============================================================================

  @override
  List<Object?> get props => [locale];
}
