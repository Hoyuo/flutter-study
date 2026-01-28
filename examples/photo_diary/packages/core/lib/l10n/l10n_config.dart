import 'package:flutter/material.dart';

/// Localization configuration for the app
class L10nConfig {
  L10nConfig._();

  /// Supported locales for the app
  static const List<Locale> supportedLocales = [
    Locale('ko', 'KR'), // Korean
    Locale('ja', 'JP'), // Japanese
    Locale('zh', 'TW'), // Chinese (Traditional)
  ];

  /// Fallback locale when user's locale is not supported
  static const Locale fallbackLocale = Locale('ko', 'KR');

  /// Path to translation files (for EasyLocalization)
  static const String translationsPath = 'assets/translations';

  /// Check if a locale is supported
  static bool isSupported(Locale locale) {
    return supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  /// Get locale from language code
  static Locale? getLocaleFromCode(String languageCode) {
    try {
      return supportedLocales.firstWhere(
        (locale) => locale.languageCode == languageCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get display name for locale
  static String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'ja':
        return '日本語';
      case 'zh':
        return '繁體中文';
      default:
        return locale.languageCode;
    }
  }

  /// Locale resolution callback for MaterialApp
  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) {
      return fallbackLocale;
    }

    // Check for exact match
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return supportedLocale;
      }
    }

    // Check for language match
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    // Return fallback locale
    return fallbackLocale;
  }
}
