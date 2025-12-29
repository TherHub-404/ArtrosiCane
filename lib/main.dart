import 'package:artrosi_cane/app.dart';
import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const resetFlow = bool.fromEnvironment('RESET_FLOW');
  await AppConfig.load();
  await initializeSupabase();
  final prefs = await SharedPreferences.getInstance();

  // When running with --dart-define=RESET_FLOW=true we clear local state/sign out
  // only once, so hot restart doesn't keep logging the user out repeatedly.
  final resetApplied = prefs.getBool('resetFlowApplied') ?? false;
  if (resetFlow && !resetApplied) {
    await Supabase.instance.client.auth.signOut();
    await prefs.remove('onboardingCompleted');
    await prefs.remove('dogProfile');
    await prefs.remove('quizProgress');
    await prefs.remove('lastResult');
    await prefs.setBool('resetFlowApplied', true);
  }
  if (!resetFlow && resetApplied) {
    // Clear the marker when running normally.
    await prefs.remove('resetFlowApplied');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ArtrosiCaneApp(),
    ),
  );
}
