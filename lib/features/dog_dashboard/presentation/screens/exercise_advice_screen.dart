import 'dart:ui' show ImageFilter;

import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final category = _riskCategory(grade);
    final advice = _exerciseDetails(category);

    return Scaffold(
      backgroundColor: AppColors.ctaApricot,
      appBar: AppBar(
        backgroundColor: AppColors.ctaApricot,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Esercizio per $dogName',
          style: AppTypography.bodyBold.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(AppColors.primaryBlue, Colors.white, 0.22)!,
                      AppColors.primaryBlue,
                      Color.lerp(AppColors.primaryBlue, Colors.black, 0.10)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(36),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sessione',
                        style: AppTypography.bodyBold.copyWith(
                          fontSize: 12,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        advice.session,
                        style: AppTypography.bodyBold.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Color.lerp(advice.accentColor, Colors.white, 0.93)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: advice.accentColor.withAlpha(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advice.title,
                        style: AppTypography.bodyBold.copyWith(
                          color: advice.accentColor,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (advice.points.isNotEmpty) ...[
                        Text(
                          'Obiettivo',
                          style: AppTypography.bodyBold.copyWith(
                            color: advice.accentColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stripObjectivePrefix(advice.points.first),
                          style: AppTypography.body.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                      ],
                      if (advice.points.length > 1) ...[
                        const SizedBox(height: 6),
                        ...advice.points.sublist(1).map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  p,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final recommendedCard = _buildCard(
                title: 'Esercizi consigliati',
                items: advice.recommended,
                accent: Colors.white,
                titleColor: AppColors.primaryBlue,
                chipColor: AppColors.primaryBlue,
                textColor: AppColors.text,
                icon: Icons.check_circle_rounded,
                minHeight: 180,
              );
              final avoidCard = _buildCard(
                title: 'Esercizi da evitare / limitare',
                items: advice.avoid,
                accent: Colors.white,
                titleColor: AppColors.ctaApricot,
                chipColor: AppColors.ctaApricot,
                textColor: AppColors.ctaApricot,
                icon: Icons.close_rounded,
                minHeight: 180,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    recommendedCard,
                    const SizedBox(height: AppSpacing.md),
                    avoidCard,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: recommendedCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: avoidCard),
                  ],
                ),
              );
            },
          ),
          if (advice.note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _NotesDisclosure(
              title: 'Note',
              note: advice.note,
              accentColor: AppColors.primaryBlue,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<String> items,
    required Color accent,
    Color? titleColor,
    Color? chipColor,
    Color? textColor,
    IconData icon = Icons.check_circle,
    double? minHeight,
  }) {
    final tColor = titleColor ?? accent;
    final cColor = chipColor ?? accent;
    final bodyColor = textColor ?? AppColors.text;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.bodyBold.copyWith(
                color: tColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...items.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: cColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTypography.body.copyWith(color: bodyColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _RiskCategory _riskCategory(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('grave') || normalized.contains('alto')) return _RiskCategory.severe;
    if (normalized.contains('lieve') || normalized.contains('medio')) return _RiskCategory.mild;
    if (normalized.contains('nessun') || normalized.contains('basso')) return _RiskCategory.none;
    return _RiskCategory.unknown;
  }

  _ExerciseAdvice _exerciseDetails(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return _ExerciseAdvice(
          title: 'Nessun segno di artrosi',
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
          note: 'Se noti zoppia o rigidità dopo l’attività, riduci intensità e durata.',
        );
      case _RiskCategory.mild:
        return _ExerciseAdvice(
          title: 'Artrosi lieve',
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
          avoid: [
            'Scatti e frenate',
            'Salti (divano/auto)',
            'Scale lunghe',
          ],
          accentColor: Colors.orange.shade700,
          note: 'Riscaldamento 3–5 min e chiusura graduale; interrompi se compare dolore.',
        );
      case _RiskCategory.severe:
        return _ExerciseAdvice(
          title: 'Artrosi avanzata',
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
          note: 'Confrontati con il veterinario per un piano personalizzato e sicuro.',
        );
      case _RiskCategory.unknown:
        return _ExerciseAdvice(
          title: 'Fai il test per consigli mirati',
          session: '-',
          points: ['Completa il test artrosi per vedere gli esercizi consigliati.'],
          recommended: [],
          avoid: [],
          accentColor: AppColors.primaryBlue,
          note: '',
        );
    }
  }

  String _stripObjectivePrefix(String text) {
    final lower = text.toLowerCase();
    if (lower.startsWith('obiettivo:')) {
      return text.substring(10).trim();
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

class _NotesDisclosure extends StatefulWidget {
  const _NotesDisclosure({
    required this.title,
    required this.note,
    required this.accentColor,
  });

  final String title;
  final String note;
  final Color accentColor;

  @override
  State<_NotesDisclosure> createState() => _NotesDisclosureState();
}

class _NotesDisclosureState extends State<_NotesDisclosure> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));
    final glassTop = widget.accentColor.withAlpha(175);
    final glassBottom = widget.accentColor.withAlpha(125);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [glassTop, glassBottom],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withAlpha(92)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  expanded: _open,
                  label: widget.title,
                  child: InkWell(
                    onTap: _toggle,
                    borderRadius: radius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.accentColor.withAlpha(64),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withAlpha(92),
                              ),
                            ),
                            child: const Icon(
                              Icons.sticky_note_2_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: AppTypography.bodyBold.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _open
                                      ? 'Tocca per chiudere'
                                      : 'Tocca per leggere',
                                  style: AppTypography.body.copyWith(
                                    color: Colors.white.withAlpha(210),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: _open ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: Colors.white.withAlpha(235),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _open
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 1,
                            color: Colors.white.withAlpha(46),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            child: Text(
                              widget.note,
                              style: AppTypography.body.copyWith(
                                color: Colors.white.withAlpha(242),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
