import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/l10n/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLocaleNotifier extends Notifier<Locale?> {
  static const _localePreferenceKey = 'appLocaleCode';

  @override
  Locale? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedCode = prefs.getString(_localePreferenceKey);
    if (savedCode != null && savedCode.isNotEmpty) {
      return AppLanguage.fromCode(savedCode).locale;
    }

    return null;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language.locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localePreferenceKey, language.code);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale?>(
  AppLocaleNotifier.new,
);
