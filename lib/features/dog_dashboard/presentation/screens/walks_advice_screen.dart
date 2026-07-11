import 'package:artrosi_cane/features/dog_dashboard/presentation/widgets/advice_widgets.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WalksAdviceScreen extends StatelessWidget {
  const WalksAdviceScreen({
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
    final advice = _walkDetails(category);

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
        l10n.text('Passeggiate per {{dogName}}', {'dogName': dogName}),
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
            icon: Icons.directions_walk_rounded,
            accentColor: advice.accentColor,
            title: advice.title,
            metricIcon: Icons.schedule_rounded,
            metricLabel: l10n.text('Durata'),
            metricValue: advice.duration,
            objectiveLabel: l10n.text('Obiettivo'),
            objectiveText: objectiveText,
            extraPoints: extraPoints,
          ),
          const SizedBox(height: AppSpacing.md),
          _SurfaceCard(
            headerIcon: Icons.park_rounded,
            accentColor: AppColors.primaryBlue,
            title: l10n.text('Superfici consigliate'),
            items: advice.surfaces.map(l10n.text).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          _SurfaceCard(
            headerIcon: Icons.do_not_disturb_on_rounded,
            accentColor: AppColors.ctaApricot,
            title: l10n.text('Superfici da evitare / limitare'),
            items: advice.surfacesLimit.map(l10n.text).toList(),
          ),
          if (advice.note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AdviceNotesCard(
              title: l10n.text('Note'),
              note: l10n.text(advice.note),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _GuideVideoCard(
            dogName: dogName,
            onTap: () => context.push('/walks-overview'),
          ),
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

  _WalkAdvice _walkDetails(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return _WalkAdvice(
          title: AppLocalizations.current.text('Nessun segno di artrosi'),
          duration: '10–20 min',
          points: ['Obiettivo: movimento libero e stimolante'],
          surfaces: [
            'Prato',
            'Asfalto',
            'Sterrato',
            'Sabbia (con moderazione)',
          ],
          surfacesLimit: [],
          accentColor: AppColors.primaryBlue,
          note:
              'Percorsi: campagna, bosco, lungomare; varia terreni e stimoli senza particolari limitazioni.',
        );
      case _RiskCategory.mild:
        return _WalkAdvice(
          title: AppLocalizations.current.text('Artrosi lieve'),
          duration: '10–20 min',
          points: [
            'Obiettivo: movimento regolare a basso impatto',
            'Meglio più passeggiate brevi',
          ],
          surfaces: ['Prato (migliore)', 'Sterrato regolare'],
          surfacesLimit: [
            'Asfalto (ok se piano e breve)',
            'Sabbia (affatica le articolazioni)',
          ],
          accentColor: Colors.orange.shade700,
          note: 'Percorsi morbidi e pianeggianti, come boschi o parchi.',
        );
      case _RiskCategory.severe:
        return _WalkAdvice(
          title: AppLocalizations.current.text('Artrosi avanzata'),
          duration: '5–10 min',
          points: [
            'Obiettivo: mantenere la mobilità senza dolore',
            'Anche più volte al giorno',
          ],
          surfaces: ['Prato (ideale)'],
          surfacesLimit: ['Asfalto', 'Sabbia', 'Sterrati irregolari'],
          accentColor: Colors.red.shade700,
          note:
              'Percorsi piatti, prevedibili e morbidi; niente dislivelli o tratti lunghi.',
        );
      case _RiskCategory.unknown:
        return _WalkAdvice(
          title: AppLocalizations.current.text(
            'Fai il test per consigli mirati',
          ),
          duration: '-',
          points: [
            'Completa il test artrosi per vedere i video consigliati.',
          ],
          surfaces: [],
          surfacesLimit: [],
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

String _cleanSurfaceLabel(String text) {
  final noEmoji = text
      .replaceAll(RegExp(r'\p{Extended_Pictographic}', unicode: true), '')
      .replaceAll('️', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return noEmoji.isEmpty ? text.trim() : noEmoji;
}

String _surfaceEmoji(String label) {
  final normalized = label.toLowerCase();
  if (normalized.startsWith('nessun') ||
      normalized.startsWith('none') ||
      normalized.startsWith('aucun') ||
      normalized.startsWith('kein')) {
    return '🎉';
  }
  if (normalized.contains('prato') ||
      normalized.contains('grass') ||
      normalized.contains('herbe') ||
      normalized.contains('wiese')) {
    return '🌱';
  }
  if (normalized.contains('asfalto') ||
      normalized.contains('pavement') ||
      normalized.contains('asphalte') ||
      normalized.contains('asphalt')) {
    return '🛣️';
  }
  if (normalized.contains('sabbia') ||
      normalized.contains('sand') ||
      normalized.contains('sable')) {
    return '🏖️';
  }
  if (normalized.contains('sterrat') ||
      normalized.contains('dirt') ||
      normalized.contains('terre') ||
      normalized.contains('feldweg')) {
    if (normalized.contains('irregolar') ||
        normalized.contains('uneven') ||
        normalized.contains('irrégulier') ||
        normalized.contains('unregel')) {
      return '🪨';
    }
    return '🥾';
  }
  return '🏞️';
}

enum _RiskCategory { none, mild, severe, unknown }

class _WalkAdvice {
  _WalkAdvice({
    required this.title,
    required this.duration,
    required this.points,
    required this.surfaces,
    required this.surfacesLimit,
    required this.accentColor,
    required this.note,
  });

  final String title;
  final String duration;
  final List<String> points;
  final List<String> surfaces;
  final List<String> surfacesLimit;
  final Color accentColor;
  final String note;
}

/// Card listing recommended / limited walking surfaces, each shown as a soft
/// pill with a surface emoji.
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.headerIcon,
    required this.accentColor,
    required this.title,
    required this.items,
  });

  final IconData headerIcon;
  final Color accentColor;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final safeItems = items.isEmpty
        ? [AppLocalizations.current.text('Nessuna in particolare')]
        : items;

    return AdviceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdviceIconBadge(icon: headerIcon, color: accentColor, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < safeItems.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == safeItems.length - 1 ? 0 : 10,
              ),
              child: _SurfaceRow(
                label: _cleanSurfaceLabel(safeItems[i]),
                accentColor: accentColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _SurfaceRow extends StatelessWidget {
  const _SurfaceRow({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _surfaceEmoji(label),
              style: const TextStyle(fontSize: 16, height: 1),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apricot CTA card that opens the recommended walking videos.
class _GuideVideoCard extends StatelessWidget {
  const _GuideVideoCard({required this.dogName, required this.onTap});

  final String dogName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    return Semantics(
      button: true,
      label: AppLocalizations.current.text(
        'Guarda il nostro video guida per passeggiare meglio con {{dogName}}',
        {'dogName': dogName},
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.ctaApricot,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.ctaApricot.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.text('Guarda il nostro video guida'),
                          style: AppTypography.bodyBold.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.text(
                            'Per passeggiare meglio con {{dogName}}',
                            {'dogName': dogName},
                          ),
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
