import 'dart:async';

import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/core/linking/feature_flags_controller.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/dog_supabase_repository.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key});

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _runEntryFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runEntryFlow() async {
    _timer?.cancel();
    final delay = Future.delayed(const Duration(milliseconds: 4500));
    await Future.wait([delay, _syncDogProfileToRemote()]);
    if (mounted) context.go('/home');
  }

  Future<void> _syncDogProfileToRemote() async {
    try {
      if (_isDemoUser()) return;
      final loadProfile = ref.read(loadDogProfileUseCaseProvider);
      final profile = await loadProfile.call();
      if (profile == null) return;
      await ref.read(dogSupabaseRepositoryProvider).upsertDog(profile);
    } catch (_) {
      // Non-blocking sync
    }
  }

  bool _isDemoUser() {
    final demoEmail = AppConfig.demoEmail;
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    if (demoEmail == null || currentEmail == null) return false;
    return currentEmail.toLowerCase() == demoEmail.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final inviteLocation = ref.watch(
      featureFlagsControllerProvider.select((state) => state.inviteLocation),
    );
    final showBibbioneBackground =
        inviteLocation == 'bibbione' || inviteLocation == 'bibione';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: showBibbioneBackground
                ? Image.asset(
                    'assets/Marina-di-Bibbiona.jpg',
                    fit: BoxFit.cover,
                  )
                : const ColoredBox(color: Colors.white),
          ),
          if (showBibbioneBackground)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  AppText.h1(
                    'Dove stai bene tu,\npuò stare bene anche il tuo cane',
                    align: TextAlign.center,
                    color: showBibbioneBackground
                        ? Colors.white
                        : AppColors.primaryBlue,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: showBibbioneBackground ? 0.2 : 0.08,
                          ),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/ArtrosiCane-Logo.png', width: 140),
                        const SizedBox(height: AppSpacing.lg),
                        Lottie.asset('assets/paw.json', width: 120),
                        const SizedBox(height: AppSpacing.md),
                        AppText.body(
                          'Ti stiamo preparando tutto...',
                          align: TextAlign.center,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
