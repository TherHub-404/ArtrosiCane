import 'package:artrosi_cane/core/widgets/non_medical_disclaimer.dart';
import 'package:artrosi_cane/features/daily_check/data/daily_check_repository.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/features/daily_check/presentation/providers/daily_check_providers.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
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
  DailySymptomLevel? _symptomLevel;
  PlannedLoad? _plannedLoad;
  RecoveryDelta? _recoveryDelta;
  final Set<DailyRiskFactor> _riskFactors = <DailyRiskFactor>{};
  bool _saving = false;

  bool get _canSubmit =>
      _symptomLevel != null && _plannedLoad != null && _recoveryDelta != null;

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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.bodyBold.copyWith(
        fontSize: 17,
        color: AppColors.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 14),
            _questionCard(
              title: 'Q1 · Oggi com’è andata?',
              subtitle: 'Hai notato rigidità o zoppia oggi?',
              child: _buildRadioGroup<DailySymptomLevel>(
                value: _symptomLevel,
                options: const {
                  DailySymptomLevel.no: 'No',
                  DailySymptomLevel.lieve: 'Lieve',
                  DailySymptomLevel.marcata: 'Marcata',
                },
                onChanged: (value) => setState(() => _symptomLevel = value),
              ),
            ),
            const SizedBox(height: 12),
            _questionCard(
              title: 'Q2 · Carico previsto',
              subtitle: 'Quanto movimento farà oggi?',
              child: _buildRadioGroup<PlannedLoad>(
                value: _plannedLoad,
                options: const {
                  PlannedLoad.breve: 'Breve (0–10 min)',
                  PlannedLoad.medio: 'Medio (10–20 min)',
                  PlannedLoad.lungo: 'Lungo (20+ min)',
                },
                onChanged: (value) => setState(() => _plannedLoad = value),
              ),
            ),
            const SizedBox(height: 12),
            _questionCard(
              title: 'Q3 · Fattori vacanza',
              subtitle: 'Seleziona tutti quelli presenti oggi.',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
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
            ),
            const SizedBox(height: 12),
            _questionCard(
              title: 'Q4 · Recupero vs ieri',
              subtitle: 'Stamattina rispetto a ieri com’era?',
              child: _buildRadioGroup<RecoveryDelta>(
                value: _recoveryDelta,
                options: const {
                  RecoveryDelta.uguale: 'Uguale',
                  RecoveryDelta.pocoPiuRigido: 'Un po’ più rigido',
                  RecoveryDelta.moltoPiuRigido: 'Molto più rigido',
                },
                onChanged: (value) => setState(() => _recoveryDelta = value),
              ),
            ),
            const SizedBox(height: 14),
            const NonMedicalDisclaimer(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit && !_saving ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaApricot,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    : const Text(
                        'Calcola stato di oggi',
                        style: TextStyle(
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
    );
  }

  Widget _questionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          _sectionTitle(title),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioGroup<T>({
    required T? value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      children: options.entries.map((entry) {
        return RadioListTile<T>(
          value: entry.key,
          groupValue: value,
          activeColor: AppColors.ctaApricot,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            entry.value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
