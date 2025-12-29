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
          'Passeggiate consigliate',
          style: AppTypography.bodyBold.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Passeggiate per $dogName',
            style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Durata',
                        style: TextStyle(fontSize: 12, color: AppColors.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        advice.duration,
                        style: AppTypography.bodyBold.copyWith(
                          color: AppColors.primaryBlue,
                          fontSize: 16,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advice.title,
                        style: AppTypography.bodyBold.copyWith(
                          color: advice.accentColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...advice.points.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: advice.accentColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildCard(
                    title: 'Superfici consigliate',
                    items: advice.surfaces,
                    accent: Colors.white,
                    titleColor: AppColors.primaryBlue,
                    chipColor: AppColors.primaryBlue,
                    textColor: AppColors.primaryBlue,
                    minHeight: 180,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildCard(
                    title: 'Evitare / limitare',
                    items: advice.surfacesLimit,
                    accent: Colors.white,
                    titleColor: Colors.orange.shade800,
                    chipColor: Colors.orange.shade800,
                    textColor: Colors.orange.shade800,
                    minHeight: 180,
                  ),
                ),
              ],
            ),
          ),
          if (advice.note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildCard(
              title: 'Note',
              items: [advice.note],
              accent: Colors.white,
              titleColor: AppColors.primaryBlue,
              chipColor: AppColors.primaryBlue,
              textColor: AppColors.text,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _NearbyWalksCtaButton(dogName: dogName, onTap: () {}),
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
                    Icon(Icons.check_circle, color: cColor, size: 18),
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
    if (normalized.contains('grave') || normalized.contains('alto'))
      return _RiskCategory.severe;
    if (normalized.contains('lieve') || normalized.contains('medio'))
      return _RiskCategory.mild;
    if (normalized.contains('nessun') || normalized.contains('basso'))
      return _RiskCategory.none;
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
            'Prato 🌱',
            'Asfalto 🛣️',
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
          surfaces: ['Prato 🌱 (migliore)', 'Sterrato regolare'],
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
          surfaces: ['Prato 🌱 (ideale)'],
          surfacesLimit: ['Asfalto', 'Sabbia', 'Sterrati irregolari'],
          accentColor: Colors.red.shade700,
          note:
              'Percorsi piatti, prevedibili e morbidi; niente dislivelli o tratti lunghi.',
        );
      case _RiskCategory.unknown:
      default:
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
