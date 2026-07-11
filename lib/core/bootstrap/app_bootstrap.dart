import 'dart:async';

import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/core/logging/app_logger.dart';
import 'package:artrosi_cane/core/notifications/daily_quick_check_notification_service.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appBootstrapProvider = FutureProvider<void>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return AppBootstrapper.ensureInitialized(prefs).timeout(
    const Duration(seconds: 12),
    onTimeout: () {
      AppLogger.debug('App bootstrap timed out, continuing with fallback.');
    },
  );
});

class AppBootstrapper {
  AppBootstrapper._();

  static Future<void>? _bootstrapFuture;

  static Future<void> ensureInitialized(SharedPreferences prefs) {
    return _bootstrapFuture ??= _bootstrap(prefs);
  }

  static void reset() {
    _bootstrapFuture = null;
  }

  static Future<void> _bootstrap(SharedPreferences prefs) async {
    const resetFlow = bool.fromEnvironment('RESET_FLOW');
    const skipNotifications = bool.fromEnvironment('SKIP_NOTIFICATIONS');

    await AppConfig.load();
    await initializeSupabase();

    final resetApplied = prefs.getBool('resetFlowApplied') ?? false;
    if (resetFlow && !resetApplied) {
      await Supabase.instance.client.auth.signOut();
      await prefs.remove('onboardingCompleted');
      await prefs.remove('dogProfile');
      await prefs.remove('quizProgress');
      await prefs.remove('lastResult');
      await prefs.remove('lastResultSyncedSignature');
      await prefs.setBool('resetFlowApplied', true);
    }

    if (!resetFlow && resetApplied) {
      await prefs.remove('resetFlowApplied');
    }
    if (!skipNotifications) {
      unawaited(_initializeNotificationsSafely());
    }
  }

  static Future<void> _initializeNotificationsSafely() async {
    try {
      await DailyQuickCheckNotificationService.initializeAndScheduleDailyReminder();
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Daily reminder initialization failed: $error\n$stackTrace',
      );
    }
  }
}
