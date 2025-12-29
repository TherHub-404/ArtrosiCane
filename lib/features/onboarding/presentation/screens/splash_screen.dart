import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(isOnboardingCompletedProvider, (previous, next) {
      next.whenData((completed) {
        if (completed) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      });
    });

    final status = ref.watch(isOnboardingCompletedProvider);

    return AppScaffold(
      backgroundColor: AppColors.ctaApricot,
      padding: const EdgeInsets.all(AppSpacing.xl),
      body: Center(
        child: status.when(
          data: (_) => const SizedBox.shrink(),
          loading: () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: AppSpacing.md),
              AppText.body(
                'Stiamo preparando il quiz per te...',
                align: TextAlign.center,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          error: (_, __) => AppText.body(
            'Caricamento...',
            align: TextAlign.center,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}
