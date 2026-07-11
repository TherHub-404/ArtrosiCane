import 'package:artrosi_cane/l10n/app_locale.dart';
import 'package:artrosi_cane/l10n/app_translation_catalog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(Localizations.localeOf(context));
  }

  static AppLocalizations get current {
    return AppLocalizations(Locale(Intl.getCurrentLocale()));
  }

  String text(String key, [Map<String, String> params = const {}]) {
    final languageCode = AppLanguage.fromLocale(locale).code;
    final translated = appTranslationCatalog[languageCode]?[key] ?? key;
    return params.entries.fold<String>(
      translated,
      (value, entry) => value.replaceAll('{{${entry.key}}}', entry.value),
    );
  }
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
