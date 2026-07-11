import 'package:flutter/material.dart';

enum AppLanguage {
  italian('it', 'Italiano', '🇮🇹'),
  english('en', 'English', '🇬🇧'),
  french('fr', 'Français', '🇫🇷'),
  german('de', 'Deutsch', '🇩🇪');

  const AppLanguage(this.code, this.nativeName, this.flag);

  final String code;
  final String nativeName;
  final String flag;

  Locale get locale => Locale(code);

  static List<Locale> get supportedLocales => AppLanguage.values
      .map((language) => language.locale)
      .toList(growable: false);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.italian,
    );
  }

  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }

  static AppLanguage fromPlatformLocale(Locale locale) {
    final match = AppLanguage.values.where(
      (language) => language.code == locale.languageCode,
    );
    return match.isEmpty ? AppLanguage.italian : match.first;
  }
}
