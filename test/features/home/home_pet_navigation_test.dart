import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
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
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/dog-dashboard',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return DogDashboardScreen(dogData: data);
          },
        ),
      ],
    );
  }

  Widget buildApp() {
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
          ];
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
}
