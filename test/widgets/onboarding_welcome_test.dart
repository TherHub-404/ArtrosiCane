import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Render OnboardingWelcome with the new entry-page copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: OnboardingWelcomeScreen()),
      ),
    );

    expect(
      find.text(
        'Un progetto pilota\nper il benessere\ndel tuo cane\nin vacanza.',
      ),
      findsOneWidget,
    );
    expect(find.text('In collaborazione con'), findsOneWidget);
    expect(find.text('Osserva'), findsOneWidget);
    expect(find.text('Interpreta'), findsOneWidget);
    expect(find.text('Agisci'), findsOneWidget);
    expect(find.text('Cresci insieme'), findsOneWidget);
    expect(find.text('Inizia il percorso'), findsOneWidget);
  });
}
