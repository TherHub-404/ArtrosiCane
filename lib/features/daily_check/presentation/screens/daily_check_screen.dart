import 'package:artrosi_cane/core/widgets/non_medical_disclaimer.dart';
import 'package:artrosi_cane/features/daily_check/data/daily_check_repository.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/features/daily_check/presentation/providers/daily_check_providers.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DailyCheckScreen extends ConsumerStatefulWidget {
  const DailyCheckScreen({super.key, required this.dogName, this.dogId});

  final String dogName;
  final String? dogId;

  @override
  ConsumerState<DailyCheckScreen> createState() => _DailyCheckScreenState();
}

class _DailyCheckScreenState extends ConsumerState<DailyCheckScreen> {
  static const int _totalPages = 4;

  late final PageController _pageController = PageController();
  int _currentPage = 0;

  DailySymptomLevel? _symptomLevel;
  PlannedLoad? _plannedLoad;
  RecoveryDelta? _recoveryDelta;
  final Set<DailyRiskFactor> _riskFactors = <DailyRiskFactor>{};
  bool _saving = false;

  bool get _canSubmit =>
      _symptomLevel != null && _plannedLoad != null && _recoveryDelta != null;

  bool get _isLastPage => _currentPage == _totalPages - 1;

  bool _isStepAnswered(int step) {
    switch (step) {
      case 0:
        return _symptomLevel != null;
      case 1:
        return _plannedLoad != null;
      case 2:
        return true; // Risk factors are optional.
      case 3:
        return _recoveryDelta != null;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    if (_isLastPage) {
      await _submit();
      return;
    }
    if (_saving || !_isStepAnswered(_currentPage)) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToPreviousPage() async {
    if (_saving) return;
    if (_currentPage == 0) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
      return;
    }
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit || _saving) return;

    setState(() => _saving = true);
    try {
      final profile = await ref.read(loadDogProfileUseCaseProvider).call();
      final diagnosisStatus = profile?.diagnosisStatus;

      final input = DailyCheckInput(
        symptomLevel: _symptomLevel!,
        plannedLoad: _plannedLoad!,
        riskFactors: {..._riskFactors},
        recoveryDelta: _recoveryDelta!,
        diagnosisStatus: diagnosisStatus,
        dogId: widget.dogId,
        dogName: widget.dogName,
      );

      final repo = ref.read(dailyCheckRepositoryProvider);
      final sensitivities = repo.loadSensitivities(dogId: widget.dogId);
      final engine = ref.read(dailyRecommendationEngineProvider);
      final result = engine.evaluate(
        input: input,
        sensitivities: sensitivities,
      );

      await repo.saveDailyLog(input: input, result: result);
      if (!mounted) return;

      await context.push(
        '/daily-check/result',
        extra: {
          'dogName': widget.dogName,
          'dogId': widget.dogId,
          'result': result,
          'diagnosisStatus': diagnosisStatus?.name,
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / _totalPages;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Quick Check · ${widget.dogName}',
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w800,
            fontFamily: 'Montserrat',
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.borderSoft,
                color: AppColors.ctaApricot,
                minHeight: 6,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildSingleChoiceStep<DailySymptomLevel>(
                  stepIndex: 0,
                  questionTitle: 'Oggi come e andata?',
                  questionSubtitle: 'Hai notato rigidita o zoppia oggi?',
                  value: _symptomLevel,
                  options: const {
                    DailySymptomLevel.no: 'No',
                    DailySymptomLevel.lieve: 'Lieve',
                    DailySymptomLevel.marcata: 'Marcata',
                  },
                  onChanged: (value) => setState(() => _symptomLevel = value),
                ),
                _buildSingleChoiceStep<PlannedLoad>(
                  stepIndex: 1,
                  questionTitle: 'Carico previsto',
                  questionSubtitle: 'Quanto movimento fara oggi?',
                  value: _plannedLoad,
                  options: const {
                    PlannedLoad.breve: 'Breve (0-10 min)',
                    PlannedLoad.medio: 'Medio (10-20 min)',
                    PlannedLoad.lungo: 'Lungo (20+ min)',
                  },
                  onChanged: (value) => setState(() => _plannedLoad = value),
                ),
                _buildRiskFactorStep(),
                _buildSingleChoiceStep<RecoveryDelta>(
                  stepIndex: 3,
                  questionTitle: 'Recupero vs ieri',
                  questionSubtitle: 'Stamattina rispetto a ieri com\'era?',
                  value: _recoveryDelta,
                  options: const {
                    RecoveryDelta.uguale: 'Uguale',
                    RecoveryDelta.pocoPiuRigido: 'Un po piu rigido',
                    RecoveryDelta.moltoPiuRigido: 'Molto piu rigido',
                  },
                  onChanged: (value) => setState(() => _recoveryDelta = value),
                  footer: const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: NonMedicalDisclaimer(),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _goToPreviousPage,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Indietro'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.borderSoft),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        overlayColor: AppColors.primaryBlue.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isStepAnswered(_currentPage) && !_saving
                          ? _goToNextPage
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        overlayColor: Colors.black.withValues(alpha: 0.08),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLastPage
                                  ? 'Calcola stato di oggi'
                                  : 'Continua',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChoiceStep<T>({
    required int stepIndex,
    required String questionTitle,
    required String questionSubtitle,
    required T? value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
    Widget? footer,
  }) {
    return _buildStepContainer(
      stepIndex: stepIndex,
      questionTitle: questionTitle,
      questionSubtitle: questionSubtitle,
      child: Column(
        children: options.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OptionTile(
              label: entry.value,
              isSelected: value == entry.key,
              onTap: () => onChanged(entry.key),
            ),
          );
        }).toList(),
      ),
      footer: footer,
    );
  }

  Widget _buildRiskFactorStep() {
    return _buildStepContainer(
      stepIndex: 2,
      questionTitle: 'Fattori vacanza',
      questionSubtitle: 'Seleziona tutti quelli presenti oggi.',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: DailyRiskFactor.values.map((factor) {
          final selected = _riskFactors.contains(factor);
          return FilterChip(
            selected: selected,
            label: Text(dailyRiskFactorLabel(factor)),
            selectedColor: AppColors.ctaApricot.withValues(alpha: 0.22),
            onSelected: (value) {
              setState(() {
                if (value) {
                  _riskFactors.add(factor);
                } else {
                  _riskFactors.remove(factor);
                }
              });
            },
            checkmarkColor: AppColors.ctaApricot,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.primaryBlue
                  : AppColors.text.withValues(alpha: 0.9),
            ),
            side: BorderSide(
              color: selected
                  ? AppColors.ctaApricot
                  : AppColors.primaryBlue.withValues(alpha: 0.16),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepContainer({
    required int stepIndex,
    required String questionTitle,
    required String questionSubtitle,
    required Widget child,
    Widget? footer,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepIndex == 0) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                'Compila il check giornaliero in pochi secondi: oggi ottieni semaforo, 2 micro-azioni e 1 cosa da evitare.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.82),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Domanda ${stepIndex + 1}/$_totalPages',
                  style: AppTypography.bodyBold.copyWith(
                    fontSize: 13,
                    color: AppColors.ctaApricot,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  questionTitle,
                  style: AppTypography.bodyBold.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  questionSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ),
          ),
          if (footer != null) footer,
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
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.pressed)) {
          return Colors.transparent;
        }
        return isSelected
            ? Colors.black.withValues(alpha: 0.08)
            : AppColors.primaryBlue.withValues(alpha: 0.08);
      }),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ctaApricot : AppColors.card,
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
              color: isSelected ? Colors.white : AppColors.borderSoft,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
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
