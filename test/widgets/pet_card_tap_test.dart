import 'package:artrosi_cane/features/home/presentation/widgets/pet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({
    required VoidCallback onTap,
    VoidCallback? onDiaryTap,
    bool insidePageView = false,
    double textScaleFactor = 1,
    bool showDetails = true,
  }) {
    final card = Center(
      child: PetCard(
        name: 'Luna',
        breed: 'Labrador',
        age: showDetails ? 7 : null,
        weight: showDetails ? 24.5 : null,
        imagePath: 'assets/first-dog.png',
        backgroundColor: Colors.white,
        onTap: onTap,
        onDiaryTap: onDiaryTap,
      ),
    );

    return MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it')],
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 568),
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: Scaffold(
          body: SizedBox(
            height: 420,
            child: insidePageView ? PageView(children: [card]) : card,
          ),
        ),
      ),
    );
  }

  testWidgets('PetCard alone responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(buildHarness(onTap: () => tapped = true));
    await tester.tapAt(tester.getCenter(find.byType(PetCard).first));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('PetCard inside PageView responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      buildHarness(onTap: () => tapped = true, insidePageView: true),
    );
    await tester.tapAt(tester.getCenter(find.byType(PetCard).first));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('prominent daily diary action is visible and tappable', (
    tester,
  ) async {
    var cardTapped = false;
    var diaryTapped = false;

    await tester.pumpWidget(
      buildHarness(
        onTap: () => cardTapped = true,
        onDiaryTap: () => diaryTapped = true,
      ),
    );

    final diaryAction = find.byKey(const ValueKey('pet-card-diary-Luna'));
    expect(diaryAction, findsOneWidget);
    expect(find.text('Diario giornaliero'), findsOneWidget);
    expect(tester.getSize(diaryAction).height, greaterThanOrEqualTo(48));

    await tester.tap(diaryAction);
    await tester.pumpAndSettle();

    expect(diaryTapped, isTrue);
    expect(cardTapped, isFalse);
  });

  testWidgets('daily diary action fits a small screen at larger text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        onTap: () {},
        onDiaryTap: () {},
        textScaleFactor: 1.5,
        showDetails: false,
      ),
    );

    expect(find.text('Diario giornaliero'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
