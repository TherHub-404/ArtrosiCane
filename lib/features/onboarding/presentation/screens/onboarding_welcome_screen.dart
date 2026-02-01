import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  static const Duration _introVisibleDuration = Duration(seconds: 2);
  static const Duration _introFadeDuration = Duration(milliseconds: 500);
  static const int _lottieLoops = 2;

  Timer? _timer;
  Timer? _swapTimer;
  Timer? _lottieTimer;
  bool _showIntroText = true;
  bool _showLottie = false;

  void _scheduleNavigation(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (mounted) {
        context.go('/quiz');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _swapTimer = Timer(_introVisibleDuration, () {
      if (mounted) {
        setState(() => _showIntroText = false);
      }
    });
    _lottieTimer = Timer(_introVisibleDuration + _introFadeDuration, () {
      if (mounted) {
        setState(() => _showLottie = true);
      }
    });
    _scheduleNavigation(const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _swapTimer?.cancel();
    _lottieTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.ctaApricot,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final topHeight = screenHeight * 0.42;
            final lottieAreaHeight = screenHeight * 0.2;
            final dogHeight = screenHeight * 0.28;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: topHeight,
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
                        top: media.padding.top + screenHeight * 0.04,
                        child: Image.asset(
                          'assets/ArtrosiCane-Logo.png',
                          height: 170,
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
                        SizedBox(
                          height: lottieAreaHeight,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedOpacity(
                                opacity: _showIntroText ? 1 : 0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                  ],
                                ),
                              ),
                              AnimatedOpacity(
                                opacity: _showLottie ? 1 : 0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                child: Lottie.asset(
                                  'assets/paw.json',
                                  height: lottieAreaHeight,
                                  repeat: true,
                                  onLoaded: (composition) {
                                    final lottieDuration = Duration(
                                      milliseconds: composition.duration.inMilliseconds * _lottieLoops,
                                    );
                                    _scheduleNavigation(
                                      _introVisibleDuration + _introFadeDuration + lottieDuration,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: dogHeight),
                          child: Transform.translate(
                            offset: const Offset(0, -24),
                            child: Image.asset(
                              'assets/first-dog.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
