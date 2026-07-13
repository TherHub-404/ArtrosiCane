import 'package:artrosi_cane/features/onboarding/domain/entities/breed.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/dog_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({required ValueChanged<DogProfile> onProfileChanged}) {
    return ProviderScope(
      overrides: [
        breedListProvider.overrideWith((ref) async {
          return const [
            Breed(
              id: 'mixed',
              name: Breed.mixedBreedCanonicalName,
              nameIt: 'Razza mista',
            ),
            Breed(id: 'lab', name: 'Labrador Retriever', nameIt: 'Labrador'),
          ];
        }),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        supportedLocales: const [Locale('it')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: DogProfilePage(
            bottomContentPadding: 96,
            onProfileChanged: onProfileChanged,
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(height: 76, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> pumpIPhone13(WidgetTester tester, Widget widget) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(DogProfilePage), const Offset(0, -520));
    await tester.pumpAndSettle();
  }

  testWidgets('breed controls remain tappable on iPhone 13 viewport', (
    tester,
  ) async {
    DogProfile? latestProfile;

    await pumpIPhone13(
      tester,
      buildSubject(onProfileChanged: (profile) => latestProfile = profile),
    );

    await tester.tap(find.text('Razza mista'));
    await tester.pumpAndSettle();

    expect(latestProfile?.breedId, 'mixed');
    expect(latestProfile?.breedName, 'Razza mista');
  });

  testWidgets('breed picker opens and selects a breed on iPhone 13 viewport', (
    tester,
  ) async {
    DogProfile? latestProfile;

    await pumpIPhone13(
      tester,
      buildSubject(onProfileChanged: (profile) => latestProfile = profile),
    );

    await tester.tap(find.text('Seleziona razza'));
    await tester.pumpAndSettle();
    expect(find.text('Labrador'), findsOneWidget);

    await tester.tap(find.text('Labrador'));
    await tester.pumpAndSettle();

    expect(latestProfile?.breedId, 'lab');
    expect(latestProfile?.breedName, 'Labrador');
  });
}
