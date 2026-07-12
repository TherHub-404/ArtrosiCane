import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  testWidgets('Render OnboardingWelcome with the new entry-page copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'invite_location': 'bibione'});
    final prefs = await SharedPreferences.getInstance();
    final supabaseClient = _MockSupabaseClient();
    final authClient = _MockGoTrueClient();

    when(() => supabaseClient.auth).thenReturn(authClient);
    when(() => authClient.currentSession).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseClientProvider.overrideWithValue(supabaseClient),
        ],
        child: const MaterialApp(
          locale: Locale('it'),
          supportedLocales: [Locale('it')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OnboardingWelcomeScreen(),
        ),
      ),
    );

    expect(
      find.text('Un progetto pilota per il benessere del tuo cane in vacanza.'),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/logo-bibione.png')),
      findsOneWidget,
    );
    expect(find.text('Osserva'), findsOneWidget);
    expect(find.text('Interpreta'), findsOneWidget);
    expect(find.text('Agisci'), findsOneWidget);
    expect(find.text('Cresci insieme'), findsOneWidget);
    expect(find.text('Inizia il percorso'), findsOneWidget);
  });
}
