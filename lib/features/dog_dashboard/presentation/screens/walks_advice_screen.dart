import 'dart:ui' show ImageFilter;

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
    final category = _riskCategory(grade);
    final advice = _walkDetails(category);

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Passeggiate per $dogName',
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
                      Color.lerp(AppColors.ctaApricot, Colors.white, 0.22)!,
                      AppColors.ctaApricot,
                      Color.lerp(AppColors.ctaApricot, Colors.black, 0.10)!,
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
                        'Durata',
                        style: AppTypography.bodyBold.copyWith(
                          fontSize: 12,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        advice.duration,
                        style: AppTypography.bodyBold.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
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
                        ...advice.points
                            .sublist(1)
                            .map(
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
              final recommendedCard = _buildSurfaceCard(
                title: 'Superfici consigliate',
                items: advice.surfaces,
                accentColor: AppColors.primaryBlue,
                headerEmoji: '🌿',
                minHeight: 200,
                itemTextSize: 13,
                titleTextSize: 15,
              );
              final avoidCard = _buildSurfaceCard(
                title: 'Superfici da evitare / limitare',
                items: advice.surfacesLimit,
                accentColor: Colors.orange.shade800,
                headerEmoji: '🚫',
                minHeight: 200,
                itemTextSize: 13,
                titleTextSize: 15,
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
          if (advice.note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _NotesDisclosure(
              title: 'Note',
              note: advice.note,
              accentColor: AppColors.primaryBlue,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _NearbyWalksCtaButton(dogName: dogName, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSurfaceCard({
    required String title,
    required List<String> items,
    required Color accentColor,
    required String headerEmoji,
    double? minHeight,
    double? itemTextSize,
    double? titleTextSize,
  }) {
    final safeItems = items.isEmpty ? const ['Nessuna in particolare'] : items;
    final itemSize = itemTextSize ?? 14.5;
    final titleSize = titleTextSize ?? 16;

    final headerBg = Color.lerp(accentColor, Colors.white, 0.78)!;
    final cardTop = Color.lerp(accentColor, Colors.white, 0.90)!;
    final cardBottom = Color.lerp(accentColor, Colors.white, 0.97)!;
    const radius = BorderRadius.all(Radius.circular(20));

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Colors.white.withAlpha(120)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
              gradient: LinearGradient(
                colors: [cardTop, cardBottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: headerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(120)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        headerEmoji,
                        style: const TextStyle(fontSize: 18, height: 1),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodyBold.copyWith(
                          color: accentColor,
                          fontSize: titleSize,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...safeItems.map((raw) {
                  final label = _cleanSurfaceLabel(raw);
                  final emoji = _surfaceEmoji(label);
                  final itemBg = Color.lerp(accentColor, Colors.white, 0.92)!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withAlpha(30)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(210),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accentColor.withAlpha(28),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
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
                                fontSize: itemSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cleanSurfaceLabel(String text) {
    final noEmoji = text
        .replaceAll(RegExp(r'\p{Extended_Pictographic}', unicode: true), '')
        .replaceAll('\uFE0F', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return noEmoji.isEmpty ? text.trim() : noEmoji;
  }

  String _stripObjectivePrefix(String text) {
    final lower = text.toLowerCase();
    if (lower.startsWith('obiettivo:')) {
      return text.substring(10).trim();
    }
    return text;
  }

  String _surfaceEmoji(String label) {
    final normalized = label.toLowerCase();
    if (normalized.startsWith('nessun')) return '🎉';
    if (normalized.contains('prato')) return '🌱';
    if (normalized.contains('asfalto')) return '🛣️';
    if (normalized.contains('sabbia')) return '🏖️';
    if (normalized.contains('sterrat')) {
      if (normalized.contains('irregolar')) return '🪨';
      return '🥾';
    }
    return '🏞️';
  }

  _RiskCategory _riskCategory(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('grave') || normalized.contains('alto')) {
      return _RiskCategory.severe;
    }
    if (normalized.contains('lieve') || normalized.contains('medio')) {
      return _RiskCategory.mild;
    }
    if (normalized.contains('nessun') || normalized.contains('basso')) {
      return _RiskCategory.none;
    }
    return _RiskCategory.unknown;
  }

  _WalkAdvice _walkDetails(_RiskCategory category) {
    switch (category) {
      case _RiskCategory.none:
        return _WalkAdvice(
          title: 'Nessun segno di artrosi',
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
          title: 'Artrosi lieve',
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
          title: 'Artrosi avanzata',
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
          title: 'Fai il test per consigli mirati',
          duration: '-',
          points: [
            'Completa il test artrosi per vedere le passeggiate consigliate.',
          ],
          surfaces: [],
          surfacesLimit: [],
          accentColor: AppColors.primaryBlue,
          note: '',
        );
    }
  }
}

class _NearbyWalksCtaButton extends StatelessWidget {
  const _NearbyWalksCtaButton({required this.dogName, required this.onTap});

  final String dogName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const base = AppColors.ctaApricot;
    final light = Color.lerp(base, Colors.white, 0.22)!;
    final dark = Color.lerp(base, Colors.black, 0.10)!;
    const radius = BorderRadius.all(Radius.circular(18));

    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        label: 'Scopri passeggiate vicine per $dogName',
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [light, base, dark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(46),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(56),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(71)),
                      ),
                      child: const Icon(
                        Icons.near_me_rounded,
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
                            'Scopri passeggiate vicine',
                            style: AppTypography.bodyBold.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Per $dogName nella tua zona',
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withAlpha(235),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(56),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final glassTop = Colors.white.withAlpha(56);
    final glassBottom = Colors.white.withAlpha(28);

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
            border: Border.all(color: Colors.white.withAlpha(77)),
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
