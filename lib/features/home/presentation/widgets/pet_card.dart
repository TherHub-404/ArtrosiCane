import 'dart:io';

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
  });

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 380,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: AppColors.ctaApricot.withOpacity(0.18),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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

              // Arthritis Grade Badge
              if (arthrosisGrade != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getGradeColor(arthrosisGrade!),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      arthrosisGrade!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Wave-shaped white border overlay
              Positioned(
                top: 214,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      30,
                      AppSpacing.lg,
                      AppSpacing.lg,
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
                          breed,
                          style: AppTypography.body.copyWith(
                            color: AppColors.primaryBlue.withOpacity(0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // Age and Weight Row
                        Row(
                          children: [
                            if (age != null) ...[
                              Icon(
                                Icons.cake_outlined,
                                size: 16,
                                color: AppColors.ctaApricot.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${age!.toStringAsFixed(0)} anni',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.text.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (weight != null) ...[
                              Icon(
                                Icons.monitor_weight_outlined,
                                size: 16,
                                color: AppColors.ctaApricot.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${weight!.toStringAsFixed(1)} kg',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.text.withOpacity(0.8),
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
            ],
          ),
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.toLowerCase().contains('grave') ||
        grade.toLowerCase().contains('alto')) {
      return Colors.red.shade400;
    } else if (grade.toLowerCase().contains('lieve') ||
        grade.toLowerCase().contains('medio')) {
      return Colors.orange.shade400;
    } else {
      return Colors.green.shade400;
    }
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
