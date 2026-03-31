import 'dart:async';

import 'package:artrosi_cane/core/widgets/app_button.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/quiz/domain/entities/quiz_result.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key, this.result, this.dogData});

  final Object? result;
  final Map<String, dynamic>? dogData;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Simulate calculation/loading
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizResult = widget.result is QuizResult
        ? widget.result as QuizResult
        : null;
    final riskLevel = quizResult?.riskLevel ?? RiskLevel.basso;

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/ArtrosiCane-Logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Spinner
                  Lottie.asset('assets/paw.json', height: 90, repeat: true),
                  const SizedBox(height: AppSpacing.xl),

                  // Text
                  Text(
                    'Stiamo analizzando\nle risposte...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  AppText.h1('Il rischio artrosi è:', align: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),

                  // Gauge/Indicator Animation
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderSoft,
                          width: 8,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _riskLabel(riskLevel),
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    color: _riskColor(riskLevel),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat', // Requested font
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'RISCHIO',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppText.body(
                      'Continua per tenere un diario, ricevere consigli personalizzati e prevenire l\'artrosi.',
                      align: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppButton(
                      label: 'Continua',
                      onPressed: _handleContinue,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _handleContinue() {
    context.go(
      '/quiz/diagnosis-result',
      extra: {'showJourneyOnly': true, 'dog': widget.dogData},
    );
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.basso:
        return 'BASSO';
      case RiskLevel.medio:
        return 'MEDIO';
      case RiskLevel.alto:
        return 'ALTO';
    }
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.basso:
        return Colors.green;
      case RiskLevel.medio:
        return Colors.orange;
      case RiskLevel.alto:
        return Colors.red;
    }
  }
}
