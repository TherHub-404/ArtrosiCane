import 'package:artrosi_cane/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Render OnboardingWelcome', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingWelcomeScreen(),
        ),
      ),
    );

    expect(find.text('Benvenuto in Artrosi Cane'), findsOneWidget);
    expect(find.text('Inizia il quiz'), findsOneWidget);
  });
}
