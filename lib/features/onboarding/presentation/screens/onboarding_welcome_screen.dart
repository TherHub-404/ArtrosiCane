import 'dart:async';

import 'package:artrosi_cane/core/linking/feature_flags_controller.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState
    extends ConsumerState<OnboardingWelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _starting = false;
  late final AnimationController _pawSpinController;
  final Completer<void> _pawLoadedCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    _pawSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precarica il cane per evitare micro-lag al primo frame della transizione.
    precacheImage(const AssetImage('assets/first-dog.png'), context);
  }

  @override
  void dispose() {
    _pawSpinController.dispose();
    super.dispose();
  }

  Future<void> _handleStartPressed() async {
    if (_starting) return;
    setState(() => _starting = true);

    // Attende che la Lottie sia pronta, evitando transizioni scattose.
    await _pawLoadedCompleter.future.timeout(
      const Duration(milliseconds: 900),
      onTimeout: () {},
    );

    // Due giri completi della Lottie prima di entrare nel quiz.
    await _pawSpinController.forward(from: 0);
    await _pawSpinController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    context.go('/quiz');
  }

  @override
  Widget build(BuildContext context) {
    final inviteLocation = ref.watch(
      featureFlagsControllerProvider.select((state) => state.inviteLocation),
    );
    final showVacationCopy =
        inviteLocation == 'bibbione' || inviteLocation == 'bibione';
    final subtitle = showVacationCopy
        ? 'Ti aiutiamo a proteggere le articolazioni del tuo cane in vacanza'
        : 'Ti aiutiamo a proteggere le articolazioni del tuo cane';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: AppColors.ctaApricot),
                  ),
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _WelcomeWaveClipper(),
                      child: const ColoredBox(color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(
                              alpha: 0.16,
                            ),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/ArtrosiCane-Logo.png',
                          width: 190,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.ctaApricot,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _starting
                        ? SizedBox.expand(
                            key: const ValueKey('welcome-loading'),
                            child: FractionallySizedBox(
                              widthFactor: 0.95,
                              heightFactor: 0.95,
                              child: Lottie.asset(
                                'assets/paw.json',
                                controller: _pawSpinController,
                                fit: BoxFit.contain,
                                repeat: false,
                                onLoaded: (composition) {
                                  _pawSpinController.duration =
                                      composition.duration;
                                  if (!_pawLoadedCompleter.isCompleted) {
                                    _pawLoadedCompleter.complete();
                                  }
                                },
                              ),
                            ),
                          )
                        : Column(
                            key: const ValueKey('welcome-content'),
                            children: [
                              const Text(
                                '30 secondi per capire\ncome muoversi oggi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 34,
                                  height: 1.1,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Transform.translate(
                                    offset: const Offset(0, -26),
                                    child: Image.asset(
                                      'assets/first-dog.png',
                                      width: 308,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleStartPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Inizia',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 52);
    path.cubicTo(
      size.width * 0.25,
      size.height + 6,
      size.width * 0.72,
      size.height - 82,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
