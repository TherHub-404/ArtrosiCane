import 'package:artrosi_cane/features/auth/presentation/screens/auth_prompt_screen.dart';
import 'package:artrosi_cane/features/home/presentation/screens/home_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/dog_dashboard_screen.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/screens/walks_advice_screen.dart';

import 'package:artrosi_cane/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/quiz_flow_screen.dart';
import 'package:artrosi_cane/features/quiz/presentation/screens/quiz_result_screen.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          final dogData = extra is Map ? extra['dog'] as Map<String, dynamic>? : null;
          return QuizFlowScreen(skipIntro: skipIntro, dogData: dogData);
        },
      ),
      GoRoute(
        path: '/quiz/result',
        name: 'quizResult',
        builder: (context, state) => QuizResultScreen(
          result: state.extra,
        ),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPromptScreen(),
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
    ],
  );
});
