import 'package:artrosi_cane/core/widgets/app_button.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (context.mounted) {
        context.go('/quiz');
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;

    return AppScaffold(
      backgroundColor: AppColors.ctaApricot,
      padding: EdgeInsets.zero, // Remove default padding to allow full width
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: screenHeight * 0.45, // Use relative height
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipPath(
                    clipper: _BlobClipper(),
                    child: Container(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.08, // Moved up significantly
                  child: Image.asset(
                    'assets/ArtrosiCane-Logo.png',
                    height: 180, // Reduced from 280
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                   AppText.h1(
                    'Più movimento,\nmeno dolore',
                    align: TextAlign.center,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppText.body(
                    'Scopri in 10 domande quanto è esposto il tuo cane al rischio artrosi e come aiutarlo a stare meglio.',
                    align: TextAlign.center,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/first-dog.png',
                    height: screenHeight * 0.25, // Relative height for the dog image
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    
    // Create a smooth curve at the bottom
    path.quadraticBezierTo(
      size.width * 0.5, // Control point x (center)
      size.height,      // Control point y (bottom)
      size.width,       // End point x (right edge)
      size.height * 0.75 // End point y
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
