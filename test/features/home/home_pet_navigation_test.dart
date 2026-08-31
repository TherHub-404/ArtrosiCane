import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/features/daily_check/presentation/providers/daily_check_providers.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/dog_dashboard_screen.dart';
import 'package:artrosi_cane/features/home/data/daily_sentence_repository.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/features/home/presentation/screens/home_screen.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/pet_card.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late SharedPreferences prefs;
  late _MockSupabaseClient supabaseClient;
  late _MockGoTrueClient authClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    supabaseClient = _MockSupabaseClient();
    authClient = _MockGoTrueClient();

    when(() => supabaseClient.auth).thenReturn(authClient);
    when(() => authClient.currentUser).thenReturn(null);
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/dog-dashboard',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return DogDashboardScreen(dogData: data);
          },
        ),
        GoRoute(
          path: '/daily-check',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return Scaffold(
              body: Text('daily-check-${data['dogId']}-${data['dogName']}'),
            );
          },
        ),
      ],
    );
  }

  Widget buildApp({Map<String, DailyDiaryStatus> diaryStatuses = const {}}) {
    final router = buildRouter();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(supabaseClient),
        userDogsProvider.overrideWith((ref) async {
          return const [
            DogProfile(
              id: 'dog-1',
              name: 'Luna',
              breedName: 'Labrador',
              breedImageUrl: 'assets/first-dog.png',
              ageYears: 7,
              weightKg: 24.5,
              riskLevel: 'medio',
            ),
            DogProfile(
              id: 'dog-2',
              name: 'Milo',
              breedName: 'Beagle',
              breedImageUrl: 'assets/first-dog.png',
              ageYears: 5,
              weightKg: 12,
              riskLevel: 'basso',
            ),
          ];
        }),
        todayDailyDiaryStateProvider.overrideWith((ref, dogId) async {
          return TodayDailyDiaryState(
            status: diaryStatuses[dogId] ?? DailyDiaryStatus.notStarted,
          );
        }),
        dailySentenceForTodayProvider('it').overrideWith((ref) async {
          return const DailySentence(
            languageCode: 'it',
            monthNum: 4,
            dayNum: 1,
            themeMonth: 'Ambiente e casa',
            category: 'osservazione',
            categoryKey: 'observation',
            phrase: 'Frase del giorno',
            explanation: 'Spiegazione di test.',
            microAction: 'Azione di test.',
          );
        }),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('it')],
      ),
    );
  }

  testWidgets('tapping a dog card from Home opens DogDashboardScreen', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final tappableCard = find.byKey(const ValueKey('pet-card-dog-1'));
    expect(tappableCard, findsOneWidget);

    await tester.ensureVisible(tappableCard);
    await tester.pumpAndSettle();

    await tester.tap(tappableCard);
    await tester.pumpAndSettle();

    expect(find.byType(DogDashboardScreen), findsOneWidget);
  });

  testWidgets('PetCard callback from Home opens DogDashboardScreen', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final petCard = tester.widget<PetCard>(find.byType(PetCard).first);
    expect(petCard.onTap, isNotNull);

    petCard.onTap!.call();
    await tester.pumpAndSettle();

    expect(find.byType(DogDashboardScreen), findsOneWidget);
  });
  testWidgets('each dog card opens an independent diary for that dog', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('pet-card-diary-Luna')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-diary-card-dog-1')), findsNothing);

    tester
        .widgetList<PetCard>(find.byType(PetCard))
        .toList()[0]
        .onDiaryTap!
        .call();
    await tester.pumpAndSettle();
    expect(find.text('daily-check-dog-1-Luna'), findsOneWidget);

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('pet-card-diary-Milo')), findsOneWidget);

    tester
        .widgetList<PetCard>(find.byType(PetCard))
        .toList()[1]
        .onDiaryTap!
        .call();
    await tester.pumpAndSettle();
    expect(find.text('daily-check-dog-2-Milo'), findsOneWidget);
  });

  testWidgets('each dog card displays its independent daily diary status', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        diaryStatuses: const {
          'dog-1': DailyDiaryStatus.completed,
          'dog-2': DailyDiaryStatus.notStarted,
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Completato oggi'), findsOneWidget);

    final carousel = find.byKey(const ValueKey('pet-carousel-page-view'));
    await tester.ensureVisible(carousel);
    await tester.pumpAndSettle();
    await tester.drag(carousel, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Completa il diario'), findsOneWidget);
    expect(find.byKey(const ValueKey('pet-card-diary-Milo')), findsOneWidget);
  });
}
