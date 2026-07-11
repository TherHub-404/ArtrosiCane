import 'dart:async';

import 'package:artrosi_cane/core/linking/feature_flags_controller.dart';
import 'package:artrosi_cane/core/providers/preferences_data_source_provider.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/core/utils/responsive.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/auth/data/auth_repository.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/onboarding/data/models/dog_profile_model.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/dog_supabase_repository.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key, this.dogData});

  final Map<String, dynamic>? dogData;

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPendingPostAuthMessage();
    });
    _runEntryFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runEntryFlow() async {
    _timer?.cancel();
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 4500)),
      _claimAndSync(),
    ]);
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _claimAndSync() async {
    // Bind any pre-populated profile (from the marketing website) to the
    // current auth user, then hydrate local cache from any pre-populated
    // dogs before pushing local changes upstream.
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session != null) {
      try {
        await ref
            .read(authRepositoryProvider)
            .claimProfile()
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
      } catch (_) {}
      await _hydrateFromRemoteIfNeeded();
    }
    await _syncDogProfileToRemote();
  }

  Future<void> _hydrateFromRemoteIfNeeded() async {
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
    } catch (_) {
      // Non-blocking hydration.
    }
  }

  Future<void> _showPendingPostAuthMessage() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final message = prefs.getString('postAuthInfoMessage');
    if (message == null || message.isEmpty || !mounted) return;
    await prefs.remove('postAuthInfoMessage');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncDogProfileToRemote() async {
    try {
      final loadProfile = ref.read(loadDogProfileUseCaseProvider);
      var profile = await loadProfile.call();
      profile ??= _profileFromDogData(widget.dogData);
      if (profile == null) return;
      final repository = ref.read(dogSupabaseRepositoryProvider);
      profile = await repository.resolvePendingDiagnosisFiles(profile);
      await ref.read(saveDogProfileUseCaseProvider).call(profile);
      final id = await repository.upsertDog(profile);
      final syncedProfile = profile.copyWith(id: id ?? profile.id);
      await ref.read(saveDogProfileUseCaseProvider).call(syncedProfile);
      await _syncProfileRiskResultToRemote(syncedProfile);
    } catch (_) {
      // Non-blocking sync
    }
  }

  Future<void> _syncProfileRiskResultToRemote(DogProfile profile) async {
    final dogId = profile.id?.trim();
    final riskLevel = profile.riskLevel?.trim();
    final riskScore = profile.riskScore;
    if (dogId == null ||
        dogId.isEmpty ||
        riskLevel == null ||
        riskLevel.isEmpty) {
      return;
    }
    if (riskScore == null) return;

    final parsedRiskLevel = RiskLevel.values.where((e) => e.name == riskLevel);
    if (parsedRiskLevel.isEmpty) return;

    final signature = '${dogId}_${riskLevel}_$riskScore';
    final prefs = ref.read(sharedPreferencesProvider);
    final alreadySynced = prefs.getString('lastResultSyncedSignature');
    if (alreadySynced == signature) return;

    await ref
        .read(quizRemoteDataSourceProvider)
        .saveResult(
          result: QuizResult(
            riskLevel: parsedRiskLevel.first,
            score: riskScore,
          ),
          dogId: dogId,
        );
    await prefs.setString('lastResultSyncedSignature', signature);
  }

  DogProfile? _profileFromDogData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final name = (data['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final breedName =
        (data['breed'] as String?)?.trim() ??
        (data['breedName'] as String?)?.trim();

    return DogProfile(
      id: data['id'] as String?,
      name: name,
      ageYears:
          (data['age'] as num?)?.toDouble() ??
          (data['ageYears'] as num?)?.toDouble(),
      weightKg:
          (data['weight'] as num?)?.toDouble() ??
          (data['weightKg'] as num?)?.toDouble(),
      breedId: (data['breedId'] as String?)?.trim(),
      breedName: breedName,
      breedImageUrl:
          (data['imagePath'] as String?) ?? (data['breedImageUrl'] as String?),
      riskLevel: (data['riskLevel'] as String?)?.trim(),
      riskScore: data['riskScore'] as int?,
      diagnosisStatus: _parseDiagnosisStatus(data['diagnosisStatus']),
    );
  }

  ArthrosisDiagnosisStatus? _parseDiagnosisStatus(dynamic rawStatus) {
    final normalized = rawStatus?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final status in ArthrosisDiagnosisStatus.values) {
      if (status.name == normalized) return status;
    }
    return null;
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
                    context.l10n.text(
                      'Dove stai bene tu, può stare bene anche il tuo cane',
                    ),
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
                        Image.asset(
                          'assets/ArtrosiCane-Logo.png',
                          width: context.scaled(140),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Lottie.asset(
                          'assets/paw.json',
                          width: context.scaled(170),
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
