import 'dart:typed_data';

import 'package:artrosi_cane/core/providers/preferences_data_source_provider.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/widgets/app_card.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/core/widgets/non_medical_disclaimer.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/dog_supabase_repository.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/dog_profile_screen.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:artrosi_cane/features/quiz/data/models/diagnosis_priority_result_model.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/features/quiz/domain/services/diagnosis_priority_engine.dart';
import 'package:artrosi_cane/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizFlowScreen extends ConsumerStatefulWidget {
  const QuizFlowScreen({
    super.key,
    this.skipIntro = false,
    this.startFromDiagnosis = false,
    this.dogData,
  });

  final bool skipIntro;
  final bool startFromDiagnosis;
  final Map<String, dynamic>? dogData;

  @override
  ConsumerState<QuizFlowScreen> createState() => _QuizFlowScreenState();
}

class _QuizFlowScreenState extends ConsumerState<QuizFlowScreen> {
  static const int _confirmedDiagnosisQuestionCount = 7;

  late final PageController _pageController = PageController(
    initialPage: widget.skipIntro ? 0 : 0,
  );
  final DiagnosisPriorityEngine _diagnosisPriorityEngine =
      const DiagnosisPriorityEngine();
  int _currentPage = 0;
  DogProfile? _profileDraft;
  DogProfile? _latestProfile;
  ArthrosisDiagnosisStatus? _diagnosisStatus;
  DateTime? _diagnosisAnsweredAt;
  bool _shouldAskDiagnosis = true;
  String? _diagnosisDate;
  String? _diagnosisVet;
  List<String> _diagnosisFiles = <String>[];
  String? _diagnosisCareNotes;
  String? _dogId;
  String? _dogName;
  String? _dogBreed;
  String? _dogImage;
  double? _dogAge;
  double? _dogWeight;
  final Set<DiagnosisJoint> _diagnosisJoints = <DiagnosisJoint>{};
  DiagnosisMobility? _diagnosisMobility;
  DiagnosisRigidityFrequency? _diagnosisRigidityFrequency;
  DiagnosisRecovery? _diagnosisRecovery;
  bool? _diagnosisHomeRiskFactors;
  DiagnosisWeightTrend? _diagnosisWeightTrend;
  DiagnosisMovementRhythm? _diagnosisMovementRhythm;
  bool _submittingDiagnosisFlow = false;
  bool _submittingStandardFlow = false;
  bool _dogProfileValid = false;
  bool _showDogProfileValidationErrors = false;

  bool get _isConfirmedDiagnosisFlow =>
      _showsDiagnosisGate &&
      !_shouldAskDiagnosis &&
      _diagnosisStatus == ArthrosisDiagnosisStatus.confirmed;

  bool get _showsDogProfileStep =>
      !widget.skipIntro && !widget.startFromDiagnosis;

  bool get _showsDiagnosisGate =>
      (!widget.skipIntro && !widget.startFromDiagnosis) ||
      widget.startFromDiagnosis;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizControllerProvider.notifier).reset();
    });
    if (widget.dogData != null) {
      final data = widget.dogData!;
      _dogId = data['id'] as String?;
      _dogName = data['name'] as String?;
      _dogBreed = data['breed'] as String?;
      _dogBreed = _dogBreed ?? data['breedName'] as String?;
      _dogBreed ??= data['breed_label'] as String?;
      _dogImage = data['imagePath'] as String?;
      _dogImage ??= data['breedImageUrl'] as String?;
      _dogAge = (data['age'] as num?)?.toDouble();
      _dogWeight = (data['weight'] as num?)?.toDouble();
      final seedProfile = _profileFromDogData(data);
      if (seedProfile != null) {
        _profileDraft = seedProfile;
        _latestProfile = seedProfile;
        _dogProfileValid = _isDogProfileComplete(seedProfile);
      }
    }
    if (_showsDiagnosisGate && !widget.startFromDiagnosis) {
      _bootstrapDiagnosisState();
    }
  }

  DogProfile? _profileFromDogData(Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim();
    final breedId = (data['breedId'] as String?)?.trim();
    final breedName =
        (data['breed'] as String?)?.trim() ??
        (data['breedName'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    return DogProfile(
      id: data['id'] as String?,
      name: name,
      ageYears: (data['age'] as num?)?.toDouble(),
      weightKg: (data['weight'] as num?)?.toDouble(),
      breedId: breedId,
      breedName: breedName,
      breedImageUrl: data['imagePath'] as String?,
    );
  }

  Future<void> _bootstrapDiagnosisState() async {
    try {
      final saved = await ref.read(loadDogProfileUseCaseProvider).call();
      if (!mounted || saved == null) return;
      final isLegacyUnknown =
          saved.diagnosisStatus == ArthrosisDiagnosisStatus.unknown;
      final restoredStatus = isLegacyUnknown ? null : saved.diagnosisStatus;
      final restoredAnsweredAt = isLegacyUnknown
          ? null
          : saved.diagnosisAnsweredAt;
      final restoredDate = restoredStatus == ArthrosisDiagnosisStatus.confirmed
          ? saved.diagnosisDate
          : null;
      final restoredVet = restoredStatus == ArthrosisDiagnosisStatus.confirmed
          ? saved.diagnosisVet
          : null;
      final restoredFiles = restoredStatus == ArthrosisDiagnosisStatus.confirmed
          ? saved.diagnosisFiles
          : <String>[];
      final restoredCareNotes =
          restoredStatus == ArthrosisDiagnosisStatus.confirmed
          ? saved.diagnosisCareNotes
          : null;
      setState(() {
        _diagnosisStatus = restoredStatus;
        _diagnosisAnsweredAt = restoredAnsweredAt;
        _diagnosisDate = restoredDate;
        _diagnosisVet = restoredVet;
        _diagnosisFiles = restoredFiles;
        _diagnosisCareNotes = restoredCareNotes;
        _shouldAskDiagnosis =
            restoredAnsweredAt == null || restoredStatus == null;
      });
      _syncProfile();
    } catch (_) {
      // Ignore stale local data and keep default onboarding flow.
    }
  }

  void _onProfileChanged(DogProfile profile) {
    _dogProfileValid = _isDogProfileComplete(profile);
    if (_dogProfileValid && _showDogProfileValidationErrors) {
      _showDogProfileValidationErrors = false;
    }
    _profileDraft = profile;
    _syncProfile();
    ref.read(saveDogProfileUseCaseProvider).call(_latestProfile!);
  }

  bool _isDogProfileComplete(DogProfile profile) {
    return (profile.name ?? '').trim().isNotEmpty &&
        (profile.breedId ?? '').trim().isNotEmpty;
  }

  Future<void> _persistDogProfileRemote() async {
    if (_latestProfile == null) return;
    await ref.read(saveDogProfileUseCaseProvider).call(_latestProfile!);

    try {
      final repository = ref.read(dogSupabaseRepositoryProvider);
      final profileForSync = await repository.resolvePendingDiagnosisFiles(
        _latestProfile!,
      );
      _latestProfile = profileForSync;
      await ref.read(saveDogProfileUseCaseProvider).call(profileForSync);

      if (widget.startFromDiagnosis &&
          _dogId != null &&
          _dogId!.trim().isNotEmpty) {
        await repository.updateDiagnosisForDog(
          dogId: _dogId!,
          diagnosisStatus: profileForSync.diagnosisStatus,
          diagnosisAnsweredAt: profileForSync.diagnosisAnsweredAt,
          diagnosisDate: profileForSync.diagnosisDate,
          diagnosisVet: profileForSync.diagnosisVet,
          diagnosisFiles: profileForSync.diagnosisFiles,
          diagnosisCareNotes: profileForSync.diagnosisCareNotes,
        );
        await ref.read(saveDogProfileUseCaseProvider).call(profileForSync);
        return;
      }
      final id = await repository.upsertDog(profileForSync);
      if (id != null) {
        _dogId = id;
        _latestProfile = profileForSync.copyWith(id: id);
        await ref.read(saveDogProfileUseCaseProvider).call(_latestProfile!);
      }
    } catch (_) {
      // Ignore remote errors for now
    }
  }

  Future<String?> _uploadDiagnosisFile(PlatformFile file) async {
    final bytes = await _readPlatformFileBytes(file);
    if (bytes == null || bytes.isEmpty) {
      throw Exception('File non leggibile');
    }
    return ref
        .read(dogSupabaseRepositoryProvider)
        .uploadDiagnosisFile(bytes: bytes, originalFileName: file.name);
  }

  Future<Uint8List?> _readPlatformFileBytes(PlatformFile file) async {
    final directBytes = file.bytes;
    if (directBytes != null && directBytes.isNotEmpty) return directBytes;

    final readStream = file.readStream;
    if (readStream != null) {
      final chunks = <int>[];
      await for (final chunk in readStream) {
        chunks.addAll(chunk);
      }
      if (chunks.isNotEmpty) return Uint8List.fromList(chunks);
    }

    return null;
  }

  Future<void> _deleteDiagnosisFile(String objectPath) async {
    await ref
        .read(dogSupabaseRepositoryProvider)
        .deleteDiagnosisFile(objectPath);
  }

  Future<void> _goToQuestions() async {
    if (!mounted) return;
    setState(() {
      _shouldAskDiagnosis = false;
    });

    await _persistDogProfileRemote();
    await _trackOnboardingEvent(
      'diagnosis_gate_confirmed',
      payload: {
        'diagnosisStatus': _diagnosisStatus?.name,
        'hasDiagnosisDate':
            _diagnosisDate != null && _diagnosisDate!.isNotEmpty,
        'hasDiagnosisVet': _diagnosisVet != null && _diagnosisVet!.isNotEmpty,
        'diagnosisFilesCount': _diagnosisFiles.length,
        'hasDiagnosisCareNotes':
            _diagnosisCareNotes != null && _diagnosisCareNotes!.isNotEmpty,
      },
    );

    if (!mounted) return;
    await _goToNextPage();
  }

  void _resetConfirmedDiagnosisAnswers() {
    _diagnosisJoints.clear();
    _diagnosisMobility = null;
    _diagnosisRigidityFrequency = null;
    _diagnosisRecovery = null;
    _diagnosisHomeRiskFactors = null;
    _diagnosisWeightTrend = null;
    _diagnosisMovementRhythm = null;
  }

  void _updateDiagnosis({
    required ArthrosisDiagnosisStatus diagnosisStatus,
    String? diagnosisDate,
    String? diagnosisVet,
    List<String>? diagnosisFiles,
    String? diagnosisCareNotes,
  }) {
    final previousStatus = _diagnosisStatus;
    _diagnosisStatus = diagnosisStatus;
    _diagnosisAnsweredAt ??= DateTime.now();
    if (diagnosisStatus == ArthrosisDiagnosisStatus.confirmed) {
      _diagnosisDate = diagnosisDate;
      _diagnosisVet = diagnosisVet;
      _diagnosisFiles = diagnosisFiles ?? <String>[];
      _diagnosisCareNotes = diagnosisCareNotes;
    } else {
      _diagnosisDate = null;
      _diagnosisVet = null;
      _diagnosisFiles = <String>[];
      _diagnosisCareNotes = null;
      _resetConfirmedDiagnosisAnswers();
    }
    if (previousStatus != diagnosisStatus &&
        diagnosisStatus == ArthrosisDiagnosisStatus.confirmed) {
      _resetConfirmedDiagnosisAnswers();
    }
    _syncProfile();
  }

  void _syncProfile() {
    final base = _profileDraft;
    _latestProfile = DogProfile(
      name: base?.name,
      ageYears: base?.ageYears,
      weightKg: base?.weightKg,
      breedId: base?.breedId,
      breedName: base?.breedName,
      diagnosisStatus: _diagnosisStatus,
      diagnosisAnsweredAt: _diagnosisAnsweredAt,
      diagnosisDate: _diagnosisDate,
      diagnosisVet: _diagnosisVet,
      diagnosisFiles: _diagnosisFiles,
      diagnosisCareNotes: _diagnosisCareNotes,
      ageGroup: base?.ageGroup ?? AgeGroup.adulto,
      size: base?.size ?? DogSize.media,
    );
  }

  Future<void> _onAnswerSelected(String questionId, int answerValue) async {
    final controller = ref.read(quizControllerProvider.notifier);
    await controller.selectAnswer(questionId, answerValue);
  }

  Future<void> _goToPreviousPage() async {
    if (!mounted || _currentPage <= 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToNextStandardQuestionFromPage(int pageIndex) async {
    if (_submittingStandardFlow) return;
    final state = ref.read(quizControllerProvider);
    final isLastPage = pageIndex == _totalPages(state) - 1;
    if (isLastPage) {
      await _submitStandardFlow();
      return;
    }
    if (!mounted) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitStandardFlow() async {
    if (_submittingStandardFlow) return;
    setState(() => _submittingStandardFlow = true);
    try {
      final controller = ref.read(quizControllerProvider.notifier);
      await controller.submitQuiz(scoreAdjustment: _diagnosisScoreAdjustment());
      final result = ref.read(quizControllerProvider).result;
      if (result == null || !mounted) return;

      await _trackOnboardingEvent(
        'quiz_standard_completed',
        payload: {
          'diagnosisStatus': _diagnosisStatus?.name,
          'riskLevel': result.riskLevel.name,
          'score': result.score,
        },
      );
      await _persistResultRemote(result);
      if (_isUserAuthenticated()) {
        await _navigateBackToDogDashboard(result);
      } else {
        await ref.read(completeOnboardingUseCaseProvider).call();
        if (!mounted) return;
        context.go(
          '/quiz/result',
          extra: {
            'result': result,
            'dog': _buildDogNavigationData(
              arthrosisGrade: _riskLabel(result.riskLevel),
            ),
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingStandardFlow = false);
      }
    }
  }

  Future<void> _goToNextConfirmedDiagnosisStep(int step) async {
    if (_submittingDiagnosisFlow || !_isConfirmedDiagnosisStepAnswered(step)) {
      return;
    }
    final state = ref.read(quizControllerProvider);
    final totalPages = _totalPages(state);
    final isLastStep = step == _confirmedDiagnosisQuestionCount - 1;
    if (isLastStep || _currentPage == totalPages - 1) {
      await _submitConfirmedDiagnosisFlow();
      return;
    }
    if (!mounted) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToPreviousConfirmedDiagnosisStep() async {
    await _goToPreviousPage();
  }

  Future<void> _goToNextPage() async {
    if (!mounted) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int _introPages() {
    if (_showsDogProfileStep) return 2;
    if (_showsDiagnosisGate) return 1;
    return 0;
  }

  int _questionStartIndex() => _introPages();

  int _contentPageCount(QuizState state) {
    if (_isConfirmedDiagnosisFlow) return _confirmedDiagnosisQuestionCount;
    return state.questions.length;
  }

  int _totalPages(QuizState state) => _introPages() + _contentPageCount(state);

  bool _isConfirmedDiagnosisStepAnswered(int step) {
    switch (step) {
      case 0:
        return _diagnosisJoints.isNotEmpty;
      case 1:
        return _diagnosisMobility != null;
      case 2:
        return _diagnosisRigidityFrequency != null;
      case 3:
        return _diagnosisRecovery != null;
      case 4:
        return _diagnosisHomeRiskFactors != null;
      case 5:
        return _diagnosisWeightTrend != null;
      case 6:
        return _diagnosisMovementRhythm != null;
      default:
        return false;
    }
  }

  Future<void> _persistResultRemote(
    QuizResult result, {
    List<QuizAnswer>? answers,
  }) async {
    final payloadAnswers = answers ?? ref.read(quizControllerProvider).answers;
    final dogId = _dogId;
    await ref
        .read(quizRemoteDataSourceProvider)
        .saveResult(result: result, dogId: dogId, answers: payloadAnswers);
    if (dogId != null && dogId.isNotEmpty) {
      final signature = '${dogId}_${result.riskLevel.name}_${result.score}';
      await ref
          .read(sharedPreferencesProvider)
          .setString('lastResultSyncedSignature', signature);
    }
  }

  Future<void> _trackOnboardingEvent(
    String eventName, {
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      await ref
          .read(preferencesDataSourceProvider)
          .appendOnboardingEvent(eventName: eventName, payload: payload);
    } catch (_) {
      // Ignore local telemetry failures.
    }

    await ref
        .read(quizRemoteDataSourceProvider)
        .saveOnboardingEvent(eventName: eventName, payload: payload);
  }

  QuizResult _toLegacyQuizResult(DiagnosisPriorityResult result) {
    final areas = PriorityArea.values.map(result.area).toList();
    final hasHigh = areas.any((item) => item.level == PriorityLevel.alta);
    final hasMedium = areas.any((item) => item.level == PriorityLevel.media);
    final riskLevel = hasHigh
        ? RiskLevel.alto
        : hasMedium
        ? RiskLevel.medio
        : RiskLevel.basso;
    return QuizResult(riskLevel: riskLevel, score: result.totalScore);
  }

  int _encodeJointsMask(Set<DiagnosisJoint> joints) {
    var mask = 0;
    for (final joint in joints) {
      mask |= (1 << joint.index);
    }
    return mask;
  }

  List<QuizAnswer> _buildConfirmedDiagnosisAnswers() {
    return [
      QuizAnswer(
        questionId: 'dq_joints_mask',
        value: _encodeJointsMask(_diagnosisJoints),
      ),
      QuizAnswer(
        questionId: 'dq_mobility',
        value: _diagnosisMobility?.index ?? 0,
      ),
      QuizAnswer(
        questionId: 'dq_rigidity_frequency',
        value: _diagnosisRigidityFrequency?.index ?? 0,
      ),
      QuizAnswer(
        questionId: 'dq_recovery',
        value: _diagnosisRecovery?.index ?? 0,
      ),
      QuizAnswer(
        questionId: 'dq_home_risk_factors',
        value: (_diagnosisHomeRiskFactors ?? false) ? 1 : 0,
      ),
      QuizAnswer(
        questionId: 'dq_weight_trend',
        value: _diagnosisWeightTrend?.index ?? 0,
      ),
      QuizAnswer(
        questionId: 'dq_movement_rhythm',
        value: _diagnosisMovementRhythm?.index ?? 0,
      ),
    ];
  }

  Future<void> _submitConfirmedDiagnosisFlow() async {
    if (_submittingDiagnosisFlow) return;
    if (_diagnosisMobility == null ||
        _diagnosisRigidityFrequency == null ||
        _diagnosisRecovery == null ||
        _diagnosisHomeRiskFactors == null ||
        _diagnosisWeightTrend == null ||
        _diagnosisMovementRhythm == null ||
        _diagnosisJoints.isEmpty) {
      return;
    }

    setState(() => _submittingDiagnosisFlow = true);
    try {
      final input = DiagnosisPriorityInput(
        joints: {..._diagnosisJoints},
        mobility: _diagnosisMobility!,
        rigidityFrequency: _diagnosisRigidityFrequency!,
        recovery: _diagnosisRecovery!,
        hasHomeRiskFactors: _diagnosisHomeRiskFactors!,
        weightTrend: _diagnosisWeightTrend!,
        movementRhythm: _diagnosisMovementRhythm!,
      );

      final priorityResult = _diagnosisPriorityEngine.evaluate(input);
      final legacyResult = _toLegacyQuizResult(priorityResult);
      await _trackOnboardingEvent(
        'diagnosis_priority_completed',
        payload: {
          'totalScore': priorityResult.totalScore,
          'shownHighAreas': priorityResult.shownHighAreas
              .map((a) => a.name)
              .toList(),
          'compressedFromHigh': priorityResult.compressedFromHigh
              .map((a) => a.name)
              .toList(),
        },
      );
      await ref
          .read(preferencesDataSourceProvider)
          .saveDiagnosisPriorityResult(
            DiagnosisPriorityResultModel.fromEntity(priorityResult),
          );
      await _persistResultRemote(
        legacyResult,
        answers: _buildConfirmedDiagnosisAnswers(),
      );
      if (_isUserAuthenticated()) {
        await _navigateBackToDogDashboard(legacyResult);
      } else {
        await ref.read(completeOnboardingUseCaseProvider).call();
        if (!mounted) return;
        context.go(
          '/quiz/diagnosis-result',
          extra: {
            'result': priorityResult,
            'dog': _buildDogNavigationData(
              arthrosisGrade: _riskLabel(legacyResult.riskLevel),
            ),
          },
        );
      }
    } finally {
      if (mounted) setState(() => _submittingDiagnosisFlow = false);
    }
  }

  bool _isUserAuthenticated() {
    return Supabase.instance.client.auth.currentUser != null;
  }

  Future<void> _navigateBackToDogDashboard(QuizResult result) async {
    // Refresh dog list so the updated risk is pulled on home.
    ref.invalidate(userDogsProvider);

    if (mounted) {
      context.go(
        '/dog-dashboard',
        extra: _buildDogNavigationData(
          arthrosisGrade: _riskLabel(result.riskLevel),
        ),
      );
    }
  }

  Map<String, dynamic> _buildDogNavigationData({String? arthrosisGrade}) {
    return {
      'id': _dogId,
      'name': _dogName ?? _latestProfile?.name ?? 'Il tuo cane',
      'breed': _dogBreed ?? _latestProfile?.breedName ?? 'Razza non indicata',
      'breedId': _latestProfile?.breedId,
      'imagePath':
          _dogImage ?? _latestProfile?.breedImageUrl ?? 'assets/first-dog.png',
      'age': _dogAge ?? _latestProfile?.ageYears,
      'weight': _dogWeight ?? _latestProfile?.weightKg,
      'arthrosisGrade': arthrosisGrade ?? 'Non rilevato',
    };
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.basso:
        return 'Nessun Livello di artrosi';
      case RiskLevel.medio:
        return 'Artrosi Lieve';
      case RiskLevel.alto:
        return 'Artrosi Grave';
    }
  }

  int _diagnosisScoreAdjustment() {
    switch (_diagnosisStatus) {
      case ArthrosisDiagnosisStatus.confirmed:
        return 1;
      case ArthrosisDiagnosisStatus.unknown:
        return 0;
      case ArthrosisDiagnosisStatus.notDiagnosed:
      case null:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    if (state.isLoading) {
      return const AppScaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    final questionStartIndex = _questionStartIndex();
    final totalPages = _totalPages(state);

    return AppScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Remove default back button
      ),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final page = _pageController.hasClients
                  ? (_pageController.page ?? 0.0)
                  : 0.0;
              final progress = (page + 1) / totalPages;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.borderSoft,
                  color: AppColors.ctaApricot, // Changed to orange
                  minHeight: 6,
                ),
              );
            },
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalPages,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                if (_isConfirmedDiagnosisFlow) return;
                if (_showsDiagnosisGate && index >= questionStartIndex) {
                  ref
                      .read(quizControllerProvider.notifier)
                      .setIndex(index - questionStartIndex);
                } else if (widget.skipIntro) {
                  ref.read(quizControllerProvider.notifier).setIndex(index);
                }
              },
              itemBuilder: (context, index) {
                final diagnosisPageIndex = _showsDogProfileStep ? 1 : 0;
                if (_showsDogProfileStep && index == 0) {
                  return DogProfilePage(
                    onProfileChanged: _onProfileChanged,
                    showValidationErrors: _showDogProfileValidationErrors,
                  );
                }
                if (_showsDiagnosisGate && index == diagnosisPageIndex) {
                  return _DiagnosisStep(
                    initialStatus: _diagnosisStatus,
                    initialDate: _diagnosisDate,
                    initialVet: _diagnosisVet,
                    initialFiles: _diagnosisFiles,
                    initialCareNotes: _diagnosisCareNotes,
                    onUploadFile: _uploadDiagnosisFile,
                    onDeleteFile: _deleteDiagnosisFile,
                    onGoBack: () async {
                      if (!mounted) return;
                      if (_showsDogProfileStep && _currentPage > 0) {
                        await _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        return;
                      }
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    onChange: (status, date, vet, files, careNotes) {
                      setState(() {
                        _updateDiagnosis(
                          diagnosisStatus: status,
                          diagnosisDate: date,
                          diagnosisVet: vet,
                          diagnosisFiles: files,
                          diagnosisCareNotes: careNotes,
                        );
                      });
                    },
                    onProceedTest: _goToQuestions,
                  );
                }

                if (_isConfirmedDiagnosisFlow) {
                  final diagnosisStep = index - questionStartIndex;
                  return _buildConfirmedDiagnosisQuestion(diagnosisStep);
                }

                final questionIndex = widget.skipIntro
                    ? index
                    : index - questionStartIndex;
                final question = state.questions[questionIndex];

                int? selectedAnswer;
                for (final answer in state.answers) {
                  if (answer.questionId == question.id) {
                    selectedAnswer = answer.value;
                    break;
                  }
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.body('Domanda ${questionIndex + 1}'),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    question.text,
                                    style: AppTypography.h1.copyWith(
                                      fontSize: 22,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ...question.options.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _OptionTile(
                                  label: entry.value,
                                  isSelected: selectedAnswer == entry.key,
                                  onTap: () =>
                                      _onAnswerSelected(question.id, entry.key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _PinnedQuestionActions(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: index > 0 && !_submittingStandardFlow
                                  ? _goToPreviousPage
                                  : null,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Indietro'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                  color: AppColors.borderSoft,
                                ),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  selectedAnswer != null &&
                                      !_submittingStandardFlow
                                  ? () =>
                                        _goToNextStandardQuestionFromPage(index)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ctaApricot,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child:
                                  _submittingStandardFlow &&
                                      index == totalPages - 1
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      index == totalPages - 1
                                          ? 'Vedi risultato'
                                          : 'Continua',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: (_showsDogProfileStep && _currentPage == 0)
          ? _QuizBottomBar(
              currentPage: _currentPage,
              totalPages: totalPages,
              onBack: () {
                _goToPreviousPage();
              },
              onNext: () async {
                if (_currentPage == 0) {
                  if (!_dogProfileValid) {
                    setState(() => _showDogProfileValidationErrors = true);
                    return;
                  }
                  await _persistDogProfileRemote();
                }
                await _goToNextPage();
              },
              onSubmit: () {},
              hideOnDiagnosisStep: false,
            )
          : const SizedBox.shrink(),
    );
  }

  void _selectDiagnosisOption({required VoidCallback update}) {
    if (_submittingDiagnosisFlow) return;
    setState(update);
  }

  Widget _buildConfirmedDiagnosisQuestion(int step) {
    switch (step) {
      case 0:
        return _buildDiagnosisJointsStep(step);
      case 1:
        return _buildDiagnosisSingleChoiceStep(
          step: step,
          question: 'Come descriveresti la mobilita oggi?',
          subtitle: 'Pensando alla giornata tipo.',
          options: [
            (
              label: 'Lieve',
              detail: 'Cammina ma con rigidita leggera.',
              selected: _diagnosisMobility == DiagnosisMobility.lieve,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisMobility = DiagnosisMobility.lieve,
              ),
            ),
            (
              label: 'Moderata',
              detail: 'Rallenta ed evita alcuni movimenti.',
              selected: _diagnosisMobility == DiagnosisMobility.moderata,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisMobility = DiagnosisMobility.moderata,
              ),
            ),
            (
              label: 'Avanzata',
              detail: 'Difficolta evidente, fatica ad alzarsi.',
              selected: _diagnosisMobility == DiagnosisMobility.avanzata,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisMobility = DiagnosisMobility.avanzata,
              ),
            ),
          ],
        );
      case 2:
        return _buildDiagnosisSingleChoiceStep(
          step: step,
          question:
              'Nell’ultima settimana quante volte hai notato rigidita o zoppia?',
          options: [
            (
              label: 'Mai',
              detail: null,
              selected:
                  _diagnosisRigidityFrequency == DiagnosisRigidityFrequency.mai,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisRigidityFrequency =
                    DiagnosisRigidityFrequency.mai,
              ),
            ),
            (
              label: '1-2 giorni',
              detail: null,
              selected:
                  _diagnosisRigidityFrequency ==
                  DiagnosisRigidityFrequency.unoDue,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisRigidityFrequency =
                    DiagnosisRigidityFrequency.unoDue,
              ),
            ),
            (
              label: '3-4 giorni',
              detail: null,
              selected:
                  _diagnosisRigidityFrequency ==
                  DiagnosisRigidityFrequency.treQuattro,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisRigidityFrequency =
                    DiagnosisRigidityFrequency.treQuattro,
              ),
            ),
            (
              label: '5-7 giorni',
              detail: null,
              selected:
                  _diagnosisRigidityFrequency ==
                  DiagnosisRigidityFrequency.cinqueSette,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisRigidityFrequency =
                    DiagnosisRigidityFrequency.cinqueSette,
              ),
            ),
          ],
        );
      case 3:
        return _buildDiagnosisSingleChoiceStep(
          step: step,
          question: 'Il giorno dopo una passeggiata normale, com’e?',
          subtitle: 'Non considerare escursioni lunghe.',
          options: [
            (
              label: 'Uguale',
              detail: null,
              selected: _diagnosisRecovery == DiagnosisRecovery.uguale,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisRecovery = DiagnosisRecovery.uguale,
              ),
            ),
            (
              label: 'Un po peggio',
              detail: null,
              selected: _diagnosisRecovery == DiagnosisRecovery.unPoPeggio,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisRecovery = DiagnosisRecovery.unPoPeggio,
              ),
            ),
            (
              label: 'Molto peggio',
              detail: null,
              selected: _diagnosisRecovery == DiagnosisRecovery.moltoPeggio,
              onTap: () => _selectDiagnosisOption(
                update: () =>
                    _diagnosisRecovery = DiagnosisRecovery.moltoPeggio,
              ),
            ),
          ],
        );
      case 4:
        return _buildDiagnosisSingleChoiceStep(
          step: step,
          question: 'In casa sono presenti 2 o piu fattori di rischio?',
          subtitle: 'Scale, pavimenti scivolosi, salti o auto difficile.',
          options: [
            (
              label: 'Si',
              detail: null,
              selected: _diagnosisHomeRiskFactors == true,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisHomeRiskFactors = true,
              ),
            ),
            (
              label: 'No',
              detail: null,
              selected: _diagnosisHomeRiskFactors == false,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisHomeRiskFactors = false,
              ),
            ),
          ],
        );
      case 5:
        return _buildDiagnosisSingleChoiceStep(
          step: step,
          question: 'Negli ultimi 3 mesi il peso e...',
          options: [
            (
              label: 'Stabile',
              detail: null,
              selected: _diagnosisWeightTrend == DiagnosisWeightTrend.stabile,
              onTap: () => _selectDiagnosisOption(
                update: () =>
                    _diagnosisWeightTrend = DiagnosisWeightTrend.stabile,
              ),
            ),
            (
              label: 'In aumento',
              detail: null,
              selected: _diagnosisWeightTrend == DiagnosisWeightTrend.inAumento,
              onTap: () => _selectDiagnosisOption(
                update: () =>
                    _diagnosisWeightTrend = DiagnosisWeightTrend.inAumento,
              ),
            ),
            (
              label: 'Non so',
              detail: null,
              selected: _diagnosisWeightTrend == DiagnosisWeightTrend.nonSo,
              onTap: () => _selectDiagnosisOption(
                update: () =>
                    _diagnosisWeightTrend = DiagnosisWeightTrend.nonSo,
              ),
            ),
          ],
        );
      case 6:
        return _buildDiagnosisSingleChoiceStep(
          step: step,
          question: 'Il movimento settimanale e...',
          subtitle: 'La regolarita e piu importante della quantita.',
          options: [
            (
              label: 'Regolare ogni giorno',
              detail: null,
              selected:
                  _diagnosisMovementRhythm ==
                  DiagnosisMovementRhythm.regolareOgniGiorno,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisMovementRhythm =
                    DiagnosisMovementRhythm.regolareOgniGiorno,
              ),
            ),
            (
              label: 'A giorni alterni tanto',
              detail: null,
              selected:
                  _diagnosisMovementRhythm ==
                  DiagnosisMovementRhythm.giorniAlterniTanto,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisMovementRhythm =
                    DiagnosisMovementRhythm.giorniAlterniTanto,
              ),
            ),
            (
              label: 'Irregolare (weekend lunghi)',
              detail: null,
              selected:
                  _diagnosisMovementRhythm ==
                  DiagnosisMovementRhythm.irregolareWeekend,
              onTap: () => _selectDiagnosisOption(
                update: () => _diagnosisMovementRhythm =
                    DiagnosisMovementRhythm.irregolareWeekend,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDiagnosisJointsStep(int step) {
    const jointOptions = <(DiagnosisJoint value, String label)>[
      (DiagnosisJoint.colonna, 'Colonna'),
      (DiagnosisJoint.anca, 'Anca'),
      (DiagnosisJoint.ginocchio, 'Ginocchio'),
      (DiagnosisJoint.gomito, 'Gomito'),
      (DiagnosisJoint.spalla, 'Spalla'),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        'Domanda ${step + 1}/$_confirmedDiagnosisQuestionCount',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Quali articolazioni sono coinvolte?',
                        style: AppTypography.h1.copyWith(
                          fontSize: 22,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText.body(
                        'Seleziona tutte quelle indicate nella diagnosi.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...jointOptions.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _OptionTile(
                      label: option.$2,
                      isSelected: _diagnosisJoints.contains(option.$1),
                      onTap: () {
                        if (_submittingDiagnosisFlow) return;
                        setState(() {
                          if (_diagnosisJoints.contains(option.$1)) {
                            _diagnosisJoints.remove(option.$1);
                          } else {
                            _diagnosisJoints.add(option.$1);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _PinnedQuestionActions(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submittingDiagnosisFlow
                          ? null
                          : _goToPreviousConfirmedDiagnosisStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Indietro'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.borderSoft),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _diagnosisJoints.isEmpty || _submittingDiagnosisFlow
                          ? null
                          : () => _goToNextConfirmedDiagnosisStep(step),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Continua'),
                    ),
                  ),
                ],
              ),
              if (_submittingDiagnosisFlow &&
                  step == _confirmedDiagnosisQuestionCount - 1)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisSingleChoiceStep({
    required int step,
    required String question,
    String? subtitle,
    required List<
      ({String label, String? detail, bool selected, VoidCallback onTap})
    >
    options,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        'Domanda ${step + 1}/$_confirmedDiagnosisQuestionCount',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        question,
                        style: AppTypography.h1.copyWith(
                          fontSize: 22,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppText.body(subtitle),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...options.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _OptionTile(
                      label: entry.detail == null
                          ? entry.label
                          : '${entry.label}\n${entry.detail}',
                      isSelected: entry.selected,
                      onTap: entry.onTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _PinnedQuestionActions(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submittingDiagnosisFlow
                          ? null
                          : _goToPreviousConfirmedDiagnosisStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Indietro'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.borderSoft),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isConfirmedDiagnosisStepAnswered(step) &&
                              !_submittingDiagnosisFlow
                          ? () => _goToNextConfirmedDiagnosisStep(step)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        step == _confirmedDiagnosisQuestionCount - 1
                            ? 'Vedi risultato'
                            : 'Continua',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_submittingDiagnosisFlow &&
                  step == _confirmedDiagnosisQuestionCount - 1)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinnedQuestionActions extends StatelessWidget {
  const _PinnedQuestionActions({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ctaApricot
              : AppColors.card, // Orange when selected
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.ctaApricot : AppColors.borderSoft,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? Colors.white
                  : AppColors.borderSoft, // White icon when selected
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.text, // White text when selected
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosisStep extends StatelessWidget {
  const _DiagnosisStep({
    required this.initialStatus,
    this.initialDate,
    this.initialVet,
    this.initialFiles = const <String>[],
    this.initialCareNotes,
    required this.onUploadFile,
    required this.onDeleteFile,
    required this.onGoBack,
    required this.onChange,
    required this.onProceedTest,
  });

  final ArthrosisDiagnosisStatus? initialStatus;
  final String? initialDate;
  final String? initialVet;
  final List<String> initialFiles;
  final String? initialCareNotes;
  final Future<String?> Function(PlatformFile file) onUploadFile;
  final Future<void> Function(String objectPath) onDeleteFile;
  final Future<void> Function() onGoBack;
  final void Function(
    ArthrosisDiagnosisStatus status,
    String? date,
    String? vet,
    List<String>? files,
    String? careNotes,
  )
  onChange;
  final VoidCallback onProceedTest;

  @override
  Widget build(BuildContext context) {
    return _DiagnosisStepContent(
      initialStatus: initialStatus,
      initialDate: initialDate,
      initialVet: initialVet,
      initialFiles: initialFiles,
      initialCareNotes: initialCareNotes,
      onUploadFile: onUploadFile,
      onDeleteFile: onDeleteFile,
      onGoBack: onGoBack,
      onChange: onChange,
      onProceedTest: onProceedTest,
    );
  }
}

class _DiagnosisStepContent extends StatefulWidget {
  const _DiagnosisStepContent({
    required this.initialStatus,
    this.initialDate,
    this.initialVet,
    this.initialFiles = const <String>[],
    this.initialCareNotes,
    required this.onUploadFile,
    required this.onDeleteFile,
    required this.onGoBack,
    required this.onChange,
    required this.onProceedTest,
  });

  final ArthrosisDiagnosisStatus? initialStatus;
  final String? initialDate;
  final String? initialVet;
  final List<String> initialFiles;
  final String? initialCareNotes;
  final Future<String?> Function(PlatformFile file) onUploadFile;
  final Future<void> Function(String objectPath) onDeleteFile;
  final Future<void> Function() onGoBack;
  final void Function(
    ArthrosisDiagnosisStatus status,
    String? date,
    String? vet,
    List<String>? files,
    String? careNotes,
  )
  onChange;
  final VoidCallback onProceedTest;

  @override
  State<_DiagnosisStepContent> createState() => _DiagnosisStepContentState();
}

class _DiagnosisStepContentState extends State<_DiagnosisStepContent> {
  ArthrosisDiagnosisStatus? _status;
  late TextEditingController _dateCtrl;
  late TextEditingController _vetCtrl;
  late TextEditingController _careNotesCtrl;
  List<String> _diagnosisFiles = <String>[];
  bool _uploadingDiagnosisFiles = false;
  bool _attemptedSubmit = false;

  bool get _isConfirmedDiagnosis =>
      _status == ArthrosisDiagnosisStatus.confirmed;

  bool get _missingStatus => _status == null;

  bool get _missingDate =>
      _isConfirmedDiagnosis && _dateCtrl.text.trim().isEmpty;

  bool get _isFormValid {
    if (_status == null) return false;
    if (!_isConfirmedDiagnosis) return true;
    return !_missingDate;
  }

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _dateCtrl = TextEditingController(text: widget.initialDate ?? '');
    _vetCtrl = TextEditingController(text: widget.initialVet ?? '');
    _careNotesCtrl = TextEditingController(text: widget.initialCareNotes ?? '');
    _diagnosisFiles = List<String>.from(widget.initialFiles);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _vetCtrl.dispose();
    _careNotesCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    if (_status == null) return;
    final hasConfirmedDiagnosis = _status == ArthrosisDiagnosisStatus.confirmed;
    final notes = _careNotesCtrl.text.trim();
    widget.onChange(
      _status!,
      hasConfirmedDiagnosis && _dateCtrl.text.isNotEmpty
          ? _dateCtrl.text.trim()
          : null,
      hasConfirmedDiagnosis && _vetCtrl.text.isNotEmpty
          ? _vetCtrl.text.trim()
          : null,
      hasConfirmedDiagnosis && _diagnosisFiles.isNotEmpty
          ? List<String>.from(_diagnosisFiles)
          : null,
      hasConfirmedDiagnosis && notes.isNotEmpty ? notes : null,
    );
  }

  Future<void> _pickDiagnosisFiles() async {
    if (_uploadingDiagnosisFiles) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploadingDiagnosisFiles = true);
      final uploaded = <String>{};
      var failed = 0;
      for (final file in result.files) {
        try {
          final uploadedPath = await widget.onUploadFile(file);
          if (uploadedPath == null || uploadedPath.trim().isEmpty) {
            failed += 1;
            continue;
          }
          uploaded.add(uploadedPath.trim());
        } catch (_) {
          failed += 1;
        }
      }
      setState(() {
        _diagnosisFiles = {..._diagnosisFiles, ...uploaded}.toList();
        _uploadingDiagnosisFiles = false;
      });
      _notifyChange();
      if (!mounted) return;
      if (failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Caricati ${uploaded.length} file. Non caricati: $failed.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploadingDiagnosisFiles = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non sono riuscito a caricare i file su cloud.'),
        ),
      );
    }
  }

  Future<void> _removeDiagnosisFile(String fileRef) async {
    setState(() {
      _diagnosisFiles = _diagnosisFiles
          .where((candidate) => candidate != fileRef)
          .toList();
    });
    _notifyChange();
    try {
      await widget.onDeleteFile(fileRef);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File rimosso dalla lista, ma non dal cloud.'),
        ),
      );
    }
  }

  String _fileLabel(String fileRef) {
    final normalized = fileRef.replaceAll('\\', '/');
    final chunks = normalized.split('/');
    if (chunks.isEmpty) return fileRef;
    final fileName = chunks.last;
    final underscoreIndex = fileName.indexOf('_');
    if (underscoreIndex > 0 && fileName.length > underscoreIndex + 1) {
      return fileName.substring(underscoreIndex + 1);
    }
    return fileName;
  }

  InputDecoration _diagnosisInputDecoration({
    required String hintText,
    required bool hasError,
    Widget? suffixIcon,
  }) {
    final borderColor = hasError ? Colors.red.shade400 : AppColors.borderSoft;
    return InputDecoration(
      hintText: hintText,
      errorText: hasError ? 'Campo obbligatorio' : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? Colors.red.shade500 : AppColors.primaryBlue,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade500, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.4),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }

  DateTime? _parseDiagnosisDate(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDiagnosisDate() async {
    final now = DateTime.now();
    final initial = _parseDiagnosisDate(_dateCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Data diagnosi',
      locale: const Locale('it'),
    );
    if (picked == null) return;
    setState(() {
      _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.h1('Diagnosi', color: AppColors.primaryBlue),
                const SizedBox(height: AppSpacing.md),
                AppText.body(
                  'Il tuo cane ha una diagnosi di artrosi confermata dal veterinario?',
                  color: AppColors.text,
                  bold: true,
                ),
                const SizedBox(height: AppSpacing.md),
                _ChoiceCard(
                  icon: Icons.verified_rounded,
                  label: 'Ho già una diagnosi',
                  subtitle: 'Posso allegare referti e aggiungere note utili.',
                  selected: _status == ArthrosisDiagnosisStatus.confirmed,
                  hasError: _attemptedSubmit && _missingStatus,
                  onTap: () {
                    setState(() {
                      _status = ArthrosisDiagnosisStatus.confirmed;
                      _attemptedSubmit = false;
                    });
                    _notifyChange();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _ChoiceCard(
                  icon: Icons.search_rounded,
                  label: 'Non ho una diagnosi',
                  subtitle: 'Continuo con il test di screening.',
                  selected: _status == ArthrosisDiagnosisStatus.notDiagnosed,
                  hasError: _attemptedSubmit && _missingStatus,
                  onTap: () {
                    setState(() {
                      _status = ArthrosisDiagnosisStatus.notDiagnosed;
                      _attemptedSubmit = false;
                    });
                    _notifyChange();
                  },
                ),
                if (_status == ArthrosisDiagnosisStatus.notDiagnosed) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.ctaApricot.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.ctaApricot,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppText.body(
                              'Importante',
                              bold: true,
                              color: AppColors.ctaApricot,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const NonMedicalDisclaimer(compact: true),
                      ],
                    ),
                  ),
                ],
                if (_status == ArthrosisDiagnosisStatus.confirmed) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _dateCtrl,
                    readOnly: true,
                    decoration: _diagnosisInputDecoration(
                      hintText: 'Quando è stata fatta la diagnosi?',
                      hasError: _attemptedSubmit && _missingDate,
                      suffixIcon: IconButton(
                        onPressed: _selectDiagnosisDate,
                        icon: const Icon(Icons.calendar_today_rounded),
                        color: AppColors.primaryBlue,
                        tooltip: 'Seleziona data',
                      ),
                    ),
                    onTap: _selectDiagnosisDate,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _vetCtrl,
                    decoration: _diagnosisInputDecoration(
                      hintText: 'Da che studio veterinario?',
                      hasError: false,
                    ),
                    onChanged: (_) => _notifyChange(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppText.body('Allega referti', bold: true),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText.body(
                          'Formati suggeriti: .pdf .png .jpeg .jpg (puoi allegare anche altri tipi).',
                          color: AppColors.text.withValues(alpha: 0.72),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _uploadingDiagnosisFiles
                              ? null
                              : _pickDiagnosisFiles,
                          icon: Icon(
                            _uploadingDiagnosisFiles
                                ? Icons.cloud_upload_rounded
                                : Icons.attach_file_rounded,
                          ),
                          label: Text(
                            _uploadingDiagnosisFiles
                                ? 'Caricamento in corso...'
                                : 'Seleziona file',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.borderSoft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_uploadingDiagnosisFiles) ...[
                          const SizedBox(height: AppSpacing.xs),
                          const LinearProgressIndicator(
                            minHeight: 4,
                            color: AppColors.ctaApricot,
                          ),
                        ],
                        if (_diagnosisFiles.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: _diagnosisFiles
                                .map(
                                  (fileRef) => Chip(
                                    avatar: const Icon(
                                      Icons.insert_drive_file_rounded,
                                      size: 18,
                                      color: AppColors.primaryBlue,
                                    ),
                                    label: Text(_fileLabel(fileRef)),
                                    onDeleted: () =>
                                        _removeDiagnosisFile(fileRef),
                                    deleteIconColor: AppColors.text.withValues(
                                      alpha: 0.6,
                                    ),
                                    backgroundColor: AppColors.background,
                                    side: const BorderSide(
                                      color: AppColors.borderSoft,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _careNotesCtrl,
                    minLines: 4,
                    maxLines: 6,
                    decoration: _diagnosisInputDecoration(
                      hintText:
                          'Note su dieta, farmaci, integratori o cure che il cane sta seguendo.',
                      hasError: false,
                    ),
                    onChanged: (_) => _notifyChange(),
                  ),
                ],
              ],
            ),
          ),
        ),
        _PinnedQuestionActions(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onGoBack(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Indietro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.borderSoft),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _attemptedSubmit = true);
                    if (!_isFormValid) return;
                    _notifyChange();
                    widget.onProceedTest();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaApricot,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continua',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    this.hasError = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.ctaApricot, Color(0xFFE7AA6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8FAFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasError
                ? Colors.red.shade400
                : selected
                ? AppColors.ctaApricot
                : AppColors.borderSoft,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.ctaApricot.withValues(alpha: 0.30)
                  : Colors.black12,
              blurRadius: selected ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.92)
                          : AppColors.text.withValues(alpha: 0.68),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? Colors.white
                  : AppColors.primaryBlue.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizBottomBar extends StatelessWidget {
  const _QuizBottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
    this.hideOnDiagnosisStep = false,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final bool hideOnDiagnosisStep;

  @override
  Widget build(BuildContext context) {
    final isFirst = currentPage == 0;
    final isLast = currentPage == totalPages - 1;
    if (hideOnDiagnosisStep && currentPage == 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirst)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: AppColors.ctaApricot,
              ),
              label: const Text(
                'Indietro',
                style: TextStyle(
                  color: AppColors.ctaApricot,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (!isLast)
            SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: onNext,
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Continua',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaApricot,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(150, 44),
                ),
                iconAlignment: IconAlignment.end,
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
