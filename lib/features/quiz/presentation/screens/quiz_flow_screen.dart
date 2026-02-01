import 'package:artrosi_cane/core/widgets/app_card.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/features/onboarding/presentation/screens/dog_profile_screen.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/dog_supabase_repository.dart';
import 'package:artrosi_cane/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizFlowScreen extends ConsumerStatefulWidget {
  const QuizFlowScreen({super.key, this.skipIntro = false, this.dogData});

  final bool skipIntro;
  final Map<String, dynamic>? dogData;

  @override
  ConsumerState<QuizFlowScreen> createState() => _QuizFlowScreenState();
}

class _QuizFlowScreenState extends ConsumerState<QuizFlowScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.skipIntro ? 0 : 0);
  int _currentPage = 0;
  DogProfile? _profileDraft;
  DogProfile? _latestProfile;
  bool _wantsTest = true;
  bool _hasDiagnosis = false;
  String? _diagnosisDate;
  String? _diagnosisVet;
  String? _dogId;
  String? _dogName;
  String? _dogBreed;
  String? _dogImage;
  double? _dogAge;
  double? _dogWeight;

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
  }

  void _onProfileChanged(DogProfile profile) {
    _profileDraft = profile;
    _syncProfile();
    ref.read(saveDogProfileUseCaseProvider).call(_latestProfile!);
  }

  Future<void> _persistDogProfileRemote() async {
    if (_latestProfile == null) return;
    try {
      final id = await ref.read(dogSupabaseRepositoryProvider).upsertDog(_latestProfile!);
      if (id != null) {
        _dogId = id;
      }
    } catch (_) {
      // Ignore remote errors for now
    }
  }

  Future<void> _goToQuestions() async {
    await _persistDogProfileRemote();
    if (mounted) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _skipTestToLogin() async {
    await ref.read(completeOnboardingUseCaseProvider).call();
    if (mounted) {
      context.go('/auth');
    }
  }

  void _updateDiagnosis({
    required bool hasDiagnosis,
    String? diagnosisDate,
    String? diagnosisVet,
    required bool wantsTest,
  }) {
    _hasDiagnosis = hasDiagnosis;
    _diagnosisDate = diagnosisDate;
    _diagnosisVet = diagnosisVet;
    _wantsTest = wantsTest;
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
      hasDiagnosis: _hasDiagnosis,
      diagnosisDate: _diagnosisDate,
      diagnosisVet: _diagnosisVet,
      ageGroup: base?.ageGroup ?? AgeGroup.adulto,
      size: base?.size ?? DogSize.media,
    );
  }

  Future<void> _onAnswerSelected(String questionId, int answerValue) async {
    final controller = ref.read(quizControllerProvider.notifier);
    controller.selectAnswer(questionId, answerValue);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
       final state = ref.read(quizControllerProvider);
       final introPages = widget.skipIntro ? 0 : 2;
       final totalPages = state.questions.length + introPages;

       if (_currentPage == totalPages - 1) {
         await controller.submitQuiz();
         final result = ref.read(quizControllerProvider).result;
         if (result != null && mounted) {
            await _persistResultRemote(result);
            if (widget.skipIntro) {
              await _navigateBackToDogDashboard(result);
            } else {
              await ref.read(completeOnboardingUseCaseProvider).call();
              context.go('/quiz/result', extra: result);
            }
         }
       } else {
         _pageController.nextPage(
           duration: const Duration(milliseconds: 300),
           curve: Curves.easeInOut,
         );
       }
    }
  }

  Future<void> _persistResultRemote(QuizResult result) async {
    final answers = ref.read(quizControllerProvider).answers;
    final dogId = _dogId;
    await ref.read(quizRemoteDataSourceProvider).saveResult(
          result: result,
          dogId: dogId,
          answers: answers,
        );
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    if (state.isLoading) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    final introPages = widget.skipIntro ? 0 : 2;
    final totalPages = state.questions.length + introPages; // profile + diagnosis + questions

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
              final page = _pageController.hasClients ? (_pageController.page ?? 0.0) : 0.0;
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
              physics: const AlwaysScrollableScrollPhysics(), // Allow swipe
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                if (!widget.skipIntro && index > 1) {
                  ref.read(quizControllerProvider.notifier).setIndex(index - 2);
                } else if (widget.skipIntro) {
                  ref.read(quizControllerProvider.notifier).setIndex(index);
                }
              },
              itemBuilder: (context, index) {
                if (!widget.skipIntro) {
                  if (index == 0) {
                    return DogProfilePage(onProfileChanged: _onProfileChanged);
                  }
                  if (index == 1) {
                    return _DiagnosisStep(
                      initialHasDiagnosis: _hasDiagnosis,
                      initialWantsTest: _wantsTest,
                      initialDate: _diagnosisDate,
                      initialVet: _diagnosisVet,
                      onChange: (hasDx, wantsTest, date, vet) {
                        setState(() {
                          _updateDiagnosis(
                            hasDiagnosis: hasDx,
                            diagnosisDate: date,
                            diagnosisVet: vet,
                            wantsTest: wantsTest,
                          );
                        });
                      },
                      onProceedTest: _goToQuestions,
                      onSkipTest: _skipTestToLogin,
                    );
                  }
                }

                final questionIndex = widget.skipIntro ? index : index - 2;
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
                                onTap: () => _onAnswerSelected(question.id, entry.key),
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
                _pageController.nextPage(
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
          color: isSelected ? AppColors.ctaApricot : AppColors.card, // Orange when selected
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
              color: isSelected ? Colors.white : AppColors.borderSoft, // White icon when selected
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text, // White text when selected
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
    required this.initialHasDiagnosis,
    required this.initialWantsTest,
    this.initialDate,
    this.initialVet,
    required this.onChange,
    required this.onProceedTest,
    required this.onSkipTest,
  });

  final bool initialHasDiagnosis;
  final bool initialWantsTest;
  final String? initialDate;
  final String? initialVet;
  final void Function(bool hasDiagnosis, bool wantsTest, String? date, String? vet) onChange;
  final VoidCallback onProceedTest;
  final VoidCallback onSkipTest;

  @override
  Widget build(BuildContext context) {
    return _DiagnosisStepContent(
      initialHasDiagnosis: initialHasDiagnosis,
      initialWantsTest: initialWantsTest,
      initialDate: initialDate,
      initialVet: initialVet,
      onChange: onChange,
      onProceedTest: onProceedTest,
      onSkipTest: onSkipTest,
    );
  }
}

class _DiagnosisStepContent extends StatefulWidget {
  const _DiagnosisStepContent({
    required this.initialHasDiagnosis,
    required this.initialWantsTest,
    this.initialDate,
    this.initialVet,
    required this.onChange,
    required this.onProceedTest,
    required this.onSkipTest,
  });

  final bool initialHasDiagnosis;
  final bool initialWantsTest;
  final String? initialDate;
  final String? initialVet;
  final void Function(bool hasDiagnosis, bool wantsTest, String? date, String? vet) onChange;
  final VoidCallback onProceedTest;
  final VoidCallback onSkipTest;

  @override
  State<_DiagnosisStepContent> createState() => _DiagnosisStepContentState();
}

class _DiagnosisStepContentState extends State<_DiagnosisStepContent> {
  late bool _hasDiagnosis = widget.initialHasDiagnosis;
  late bool _wantsTest = widget.initialWantsTest;
  late TextEditingController _dateCtrl;
  late TextEditingController _vetCtrl;

  @override
  void initState() {
    super.initState();
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
    widget.onChange(
      _hasDiagnosis,
      _wantsTest,
      _dateCtrl.text.isEmpty ? null : _dateCtrl.text.trim(),
      _vetCtrl.text.isEmpty ? null : _vetCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.h1(
            'Diagnosi di artrosi',
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _hasDiagnosis,
            activeColor: AppColors.ctaApricot,
            title: const Text('Il tuo cane ha già una diagnosi di artrosi?'),
            onChanged: (value) {
              setState(() => _hasDiagnosis = value);
              _notifyChange();
            },
          ),
          if (_hasDiagnosis) ...[
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.lg),
            AppText.body(
              'Vuoi comunque fare il test rapido di 5 domande?',
              color: AppColors.text,
              bold: true,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ChoiceCard(
                    label: 'Sì, fai il test',
                    selected: _wantsTest,
                    onTap: () {
                      setState(() => _wantsTest = true);
                      _notifyChange();
                      widget.onProceedTest();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChoiceCard(
                    label: 'No, vai al login',
                    selected: !_wantsTest,
                    onTap: () {
                      setState(() => _wantsTest = false);
                      _notifyChange();
                      widget.onSkipTest();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppText.body(
              'Se scegli di saltare il test verrai portato alla schermata di login.',
              color: AppColors.text,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.lg),
            AppText.body(
              'Nessuna diagnosi? Puoi fare un rapido test di 5 domande per scoprire lo stato di salute del tuo cane.',
              color: AppColors.text.withOpacity(0.8),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ChoiceCard(
              label: 'Sì, fai il test',
              selected: true,
              onTap: () {
                setState(() => _wantsTest = true);
                _notifyChange();
                widget.onProceedTest();
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
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
              icon: const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.ctaApricot),
              label: const Text('Indietro', style: TextStyle(color: AppColors.ctaApricot, fontWeight: FontWeight.bold)),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (!isLast)
            SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
