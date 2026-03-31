import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Render OnboardingWelcome with Bibbione copy', (tester) async {
    SharedPreferences.setMockInitialValues({'invite_location': 'bibbione'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(home: OnboardingWelcomeScreen()),
      ),
    );

    expect(
      find.text('30 secondi per capire\ncome muoversi oggi.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Ti aiutiamo a proteggere le articolazioni del tuo cane in vacanza',
      ),
      findsOneWidget,
    );
    expect(find.text('Inizia'), findsOneWidget);
  });

  testWidgets('Render OnboardingWelcome with normal copy', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(home: OnboardingWelcomeScreen()),
      ),
    );

    expect(
      find.text('Ti aiutiamo a proteggere le articolazioni del tuo cane'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Ti aiutiamo a proteggere le articolazioni del tuo cane in vacanza',
      ),
      findsNothing,
    );
  });
}
