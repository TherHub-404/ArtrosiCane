import 'package:artrosi_cane/features/auth/presentation/screens/auth_prompt_screen.dart';
import 'package:artrosi_cane/features/auth/presentation/screens/change_temp_password_screen.dart';
import 'package:artrosi_cane/features/auth/presentation/screens/entry_screen.dart';
import 'package:artrosi_cane/features/auth/presentation/screens/video_call_request_screen.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/features/daily_check/presentation/screens/daily_check_history_screen.dart';
import 'package:artrosi_cane/features/daily_check/presentation/screens/daily_check_result_screen.dart';
import 'package:artrosi_cane/features/daily_check/presentation/screens/daily_check_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/dog_dashboard_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/exercise_advice_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/walks_advice_screen.dart';
import 'package:artrosi_cane/features/home/presentation/screens/home_screen.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/context_bibione_screen.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/diagnosis_priority_result_screen.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/quiz_flow_screen.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/quiz_result_screen.dart';
import 'package:artrosi_cane/features/walks/presentation/screens/walks_overview_screen.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  const initialLocation = String.fromEnvironment(
    'INITIAL_LOCATION',
    defaultValue: '/',
  );
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/i' || path.startsWith('/i/')) {
        return '/';
      }
      return null;
    },
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
        path: '/context-bibione',
        name: 'contextBibione',
        builder: (context, state) => const ContextBibioneScreen(),
      ),

      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) {
          final extra = state.extra;
          final skipIntro =
              state.uri.queryParameters['skipIntro'] == 'true' ||
              (extra is Map && extra['skipIntro'] == true);
          final startFromDiagnosis =
              state.uri.queryParameters['startFromDiagnosis'] == 'true' ||
              extra is Map && extra['startFromDiagnosis'] == true;
          final dogData = extra is Map
              ? extra['dog'] as Map<String, dynamic>?
              : null;
          return QuizFlowScreen(
            skipIntro: skipIntro,
            startFromDiagnosis: startFromDiagnosis,
            dogData: dogData,
          );
        },
      ),
      GoRoute(
        path: '/quiz/result',
        name: 'quizResult',
        builder: (context, state) {
          final extra = state.extra;
          final result = extra is Map<String, dynamic>
              ? extra['result']
              : extra;
          final dogData = extra is Map<String, dynamic>
              ? extra['dog'] as Map<String, dynamic>?
              : null;
          return QuizResultScreen(result: result, dogData: dogData);
        },
      ),
      GoRoute(
        path: '/quiz/diagnosis-result',
        name: 'quizDiagnosisResult',
        builder: (context, state) {
          final extra = state.extra;
          final showJourneyOnly =
              state.uri.queryParameters['showJourneyOnly'] == 'true' ||
              extra is Map<String, dynamic> && extra['showJourneyOnly'] == true;
          final result = extra is Map<String, dynamic>
              ? extra['result']
              : extra;
          final dogData = extra is Map<String, dynamic>
              ? extra['dog'] as Map<String, dynamic>?
              : null;

          if (!showJourneyOnly && result is! DiagnosisPriorityResult) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.text('Mappa Priorita'))),
              body: Center(
                child: Text(
                  context.l10n.text('Risultato priorita non disponibile.'),
                ),
              ),
            );
          }
          return DiagnosisPriorityResultScreen(
            result: result is DiagnosisPriorityResult ? result : null,
            dogData: dogData,
            showJourneyOnly: showJourneyOnly,
          );
        },
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final entryContext = extra?['entryContext'] as String?;
          final dogData = extra?['dog'] as Map<String, dynamic>?;
          final startInLoginMode = extra?['isLogin'] as bool? ?? false;
          return AuthPromptScreen(
            entryContext: entryContext,
            dogData: dogData,
            startInLoginMode: startInLoginMode,
          );
        },
      ),
      GoRoute(
        path: '/change-temp-password',
        name: 'changeTempPassword',
        builder: (context, state) => const ChangeTempPasswordScreen(),
      ),
      GoRoute(
        path: '/entry',
        name: 'entry',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final dogData = extra?['dog'] as Map<String, dynamic>?;
          return EntryScreen(dogData: dogData);
        },
      ),
      GoRoute(
        path: '/videocall-request',
        name: 'videocallRequest',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final dogData = extra?['dog'] as Map<String, dynamic>?;
          final source = extra?['source'] as String?;
          return VideoCallRequestScreen(dogData: dogData, source: source);
        },
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
                ? context.l10n.text('Il tuo cane')
                : dogName,
            dogId: dogId,
          );
        },
      ),
      GoRoute(
        path: '/daily-check/history',
        name: 'dailyCheckHistory',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final dogId = extra['dogId'] as String?;
          final dogName =
              (extra['dogName'] as String?)?.trim() ??
              context.l10n.text('Il tuo cane');
          if (dogId == null || dogId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.text('Diario'))),
              body: Center(
                child: Text(context.l10n.text('Cane non disponibile.')),
              ),
            );
          }
          return DailyCheckHistoryScreen(dogId: dogId, dogName: dogName);
        },
      ),
      GoRoute(
        path: '/daily-check/result',
        name: 'dailyCheckResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final result = extra['result'];
          final dogName =
              extra['dogName'] as String? ?? context.l10n.text('Il tuo cane');
          if (result is! DailyCheckResult) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.text('Come stai oggi?'))),
              body: Center(
                child: Text(context.l10n.text('Risultato non disponibile.')),
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
            dogName:
                extra['name'] as String? ?? context.l10n.text('Il tuo cane'),
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
            dogName:
                extra['name'] as String? ?? context.l10n.text('Il tuo cane'),
          );
        },
      ),
    ],
  );
});
