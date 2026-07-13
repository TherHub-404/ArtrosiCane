import 'dart:io';

import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';

class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.name,
    required this.breed,
    this.subtitle,
    this.showWarning = false,
    this.age,
    this.weight,
    this.arthrosisGrade,
    required this.imagePath,
    required this.backgroundColor,
    this.onTap,
    this.onDiaryTap,
  });

  static const double cardHeight = 392;

  final String name;
  final String breed;
  final String? subtitle;
  final bool showWarning;
  final double? age;
  final double? weight;
  final String? arthrosisGrade;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onDiaryTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 300,
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: AppColors.ctaApricot.withValues(alpha: 0.18),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 6,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.ctaApricot, Color(0xFFFFF2E0)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),
              ),
              // Pet Image (Top half)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 236,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: _PetImage(imagePath: imagePath),
                ),
              ),
              // Wave-shaped white border overlay
              Positioned(
                top: 200,
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      24,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTypography.bodyBold.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontSize: 24,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showWarning)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.text(breed),
                          style: AppTypography.body.copyWith(
                            color: AppColors.primaryBlue.withValues(alpha: 0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (arthrosisGrade != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(
                                arthrosisGrade!,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getGradeColor(
                                  arthrosisGrade!,
                                ).withValues(alpha: 0.28),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getGradeColor(arthrosisGrade!),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.l10n.text('Rischio artrosi'),
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.primaryBlue.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.35,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Text(
                                    _displayGradeLabel(
                                      context,
                                      arthrosisGrade!,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyBold.copyWith(
                                      color: _getGradeColor(arthrosisGrade!),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Age and Weight Row
                        Row(
                          children: [
                            if (age != null) ...[
                              Icon(
                                Icons.cake_outlined,
                                size: 16,
                                color: AppColors.ctaApricot.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.text('{{age}} anni', {
                                  'age': age!.toStringAsFixed(0),
                                }),
                                style: AppTypography.body.copyWith(
                                  color: AppColors.text.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (weight != null) ...[
                              Icon(
                                Icons.monitor_weight_outlined,
                                size: 16,
                                color: AppColors.ctaApricot.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${weight!.toStringAsFixed(1)} kg',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.text.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onDiaryTap != null)
                Positioned(
                  top: 18,
                  right: 18,
                  child: _DiaryActionChip(petName: name, onTap: onDiaryTap!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('grave') ||
        normalized.contains('alto') ||
        normalized.contains('high') ||
        normalized.contains('élevé') ||
        normalized.contains('hohes') ||
        normalized.contains('hoch')) {
      return Colors.red.shade500;
    } else if (normalized.contains('lieve') ||
        normalized.contains('medio') ||
        normalized.contains('medium') ||
        normalized.contains('moyen') ||
        normalized.contains('mittel')) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green.shade600;
    }
  }

  String _displayGradeLabel(BuildContext context, String grade) {
    final normalized = grade.trim().toLowerCase();
    if (normalized.contains('alto') ||
        normalized.contains('grave') ||
        normalized.contains('high') ||
        normalized.contains('élevé') ||
        normalized.contains('hohes') ||
        normalized.contains('hoch')) {
      return context.l10n.text('Alto');
    }
    if (normalized.contains('medio') ||
        normalized.contains('lieve') ||
        normalized.contains('medium') ||
        normalized.contains('moyen') ||
        normalized.contains('mittel')) {
      return context.l10n.text('Medio');
    }
    if (normalized.contains('basso') ||
        normalized.contains('nessun') ||
        normalized.contains('low') ||
        normalized.contains('faible') ||
        normalized.contains('niedrig')) {
      return context.l10n.text('Basso');
    }
    return grade.trim();
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from top-left with wave
    path.moveTo(0, 20);

    // Create smooth wave using quadratic bezier curves
    path.quadraticBezierTo(
      size.width * 0.25,
      0, // Control point
      size.width * 0.5,
      10, // End point
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      20, // Control point
      size.width,
      10, // End point
    );

    // Complete the rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _PetImage extends StatelessWidget {
  const _PetImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');
    final placeholder = Container(
      color: AppColors.background,
      child: const Icon(Icons.pets, size: 64, color: AppColors.ctaApricot),
    );

    if (isNetwork) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: const Alignment(0, 0.22),
        errorBuilder: (context, error, stackTrace) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.ctaApricot,
              ),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
      );
    }

    final localImage = File(imagePath);
    if (localImage.existsSync()) {
      return Image.file(
        localImage,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: const Alignment(0, 0.22),
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.asset(
      imagePath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: const Alignment(0, 0.22),
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

class _DiaryActionChip extends StatelessWidget {
  const _DiaryActionChip({required this.petName, required this.onTap});

  final String petName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.text('Apri diario di {{dogName}}', {
        'dogName': petName,
      }),
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        child: InkWell(
          key: ValueKey('pet-card-diary-$petName'),
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: AppColors.ctaApricot,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.text('Diario'),
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
