import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
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
    DailyDiaryStatus? diaryStatus,
    bool isDiaryStatusLoading = false,
    bool hasDiaryStatusError = false,
    Locale locale = const Locale('it'),
  }) {
    final card = Center(
      child: PetCard(
        name: 'Luna',
        breed: 'Labrador',
        age: showDetails ? 7 : null,
        weight: showDetails ? 24.5 : null,
        arthrosisGrade: showDetails ? 'Medio' : null,
        imagePath: 'assets/first-dog.png',
        backgroundColor: Colors.white,
        onTap: onTap,
        onDiaryTap: onDiaryTap,
        diaryStatus: diaryStatus,
        isDiaryStatusLoading: isDiaryStatusLoading,
        hasDiaryStatusError: hasDiaryStatusError,
      ),
    );

    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
        Locale('fr'),
        Locale('de'),
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 568),
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: Scaffold(
          body: SizedBox(
            height: PetCard.cardHeight,
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
    expect(find.text('Diario di oggi'), findsOneWidget);
    expect(find.text('Non completato'), findsOneWidget);
    expect(find.text('Completa il diario'), findsOneWidget);
    expect(tester.getSize(diaryAction).height, greaterThanOrEqualTo(48));

    await tester.tap(diaryAction);
    await tester.pumpAndSettle();

    expect(diaryTapped, isTrue);
    expect(cardTapped, isFalse);
  });

  testWidgets('daily diary appears before secondary health information', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(onTap: () {}, onDiaryTap: () {}));

    final diaryTop = tester.getTopLeft(
      find.byKey(const ValueKey('pet-card-diary-Luna')),
    );
    final riskTop = tester.getTopLeft(find.text('Rischio artrosi'));
    final ageTop = tester.getTopLeft(find.text('7 anni'));

    expect(diaryTop.dy, lessThan(riskTop.dy));
    expect(diaryTop.dy, lessThan(ageTop.dy));
    expect(tester.takeException(), isNull);
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

    expect(find.text('Diario di oggi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily diary shows completed status with text and icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        onTap: () {},
        onDiaryTap: () {},
        diaryStatus: DailyDiaryStatus.completed,
      ),
    );

    expect(find.text('Completato oggi'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('daily diary exposes loading and unavailable states', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(onTap: () {}, onDiaryTap: () {}, isDiaryStatusLoading: true),
    );
    expect(find.text('Caricamento stato diario...'), findsOneWidget);

    await tester.pumpWidget(
      buildHarness(onTap: () {}, onDiaryTap: () {}, hasDiaryStatusError: true),
    );
    expect(find.text('Stato diario non disponibile'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('daily diary updates when the application language changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        onTap: () {},
        onDiaryTap: () {},
        diaryStatus: DailyDiaryStatus.completed,
        locale: const Locale('de'),
      ),
    );

    expect(find.text('Heutiges Tagebuch'), findsOneWidget);
    expect(find.text('Heute abgeschlossen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending diary status and action follow the selected language', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        onTap: () {},
        onDiaryTap: () {},
        diaryStatus: DailyDiaryStatus.notStarted,
        locale: const Locale('fr'),
      ),
    );

    expect(find.text('Non terminé'), findsOneWidget);
    expect(find.text('Remplir le journal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
