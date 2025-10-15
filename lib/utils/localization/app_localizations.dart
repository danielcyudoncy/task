// utils/localization/app_localizations.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'translations.dart';

class AppLocalizations {
  static final AppLocalizations _instance = AppLocalizations._internal();
  factory AppLocalizations() => _instance;
  AppLocalizations._internal();

  static AppLocalizations get instance => _instance;

  // Supported locales (only those fully supported by Flutter's MaterialLocalizations)
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('fr', 'FR'), // French
  ];

  // All available locales (including those not fully supported by Flutter)
  static const List<Locale> allAvailableLocales = [
    Locale('en', 'US'), // English
    Locale('fr', 'FR'), // French
    Locale('ha', 'NG'), // Hausa
    Locale('yo', 'NG'), // Yoruba
    Locale('ig', 'NG'), // Igbo
  ];

  // Default locale
  static const Locale defaultLocale = Locale('en', 'US');

  // Current locale
  Locale _currentLocale = defaultLocale;
  Locale get currentLocale => _currentLocale;

  // Language code mapping
  static const Map<String, Locale> languageCodeToLocale = {
    'English (Default)': Locale('en', 'US'),
    'French': Locale('fr', 'FR'),
    'Hausa': Locale('ha', 'NG'),
    'Yoruba': Locale('yo', 'NG'),
    'Igbo': Locale('ig', 'NG'),
  };

  static final Map<Locale, String> localeToLanguageName = {
    const Locale('en', 'US'): 'English (Default)',
    const Locale('fr', 'FR'): 'French',
    const Locale('ha', 'NG'): 'Hausa',
    const Locale('yo', 'NG'): 'Yoruba',
    const Locale('ig', 'NG'): 'Igbo',
  };

  // Check if a locale is fully supported by Flutter
  static bool isFullySupported(Locale locale) {
    return supportedLocales.contains(locale);
  }

  // Check if a language name is fully supported
  static bool isLanguageFullySupported(String languageName) {
    final locale = languageCodeToLocale[languageName];
    return locale != null && isFullySupported(locale);
  }

  // Get warning message for unsupported languages
  static String getUnsupportedLanguageWarning(String languageName) {
    return 'unsupported_language_warning'.trParams({'language': languageName});
  }

  // Initialize localization
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage =
        prefs.getString('selectedLanguage') ?? 'English (Default)';
    await changeLanguage(savedLanguage);
  }

  // Change language
  Future<void> changeLanguage(String languageName) async {
    final locale = languageCodeToLocale[languageName];
    if (locale != null) {
      _currentLocale = locale;
      Get.updateLocale(locale);

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', languageName);

      debugPrint(
          '🌍 Language changed to: $languageName (${locale.languageCode})');

      // Show warning for unsupported languages
      if (!isFullySupported(locale)) {
        Get.snackbar(
          'language_warning'.tr,
          getUnsupportedLanguageWarning(languageName),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  // Get current language name
  String getCurrentLanguageName() {
    return localeToLanguageName[_currentLocale] ?? 'English (Default)';
  }

  // Get supported language names
  List<String> getSupportedLanguageNames() {
    return languageCodeToLocale.keys.toList();
  }

  // Get fully supported language names only
  List<String> getFullySupportedLanguageNames() {
    return languageCodeToLocale.entries
        .where((entry) => isFullySupported(entry.value))
        .map((entry) => entry.key)
        .toList();
  }

  // Get locale from language name
  Locale? getLocaleFromLanguageName(String languageName) {
    return languageCodeToLocale[languageName];
  }

  // Get language name from locale
  String getLanguageNameFromLocale(Locale locale) {
    return localeToLanguageName[locale] ?? 'English (Default)';
  }
}
