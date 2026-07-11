import 'package:artrosi_cane/features/dog_dashboard/presentation/widgets/advice_widgets.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class ExerciseAdviceScreen extends StatelessWidget {
  const ExerciseAdviceScreen({
    super.key,
    required this.grade,
    required this.dogName,
  });

  final String grade;
  final String dogName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = _riskCategory(grade);
    final advice = _exerciseDetails(category);

    final points = advice.points.map(l10n.text).toList();
    final objectiveText = points.isEmpty
        ? ''
        : _stripObjectivePrefix(points.first);
    final extraPoints = points.length > 1
        ? points.sublist(1)
        : const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: adviceAppBar(
        context,
        l10n.text('Esercizio per {{dogName}}', {'dogName': dogName}),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          AdviceSummaryCard(
            icon: Icons.fitness_center_rounded,
            accentColor: advice.accentColor,
            title: advice.title,
            metricIcon: Icons.timer_outlined,
            metricLabel: l10n.text('Sessione'),
            metricValue: advice.session,
            objectiveLabel: l10n.text('Obiettivo'),
            objectiveText: objectiveText,
            extraPoints: extraPoints,
          ),
          if (advice.recommended.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AdviceListCard(
              headerIcon: Icons.check_circle_rounded,
              accentColor: AppColors.primaryBlue,
              title: l10n.text('Esercizi consigliati'),
              bulletIcon: Icons.check_rounded,
              items: advice.recommended.map(l10n.text).toList(),
            ),
          ],
          if (advice.avoid.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AdviceListCard(
              headerIcon: Icons.block_rounded,
              accentColor: AppColors.ctaApricot,
              title: l10n.text('Esercizi da evitare / limitare'),
              bulletIcon: Icons.remove_rounded,
              items: advice.avoid.map(l10n.text).toList(),
            ),
          ],
          if (advice.note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AdviceNotesCard(
              title: l10n.text('Note'),
              note: l10n.text(advice.note),
            ),
          ],
        ],
      ),
    );
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

  _ExerciseAdvice _exerciseDetails(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return _ExerciseAdvice(
          title: AppLocalizations.current.text('Nessun segno di artrosi'),
          session: '20–30 min',
          points: [
            'Obiettivo: forma fisica e tono muscolare',
            'Alterna attività e riposo',
          ],
          recommended: [
            'Passeggiata a ritmo sostenuto',
            'Giochi controllati (senza salti)',
            'Nuoto / acqua bassa',
          ],
          avoid: [],
          accentColor: AppColors.primaryBlue,
          note:
              'Se noti zoppia o rigidità dopo l’attività, riduci intensità e durata.',
        );
      case _RiskCategory.mild:
        return _ExerciseAdvice(
          title: AppLocalizations.current.text('Artrosi lieve'),
          session: '10–20 min',
          points: [
            'Obiettivo: movimento regolare a basso impatto',
            'Meglio più sessioni brevi',
          ],
          recommended: [
            'Camminata al guinzaglio su piano',
            'Nuoto / idroterapia (se disponibile)',
            'Esercizi lenti di mobilità',
          ],
          avoid: ['Scatti e frenate', 'Salti (divano/auto)', 'Scale lunghe'],
          accentColor: Colors.orange.shade700,
          note:
              'Riscaldamento 3–5 min e chiusura graduale; interrompi se compare dolore.',
        );
      case _RiskCategory.severe:
        return _ExerciseAdvice(
          title: AppLocalizations.current.text('Artrosi avanzata'),
          session: '5–10 min',
          points: [
            'Obiettivo: mantenere mobilità senza dolore',
            'Anche più volte al giorno',
          ],
          recommended: [
            'Camminata lenta su piano',
            'Esercizi guidati da fisioterapista',
            'Movimenti dolci in casa',
          ],
          avoid: [
            'Corsa e giochi intensi',
            'Salti e scale',
            'Terreni irregolari',
          ],
          accentColor: Colors.red.shade700,
          note:
              'Confrontati con il veterinario per un piano personalizzato e sicuro.',
        );
      case _RiskCategory.unknown:
        return _ExerciseAdvice(
          title: AppLocalizations.current.text(
            'Fai il test per consigli mirati',
          ),
          session: '-',
          points: [
            'Completa il test artrosi per vedere gli esercizi consigliati.',
          ],
          recommended: [],
          avoid: [],
          accentColor: AppColors.primaryBlue,
          note: '',
        );
    }
  }

  String _stripObjectivePrefix(String text) {
    final lower = text.toLowerCase();
    final objectivePrefix = '${AppLocalizations.current.text('Obiettivo')}:'
        .toLowerCase();
    if (lower.startsWith(objectivePrefix)) {
      return text.substring(objectivePrefix.length).trim();
    }
    return text;
  }
}

enum _RiskCategory { none, mild, severe, unknown }

class _ExerciseAdvice {
  _ExerciseAdvice({
    required this.title,
    required this.session,
    required this.points,
    required this.recommended,
    required this.avoid,
    required this.accentColor,
    required this.note,
  });

  final String title;
  final String session;
  final List<String> points;
  final List<String> recommended;
  final List<String> avoid;
  final Color accentColor;
  final String note;
}
