import 'package:artrosi_cane/core/widgets/app_card.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/core/widgets/non_medical_disclaimer.dart';
import 'package:artrosi_cane/core/config/app_config.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/dog_profile_screen.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/dog_supabase_repository.dart';
import 'package:artrosi_cane/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/diagnosis_priority_models.dart';
import 'package:artrosi_cane/features/quiz/domain/services/diagnosis_priority_engine.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_answer.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizFlowScreen extends ConsumerStatefulWidget {
  const QuizFlowScreen({super.key, this.skipIntro = false, this.dogData});

  final bool skipIntro;
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

  bool get _isConfirmedDiagnosisFlow =>
      !widget.skipIntro &&
      !_shouldAskDiagnosis &&
      _diagnosisStatus == ArthrosisDiagnosisStatus.confirmed;

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
    if (widget.skipIntro && widget.dogData != null) {
      final data = widget.dogData!;
      _dogId = data['id'] as String?;
      _dogName = data['name'] as String?;
      _dogBreed = data['breed'] as String?;
      _dogImage = data['imagePath'] as String?;
      _dogAge = (data['age'] as num?)?.toDouble();
      _dogWeight = (data['weight'] as num?)?.toDouble();
    }
    if (!widget.skipIntro) {
      _bootstrapDiagnosisState();
    }
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
      setState(() {
        _diagnosisStatus = restoredStatus;
        _diagnosisAnsweredAt = restoredAnsweredAt;
        _diagnosisDate = restoredDate;
        _diagnosisVet = restoredVet;
        _shouldAskDiagnosis =
            restoredAnsweredAt == null || restoredStatus == null;
      });
      _syncProfile();
    } catch (_) {
      // Ignore stale local data and keep default onboarding flow.
    }
  }

  void _onProfileChanged(DogProfile profile) {
    _profileDraft = profile;
    _syncProfile();
    ref.read(saveDogProfileUseCaseProvider).call(_latestProfile!);
  }

  Future<void> _persistDogProfileRemote() async {
    if (_latestProfile == null) return;
    try {
      if (_isDemoUser()) return;
      final id = await ref
          .read(dogSupabaseRepositoryProvider)
          .upsertDog(_latestProfile!);
      if (id != null) {
        _dogId = id;
      }
    } catch (_) {
      // Ignore remote errors for now
    }
  }

  Future<void> _goToQuestions() async {
    _shouldAskDiagnosis = false;
    await _persistDogProfileRemote();
    if (!mounted) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
  }) {
    final previousStatus = _diagnosisStatus;
    _diagnosisStatus = diagnosisStatus;
    _diagnosisAnsweredAt ??= DateTime.now();
    if (diagnosisStatus == ArthrosisDiagnosisStatus.confirmed) {
      _diagnosisDate = diagnosisDate;
      _diagnosisVet = diagnosisVet;
    } else {
      _diagnosisDate = null;
      _diagnosisVet = null;
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
      ageGroup: base?.ageGroup ?? AgeGroup.adulto,
      size: base?.size ?? DogSize.media,
    );
  }

  Future<void> _onAnswerSelected(String questionId, int answerValue) async {
    final controller = ref.read(quizControllerProvider.notifier);
    await controller.selectAnswer(questionId, answerValue);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final state = ref.read(quizControllerProvider);
    final introPages = _introPages();
    final totalPages = state.questions.length + introPages;

    if (_currentPage == totalPages - 1) {
      await controller.submitQuiz(scoreAdjustment: _diagnosisScoreAdjustment());
      final result = ref.read(quizControllerProvider).result;
      if (result != null && mounted) {
        await _persistResultRemote(result);
        if (widget.skipIntro) {
          await _navigateBackToDogDashboard(result);
        } else {
          await ref.read(completeOnboardingUseCaseProvider).call();
          if (!mounted) return;
          context.go('/quiz/result', extra: result);
        }
      }
    } else {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _introPages() {
    if (widget.skipIntro) return 0;
    return _shouldAskDiagnosis ? 2 : 1;
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

  Future<void> _advanceConfirmedDiagnosisFlowFrom(int step) async {
    if (!_isConfirmedDiagnosisStepAnswered(step)) return;
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

  Future<void> _persistResultRemote(
    QuizResult result, {
    List<QuizAnswer>? answers,
  }) async {
    if (_isDemoUser()) return;
    final payloadAnswers = answers ?? ref.read(quizControllerProvider).answers;
    final dogId = _dogId;
    await ref
        .read(quizRemoteDataSourceProvider)
        .saveResult(result: result, dogId: dogId, answers: payloadAnswers);
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
      await _persistResultRemote(legacyResult, answers: const []);
      await ref.read(completeOnboardingUseCaseProvider).call();
      if (!mounted) return;
      context.go('/quiz/diagnosis-result', extra: priorityResult);
    } finally {
      if (mounted) setState(() => _submittingDiagnosisFlow = false);
    }
  }

  bool _isDemoUser() {
    final demoEmail = AppConfig.demoEmail;
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    if (demoEmail == null || currentEmail == null) return false;
    return currentEmail.toLowerCase() == demoEmail.toLowerCase();
  }

  Future<void> _navigateBackToDogDashboard(QuizResult result) async {
    // Refresh dog list so the updated risk is pulled on home.
    ref.invalidate(userDogsProvider);

    final gradeLabel = _riskLabel(result.riskLevel);
    final data = {
      'id': _dogId,
      'name': _dogName ?? 'Il tuo cane',
      'breed': _dogBreed ?? 'Razza non indicata',
      'imagePath': _dogImage ?? 'assets/first-dog.png',
      'age': _dogAge,
      'weight': _dogWeight,
      'arthrosisGrade': gradeLabel,
    };

    if (mounted) {
      context.go('/dog-dashboard', extra: data);
    }
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
              physics: _isConfirmedDiagnosisFlow
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                if (_isConfirmedDiagnosisFlow) return;
                if (!widget.skipIntro && index >= questionStartIndex) {
                  ref
                      .read(quizControllerProvider.notifier)
                      .setIndex(index - questionStartIndex);
                } else if (widget.skipIntro) {
                  ref.read(quizControllerProvider.notifier).setIndex(index);
                }
              },
              itemBuilder: (context, index) {
                if (!widget.skipIntro) {
                  if (index == 0) {
                    return DogProfilePage(onProfileChanged: _onProfileChanged);
                  }
                  if (_shouldAskDiagnosis && index == 1) {
                    return _DiagnosisStep(
                      initialStatus: _diagnosisStatus,
                      initialDate: _diagnosisDate,
                      initialVet: _diagnosisVet,
                      onChange: (status, date, vet) {
                        setState(() {
                          _updateDiagnosis(
                            diagnosisStatus: status,
                            diagnosisDate: date,
                            diagnosisVet: vet,
                          );
                        });
                      },
                      onProceedTest: _goToQuestions,
                    );
                  }
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

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!widget.skipIntro && _currentPage == 0)
          ? _QuizBottomBar(
              currentPage: _currentPage,
              totalPages: totalPages,
              onBack: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              onNext: () async {
                if (_currentPage == 0) {
                  await _persistDogProfileRemote();
                }
                await _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              onSubmit: () {},
              hideOnDiagnosisStep: false,
            )
          : const SizedBox.shrink(),
    );
  }

  void _selectAndAdvance({required int step, required VoidCallback update}) {
    if (_submittingDiagnosisFlow) return;
    setState(update);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _advanceConfirmedDiagnosisFlowFrom(step);
    });
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
              onTap: () => _selectAndAdvance(
                step: step,
                update: () => _diagnosisMobility = DiagnosisMobility.lieve,
              ),
            ),
            (
              label: 'Moderata',
              detail: 'Rallenta ed evita alcuni movimenti.',
              selected: _diagnosisMobility == DiagnosisMobility.moderata,
              onTap: () => _selectAndAdvance(
                step: step,
                update: () => _diagnosisMobility = DiagnosisMobility.moderata,
              ),
            ),
            (
              label: 'Avanzata',
              detail: 'Difficolta evidente, fatica ad alzarsi.',
              selected: _diagnosisMobility == DiagnosisMobility.avanzata,
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
                update: () => _diagnosisRecovery = DiagnosisRecovery.uguale,
              ),
            ),
            (
              label: 'Un po peggio',
              detail: null,
              selected: _diagnosisRecovery == DiagnosisRecovery.unPoPeggio,
              onTap: () => _selectAndAdvance(
                step: step,
                update: () => _diagnosisRecovery = DiagnosisRecovery.unPoPeggio,
              ),
            ),
            (
              label: 'Molto peggio',
              detail: null,
              selected: _diagnosisRecovery == DiagnosisRecovery.moltoPeggio,
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
                update: () => _diagnosisHomeRiskFactors = true,
              ),
            ),
            (
              label: 'No',
              detail: null,
              selected: _diagnosisHomeRiskFactors == false,
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
                update: () =>
                    _diagnosisWeightTrend = DiagnosisWeightTrend.stabile,
              ),
            ),
            (
              label: 'In aumento',
              detail: null,
              selected: _diagnosisWeightTrend == DiagnosisWeightTrend.inAumento,
              onTap: () => _selectAndAdvance(
                step: step,
                update: () =>
                    _diagnosisWeightTrend = DiagnosisWeightTrend.inAumento,
              ),
            ),
            (
              label: 'Non so',
              detail: null,
              selected: _diagnosisWeightTrend == DiagnosisWeightTrend.nonSo,
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
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
              onTap: () => _selectAndAdvance(
                step: step,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  style: AppTypography.h1.copyWith(fontSize: 22, height: 1.2),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText.body('Seleziona tutte quelle indicate nella diagnosi.'),
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
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _diagnosisJoints.isEmpty || _submittingDiagnosisFlow
                  ? null
                  : () => _advanceConfirmedDiagnosisFlowFrom(step),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaApricot,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Continua'),
            ),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  style: AppTypography.h1.copyWith(fontSize: 22, height: 1.2),
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
          if (_submittingDiagnosisFlow &&
              step == _confirmedDiagnosisQuestionCount - 1)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
            ),
        ],
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
    required this.onChange,
    required this.onProceedTest,
  });

  final ArthrosisDiagnosisStatus? initialStatus;
  final String? initialDate;
  final String? initialVet;
  final void Function(
    ArthrosisDiagnosisStatus status,
    String? date,
    String? vet,
  )
  onChange;
  final VoidCallback onProceedTest;

  @override
  Widget build(BuildContext context) {
    return _DiagnosisStepContent(
      initialStatus: initialStatus,
      initialDate: initialDate,
      initialVet: initialVet,
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
    required this.onChange,
    required this.onProceedTest,
  });

  final ArthrosisDiagnosisStatus? initialStatus;
  final String? initialDate;
  final String? initialVet;
  final void Function(
    ArthrosisDiagnosisStatus status,
    String? date,
    String? vet,
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

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _dateCtrl = TextEditingController(text: widget.initialDate ?? '');
    _vetCtrl = TextEditingController(text: widget.initialVet ?? '');
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _vetCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    if (_status == null) return;
    final hasConfirmedDiagnosis = _status == ArthrosisDiagnosisStatus.confirmed;
    widget.onChange(
      _status!,
      hasConfirmedDiagnosis && _dateCtrl.text.isNotEmpty
          ? _dateCtrl.text.trim()
          : null,
      hasConfirmedDiagnosis && _vetCtrl.text.isNotEmpty
          ? _vetCtrl.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: 'Sì, ha una diagnosi\ndi artrosi',
                  selected: _status == ArthrosisDiagnosisStatus.confirmed,
                  onTap: () {
                    setState(
                      () => _status = ArthrosisDiagnosisStatus.confirmed,
                    );
                    _notifyChange();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ChoiceCard(
                  label: 'No, non ha una\ndiagnosi di artrosi',
                  selected: _status == ArthrosisDiagnosisStatus.notDiagnosed,
                  onTap: () {
                    setState(
                      () => _status = ArthrosisDiagnosisStatus.notDiagnosed,
                    );
                    _notifyChange();
                  },
                ),
              ),
            ],
          ),
          if (_status == ArthrosisDiagnosisStatus.confirmed) ...[
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _dateCtrl,
              decoration: InputDecoration(
                hintText: 'Quando è stata fatta la diagnosi?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (_) => _notifyChange(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _vetCtrl,
              decoration: InputDecoration(
                hintText: 'Da che studio veterinario?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (_) => _notifyChange(),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _status == null
                  ? null
                  : () {
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
          const SizedBox(height: AppSpacing.md),
          const NonMedicalDisclaimer(compact: true),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.ctaApricot : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.ctaApricot : AppColors.borderSoft,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
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
