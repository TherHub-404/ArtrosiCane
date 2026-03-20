import 'package:artrosi_cane/features/auth/presentation/screens/auth_prompt_screen.dart';
import 'package:artrosi_cane/features/auth/presentation/screens/entry_screen.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/features/daily_check/presentation/screens/daily_check_result_screen.dart';
import 'package:artrosi_cane/features/daily_check/presentation/screens/daily_check_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/dog_dashboard_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/exercise_advice_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/walks_advice_screen.dart';
import 'package:artrosi_cane/features/home/presentation/screens/home_screen.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/quiz_flow_screen.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/quiz_result_screen.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/diagnosis_priority_result_screen.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/walks/presentation/screens/walks_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),

      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) {
          final extra = state.extra;
          final skipIntro = extra is Map && extra['skipIntro'] == true;
          final dogData = extra is Map
              ? extra['dog'] as Map<String, dynamic>?
              : null;
          return QuizFlowScreen(skipIntro: skipIntro, dogData: dogData);
        },
      ),
      GoRoute(
        path: '/quiz/result',
        name: 'quizResult',
        builder: (context, state) => QuizResultScreen(result: state.extra),
      ),
      GoRoute(
        path: '/quiz/diagnosis-result',
        name: 'quizDiagnosisResult',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! DiagnosisPriorityResult) {
            return Scaffold(
              appBar: AppBar(title: const Text('Mappa Priorita')),
              body: const Center(
                child: Text('Risultato priorita non disponibile.'),
              ),
            );
          }
          return DiagnosisPriorityResultScreen(result: extra);
        },
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final entryContext = extra?['entryContext'] as String?;
          return AuthPromptScreen(entryContext: entryContext);
        },
      ),
      GoRoute(
        path: '/entry',
        name: 'entry',
        builder: (context, state) => const EntryScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/dog-dashboard',
        name: 'dogDashboard',
        builder: (context, state) {
          final dogData = state.extra as Map<String, dynamic>? ?? {};
          return DogDashboardScreen(dogData: dogData);
        },
      ),
      GoRoute(
        path: '/daily-check',
        name: 'dailyCheck',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final dogName = (extra['dogName'] as String?)?.trim();
          final dogId = extra['dogId'] as String?;
          return DailyCheckScreen(
            dogName: (dogName == null || dogName.isEmpty)
                ? 'Il tuo cane'
                : dogName,
            dogId: dogId,
          );
        },
      ),
      GoRoute(
        path: '/daily-check/result',
        name: 'dailyCheckResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final result = extra['result'];
          final dogName = extra['dogName'] as String? ?? 'Il tuo cane';
          if (result is! DailyCheckResult) {
            return Scaffold(
              appBar: AppBar(title: const Text('Quick Check')),
              body: const Center(
                child: Text('Risultato quick check non disponibile.'),
              ),
            );
          }
          return DailyCheckResultScreen(result: result, dogName: dogName);
        },
      ),
      GoRoute(
        path: '/walks-overview',
        name: 'walksOverview',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const WalksOverviewScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/walks',
        name: 'walks',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return WalksAdviceScreen(
            grade: extra['grade'] as String? ?? '',
            dogName: extra['name'] as String? ?? 'Il tuo cane',
          );
        },
      ),
      GoRoute(
        path: '/exercise',
        name: 'exercise',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ExerciseAdviceScreen(
            grade: extra['grade'] as String? ?? '',
            dogName: extra['name'] as String? ?? 'Il tuo cane',
          );
        },
      ),
    ],
  );
});
