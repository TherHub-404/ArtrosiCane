import 'dart:io';

import 'package:artrosi_cane/core/widgets/app_banner.dart';
import 'package:artrosi_cane/core/widgets/app_button.dart';
import 'package:artrosi_cane/features/daily_check/domain/entities/daily_check_models.dart';
import 'package:artrosi_cane/features/daily_check/presentation/providers/daily_check_providers.dart';
import 'package:artrosi_cane/features/dog_dashboard/presentation/widgets/dog_edit_sheet.dart';
import 'package:artrosi_cane/features/home/data/dog_remote_repository.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DogDashboardScreen extends ConsumerStatefulWidget {
  const DogDashboardScreen({super.key, required this.dogData});

  final Map<String, dynamic>
  dogData; // Using Map for now, will switch to Dog entity later

  @override
  ConsumerState<DogDashboardScreen> createState() => _DogDashboardScreenState();
}

class _DogDashboardScreenState extends ConsumerState<DogDashboardScreen> {
  late String _name;
  late String _breed;
  late String _ageText;
  late String _weightText;
  late String _imagePath;
  late String _arthrosisGrade;
  late bool _hasConfirmedDiagnosis;
  String? _dogId;

  String _t(String key, [Map<String, String> params = const {}]) =>
      AppLocalizations.of(context).text(key, params);

  bool _hasSavedRiskGrade(String? grade) {
    if (grade == null || grade.trim().isEmpty) return false;
    return _displayGradeLabel(grade) != null;
  }

  String _effectiveArthrosisGrade(String grade) {
    if (_hasSavedRiskGrade(grade)) return grade;
    if (_hasConfirmedDiagnosis) return _t('Non rilevato');
    return grade;
  }

  @override
  void initState() {
    super.initState();
    final data = widget.dogData;
    _name = (data['name'] ?? 'Il tuo cane').toString();
    _breed = (data['breed'] ?? 'Razza non indicata').toString();
    _ageText = (data['age'] ?? 'N/A').toString();
    _weightText = (data['weight'] ?? 'N/A').toString();
    _imagePath = (data['imagePath'] ?? 'assets/first-dog.png').toString();
    _arthrosisGrade = (data['arthrosisGrade'] ?? 'Non rilevato').toString();
    _hasConfirmedDiagnosis =
        data['diagnosisStatus']?.toString() ==
        ArthrosisDiagnosisStatus.confirmed.name;
    _dogId = data['id']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => DogEditSheet(
                  initialName: _name,
                  initialAge: _ageText,
                  initialWeight: _weightText,
                  initialImagePath: _imagePath,
                  onSave: (newName, newAge, newWeight, newImage) async {
                    final dogId = _dogId;
                    if (dogId == null || dogId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_t('Errore: ID cane non trovato')),
                        ),
                      );
                      return false;
                    }

                    final parsedAge = double.tryParse(
                      newAge.replaceAll(',', '.'),
                    );
                    if (parsedAge == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_t('Inserisci un’età valida.'))),
                      );
                      return false;
                    }

                    final parsedWeight = double.tryParse(
                      newWeight.replaceAll(',', '.'),
                    );
                    if (parsedWeight == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_t('Inserisci un peso valido.')),
                        ),
                      );
                      return false;
                    }

                    try {
                      final repo = ref.read(dogRemoteRepositoryProvider);
                      final uploadedImageUrl = await repo.updateDog(
                        dogId: dogId,
                        name: newName.trim(),
                        ageYears: parsedAge,
                        weightKg: parsedWeight,
                        imagePath: newImage,
                      );
                      ref.invalidate(userDogsProvider);
                      if (!context.mounted) return true;
                      setState(() {
                        _name = newName.trim();
                        _ageText = newAge.trim();
                        _weightText = newWeight.trim();
                        if (uploadedImageUrl != null &&
                            uploadedImageUrl.isNotEmpty) {
                          _imagePath = uploadedImageUrl;
                        }
                      });
                      AppBanner.showSuccess(context, _t('Profilo aggiornato.'));
                      return true;
                    } catch (e) {
                      if (!context.mounted) return false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _t('Errore durante il salvataggio: {{error}}', {
                              'error': e.toString(),
                            }),
                          ),
                        ),
                      );
                      return false;
                    }
                  },
                  onDelete: () async {
                    // Confirm delete
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(_t('Elimina profilo')),
                        content: Text(
                          _t(
                            'Sei sicuro di voler eliminare il profilo di {{name}}? Questa azione non può essere annullata.',
                            {'name': _name},
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(_t('Annulla')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Elimina',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final dogId = _dogId;
                      if (dogId == null) {
                        // Should not happen if data is consistent, but safety check
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_t('Errore: ID cane non trovato')),
                            ),
                          );
                        }
                        return;
                      }

                      try {
                        // Close the sheet first
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }

                        final repo = ref.read(dogRemoteRepositoryProvider);
                        await repo.deleteDog(dogId);

                        // Refresh list
                        ref.invalidate(userDogsProvider);

                        if (context.mounted) {
                          // Go back to home
                          context.go('/home');
                          AppBanner.showSuccess(
                            context,
                            _t('Profilo eliminato.'),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _t(
                                  'Errore durante l\'eliminazione: {{error}}',
                                  {'error': e.toString()},
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Image
            _buildHeader(_imagePath),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  Text(
                    _name,
                    style: AppTypography.h1.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _breed,
                    style: AppTypography.body.copyWith(
                      color: AppColors.text.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        context.l10n.text('Età'),
                        context.l10n.text('{{age}} anni', {'age': _ageText}),
                        Icons.cake,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _buildStatCard(
                        context.l10n.text('Peso'),
                        '$_weightText kg',
                        Icons.monitor_weight,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Risk Section
                  _buildArthrosisSection(context, _arthrosisGrade),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick Check giornaliero
                  _buildQuickCheckSection(context),
                  const SizedBox(height: AppSpacing.xl),

                  // Personalized Advice
                  _buildAdviceSection(context),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String imagePath) {
    return SizedBox(
      height: 340, // Increased height slightly
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 20, // Leave space for the wave overlap
            child: _buildHeaderImage(imagePath),
          ),
          Positioned.fill(
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // White Wave Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: ClipPath(
              clipper: const _HeaderWaveClipper(),
              child: Container(color: AppColors.background),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(String imagePath) {
    final placeholder = Container(
      color: AppColors.background,
      child: const Icon(Icons.pets, color: AppColors.primaryBlue, size: 56),
    );

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    final localImage = File(imagePath);
    if (localImage.existsSync()) {
      return Image.file(
        localImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: AppColors.text.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArthrosisSection(BuildContext context, String grade) {
    final effectiveGrade = _effectiveArthrosisGrade(grade);
    final mapped = _mapRisk(effectiveGrade);
    final displayGrade = _displayGradeLabel(effectiveGrade);
    final isUnknown = mapped.label == null;
    final bgColor = isUnknown ? const Color(0xFFFFF3E0) : mapped.background;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_t('Rischio artrosi')}:',
                style: AppTypography.h1.copyWith(
                  color: mapped.textColor,
                  fontSize: 24,
                ),
              ),
              Icon(
                isUnknown
                    ? Icons.warning_amber_rounded
                    : Icons.health_and_safety,
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayGrade ?? _t('Non ancora valutato'),
            style: AppTypography.h1.copyWith(
              color: mapped.textColor,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: isUnknown ? _t('Fai il test') : _t('Rifai il test'),
              onPressed: () {
                context.push(
                  '/quiz',
                  extra: {'skipIntro': true, 'dog': widget.dogData},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(BuildContext context) {
    final gradeString = _effectiveArthrosisGrade(_arthrosisGrade);
    final riskCategory = _riskCategory(gradeString);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Consigli Personalizzati'),
          style: AppTypography.h1.copyWith(
            color: AppColors.ctaApricot,
            fontSize: 24, // Custom size for h3 equivalent
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildWalkCard(context, riskCategory, gradeString),
        const SizedBox(height: AppSpacing.md),
        _buildExerciseCard(context, riskCategory, gradeString),
      ],
    );
  }

  Widget _buildQuickCheckSection(BuildContext context) {
    final todayState = ref.watch(todayDailyDiaryStateProvider(_dogId));

    return todayState.when(
      loading: () => _buildQuickCheckCard(
        context,
        statusLabel: _t('Caricamento stato check...'),
        description: _t(
          'Stiamo controllando se il check di oggi e gia stato completato.',
        ),
        buttonLabel: _t('Apri check di oggi'),
        icon: Icons.hourglass_top_rounded,
        onPressed: null,
      ),
      error: (_, __) => _buildQuickCheckCard(
        context,
        statusLabel: _t('Stato check non disponibile'),
        description: _t(
          'Puoi comunque aprire il check: se eri offline, la bozza sul dispositivo resta disponibile.',
        ),
        buttonLabel: _t('Apri check di oggi'),
        icon: Icons.error_outline_rounded,
        onPressed: _openDailyCheck,
      ),
      data: (state) {
        final status = state.status;
        final isCompleted = status == DailyDiaryStatus.completed;
        final isDraft = status == DailyDiaryStatus.inProgress;
        return _buildQuickCheckCard(
          context,
          statusLabel: isCompleted
              ? _t('Check di oggi completato')
              : isDraft
              ? _t('Check di oggi in corso')
              : _t('Check di oggi da compilare'),
          description: isCompleted
              ? _t(
                  'Ottimo: il diario di oggi e salvato. Puoi rivedere il risultato o consultare lo storico.',
                )
              : isDraft
              ? _t(
                  'Hai una bozza salvata: continua da dove eri rimasto senza reinserire le risposte.',
                )
              : _t(
                  'In 20 secondi ottieni semaforo, 2 micro-azioni e 1 cosa da evitare per oggi.',
                ),
          buttonLabel: isCompleted
              ? _t('Vedi diario completo')
              : isDraft
              ? _t('Continua check di oggi')
              : _t('Inizia check di oggi'),
          icon: isCompleted
              ? Icons.check_circle_rounded
              : isDraft
              ? Icons.edit_note_rounded
              : Icons.traffic_rounded,
          onPressed: isCompleted ? _openDailyHistory : _openDailyCheck,
        );
      },
    );
  }

  void _openDailyCheck() {
    context.push(
      '/daily-check',
      extra: {
        'dogId': _dogId,
        'dogName': _name.isNotEmpty ? _name : context.l10n.text('Il tuo cane'),
      },
    );
  }

  void _openDailyHistory() {
    if (_dogId == null) return;
    context.push(
      '/daily-check/history',
      extra: {
        'dogId': _dogId,
        'dogName': _name.isNotEmpty ? _name : context.l10n.text('Il tuo cane'),
      },
    );
  }

  Widget _buildQuickCheckCard(
    BuildContext context, {
    required String statusLabel,
    required String description,
    required String buttonLabel,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.ctaApricot.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.ctaApricot, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.body.copyWith(
              color: AppColors.text.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaApricot,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _dogId == null ? null : _openDailyHistory,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(
                _t('Vedi diario completo'),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    _RiskCategory category,
    String gradeString,
  ) {
    final subtitle = _exerciseCardSubtitle(category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push(
            '/exercise',
            extra: {
              'grade': gradeString,
              'name': _name.isNotEmpty ? _name : 'Il tuo cane',
            },
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('Esercizio fisico consigliato'),
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.body.copyWith(
                  color: AppColors.text.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app, size: 18, color: AppColors.ctaApricot),
                  const SizedBox(width: 6),
                  Text(
                    _t('Tocca per aprire i dettagli'),
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.ctaApricot,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _exerciseCardSubtitle(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return _t('Idee per attività e gioco in sicurezza');
      case _RiskCategory.mild:
        return _t('Esercizi a basso impatto e sessioni brevi');
      case _RiskCategory.severe:
        return _t('Movimento dolce per mantenere la mobilità');
      case _RiskCategory.unknown:
        return _t('Apri i consigli per esercizi su misura');
    }
  }

  _RiskCategory _riskCategory(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('grave') ||
        normalized.contains('alto') ||
        normalized.contains('high') ||
        normalized.contains('élevé') ||
        normalized.contains('hohes') ||
        normalized.contains('hoch')) {
      return _RiskCategory.severe;
    }
    if (normalized.contains('lieve') ||
        normalized.contains('medio') ||
        normalized.contains('medium') ||
        normalized.contains('moyen') ||
        normalized.contains('mittel')) {
      return _RiskCategory.mild;
    }
    if (normalized.contains('nessun') ||
        normalized.contains('basso') ||
        normalized.contains('low') ||
        normalized.contains('faible') ||
        normalized.contains('niedrig')) {
      return _RiskCategory.none;
    }
    return _RiskCategory.unknown;
  }

  Widget _buildWalkCard(
    BuildContext context,
    _RiskCategory category,
    String gradeString,
  ) {
    final summary = _walkSummary(category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push(
            '/walks',
            extra: {
              'grade': gradeString,
              'name': _name.isNotEmpty ? _name : 'Il tuo cane',
            },
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.map_outlined, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.text('Video consigliati'),
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.title,
                style: AppTypography.body.copyWith(
                  color: AppColors.text.withValues(alpha: 0.8),
                ),
              ),
              if (summary.details != null) ...[
                const SizedBox(height: 4),
                Text(
                  summary.details!,
                  style: AppTypography.body.copyWith(
                    color: AppColors.text.withValues(alpha: 0.68),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app, size: 18, color: AppColors.ctaApricot),
                  const SizedBox(width: 6),
                  Text(
                    _t('Tocca per aprire i dettagli'),
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.ctaApricot,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _WalkSummary _walkSummary(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return _WalkSummary(
          title: _t('Nessun segno di artrosi: 10–20 min liberi.'),
          details: _t('Varia terreni e stimoli (parco, bosco, lungomare).'),
        );
      case _RiskCategory.mild:
        return _WalkSummary(
          title: _t('Artrosi lieve: 10–20 min, meglio uscite brevi.'),
          details: _t(
            'Prato/sterrato regolare; limita asfalto lungo e sabbia.',
          ),
        );
      case _RiskCategory.severe:
        return _WalkSummary(
          title: _t(
            'Artrosi avanzata: 5–10 min su prato, più volte al giorno.',
          ),
          details: _t(
            'Evita superfici dure o irregolari; percorsi piatti e prevedibili.',
          ),
        );
      case _RiskCategory.unknown:
        return _WalkSummary(
          title: _t('Fai il test per consigli mirati sulle passeggiate.'),
        );
    }
  }

  _RiskMapping _mapRisk(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('alto') ||
        normalized.contains('grave') ||
        normalized.contains('high') ||
        normalized.contains('élevé') ||
        normalized.contains('hohes') ||
        normalized.contains('hoch')) {
      return _RiskMapping(
        label: _t('Alto'),
        textColor: Colors.red.shade700,
        background: Colors.white,
      );
    }
    if (normalized.contains('medio') ||
        normalized.contains('lieve') ||
        normalized.contains('medium') ||
        normalized.contains('moyen') ||
        normalized.contains('mittel')) {
      return _RiskMapping(
        label: _t('Medio'),
        textColor: Colors.yellow.shade700,
        background: Colors.white,
      );
    }
    if (normalized.contains('nessun') ||
        normalized.contains('basso') ||
        normalized.contains('low') ||
        normalized.contains('faible') ||
        normalized.contains('niedrig')) {
      return _RiskMapping(
        label: _t('Basso'),
        textColor: Colors.green.shade700,
        background: Colors.white,
      );
    }
    // Unknown / not tested
    return _RiskMapping(
      label: null,
      textColor: AppColors.primaryBlue,
      background: Colors.white,
    );
  }

  String? _displayGradeLabel(String grade) {
    final normalized = grade.trim().toLowerCase();
    if (normalized.contains('alto') ||
        normalized.contains('grave') ||
        normalized.contains('high') ||
        normalized.contains('élevé') ||
        normalized.contains('hohes') ||
        normalized.contains('hoch')) {
      return _t('Alto');
    }
    if (normalized.contains('medio') ||
        normalized.contains('lieve') ||
        normalized.contains('medium') ||
        normalized.contains('moyen') ||
        normalized.contains('mittel')) {
      return _t('Medio');
    }
    if (normalized.contains('basso') ||
        normalized.contains('nessun') ||
        normalized.contains('low') ||
        normalized.contains('faible') ||
        normalized.contains('niedrig')) {
      return _t('Basso');
    }
    return null;
  }
}

class _RiskMapping {
  _RiskMapping({
    required this.label,
    required this.textColor,
    required this.background,
  });

  final String? label;
  final Color textColor;
  final Color background;
}

enum _RiskCategory { none, mild, severe, unknown }

class _WalkSummary {
  _WalkSummary({required this.title, this.details});
  final String title;
  final String? details;
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  const _HeaderWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    // Start from the bottom left, but go up to the wave start height
    // We want the white part to be at the bottom.
    // So we draw the shape of the WHITE overlay.

    // Start at (0, 40) - lower down
    path.moveTo(0, 40);

    // Go to (0, 0) is not what we want if we want the wave to be the top edge of this container.
    // The container is the white overlay.
    // So the top edge of this container should be the wave.

    // Let's make a nice S-curve
    // Start high on the left
    path.lineTo(0, 20);

    // Curve down then up
    final firstControlPoint = Offset(size.width * 0.25, 50);
    final firstEndPoint = Offset(size.width * 0.5, 30);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, 10);
    final secondEndPoint = Offset(size.width, 40);

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Close the path at the bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
