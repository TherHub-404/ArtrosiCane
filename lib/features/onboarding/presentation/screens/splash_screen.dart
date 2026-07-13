import 'package:artrosi_cane/core/bootstrap/app_bootstrap.dart';
import 'package:artrosi_cane/core/linking/feature_flags_controller.dart';
import 'package:artrosi_cane/core/linking/link_service.dart';
import 'package:artrosi_cane/core/logging/app_logger.dart';
import 'package:artrosi_cane/core/providers/preferences_data_source_provider.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/core/utils/responsive.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/auth/data/auth_repository.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/onboarding/data/models/dog_profile_model.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _linkServiceStarted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _resolveStartup() async {
    if (_navigated) {
      return;
    }

    try {
      // On the very first launch the install referrer / deep link may still
      // be processing when we get here. Wait briefly so we can honor
      // `?location=skip-onboard` (and `bibione`) before deciding the route.
      // Capped to avoid hanging the splash on slow networks; on subsequent
      // launches the location is hydrated synchronously from SharedPreferences
      // so this branch is skipped.
      final cachedLocation = ref
          .read(featureFlagsControllerProvider)
          .inviteLocation;
      if (cachedLocation == null) {
        await _startLinkServiceIfNeeded().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }

      final repo = ref.read(authRepositoryProvider);
      final softDeleted = await repo.signOutIfCurrentUserSoftDeleted().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      final hardDeleted = softDeleted
          ? false
          : await repo.signOutIfCurrentUserHardDeleted().timeout(
              const Duration(seconds: 8),
              onTimeout: () => false,
            );
      if (softDeleted || hardDeleted) {
        final prefs = ref.read(sharedPreferencesProvider);
        await repo.signOutAndClearLocalState(prefs);
        if (!mounted) return;
        _navigated = true;
        context.go('/auth');
        return;
      }

      // If a session exists, claim any pre-populated profile (from the
      // marketing website) and hydrate the local cache from remote dogs
      // so the user does not redo onboarding for data already collected.
      final session = ref.read(supabaseClientProvider).auth.currentSession;
      if (session != null) {
        await repo.claimProfile().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        await _hydrateOnboardingFromRemoteIfNeeded().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      }

      if (!mounted) return;
      _navigated = true;
      // The onboarding welcome screen is shown for every launch — also for
      // skip-onboard users, who still see the entry page (dog photo +
      // "Continua") and only skip the *quiz* on tap, going straight to
      // /auth. Bibione and logged-in routing is decided by the welcome
      // screen itself based on the same flags.
      context.go('/onboarding');
    } catch (error, stackTrace) {
      AppLogger.debug('Splash startup fallback triggered: $error\n$stackTrace');
      if (!mounted) return;
      _navigated = true;
      context.go('/onboarding');
    }
  }

  /// If the local cache has no dog and the website pre-populated dogs for
  /// this user, hydrate the local profile and mark onboarding complete so
  /// the user is taken straight to /home.
  Future<void> _hydrateOnboardingFromRemoteIfNeeded() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final cache = ref.read(preferencesDataSourceProvider);

      final alreadyCompleted = prefs.getBool('onboardingCompleted') ?? false;
      final localDog = await cache.loadDogProfile();
      if (alreadyCompleted || localDog != null) return;

      final remoteDogs = await ref
          .read(dogRemoteRepositoryProvider)
          .fetchDogs();
      if (remoteDogs.isEmpty) return;

      await cache.saveDogProfile(DogProfileModel.fromEntity(remoteDogs.first));
      await prefs.setBool('onboardingCompleted', true);
    } catch (error, stackTrace) {
      AppLogger.debug('Hydrate from remote failed: $error\n$stackTrace');
    }
  }

  Future<void> _startLinkServiceIfNeeded() async {
    if (_linkServiceStarted) {
      return;
    }

    _linkServiceStarted = true;
    try {
      await ref.read(linkServiceProvider).start();
    } catch (error, stackTrace) {
      AppLogger.debug('Unable to start link service: $error\n$stackTrace');
    }
  }

  void _retryBootstrap() {
    Haptics.tap();
    AppBootstrapper.reset();
    ref.invalidate(appBootstrapProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen<AsyncValue<void>>(appBootstrapProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          _startLinkServiceIfNeeded();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _resolveStartup(),
          );
        },
      );
    });
    final bootstrap = ref.watch(appBootstrapProvider);

    return AppScaffold(
      backgroundColor: AppColors.ctaApricot,
      padding: const EdgeInsets.all(AppSpacing.xl),
      body: bootstrap.when(
        data: (_) => Center(
          child: Lottie.asset('assets/paw.json', width: context.scaled(200)),
        ),
        loading: () => Center(
          child: Lottie.asset('assets/paw.json', width: context.scaled(200)),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText.body(
                l10n.text('L\'app non e riuscita ad avviarsi correttamente.'),
                align: TextAlign.center,
                color: AppColors.primaryBlue,
                bold: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText.body(
                'Tocca qui sotto per riprovare.',
                align: TextAlign.center,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _retryBootstrap,
                child: Text(l10n.text('Riprova')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
