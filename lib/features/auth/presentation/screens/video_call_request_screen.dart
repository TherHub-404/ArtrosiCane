import 'package:artrosi_cane/core/linking/video_call_booking_launcher.dart';
import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class VideoCallRequestScreen extends StatefulWidget {
  const VideoCallRequestScreen({super.key, this.dogData, this.source});

  final Map<String, dynamic>? dogData;
  final String? source;

  @override
  State<VideoCallRequestScreen> createState() => _VideoCallRequestScreenState();
}

class _VideoCallRequestScreenState extends State<VideoCallRequestScreen> {
  bool _isLaunching = true;
  bool _launchFailed = false;
  bool _hasLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToCalendly();
    });
  }

  void _goBack() {
    switch (widget.source) {
      case 'onboarding_post_calculation':
        context.go(
          '/quiz/diagnosis-result',
          extra: {'showJourneyOnly': true, 'dog': widget.dogData},
        );
        return;
      case 'home_bottom_bar':
        context.go('/home');
        return;
      default:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
    }
  }

  Future<void> _redirectToCalendly() async {
    if (_hasLaunched) return;
    _hasLaunched = true;

    final opened = await VideoCallBookingLauncher.open(context);
    if (!mounted) return;

    if (opened) {
      _goBack();
      return;
    }

    setState(() {
      _hasLaunched = false;
      _isLaunching = false;
      _launchFailed = true;
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/paw.json', width: 170),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.text('Ti stiamo reindirizzando a Calendly...'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF5E9), Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/ArtrosiCane-Logo.png', width: 170),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n.text('Non siamo riusciti ad aprire Calendly'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.text(
                      'Riprova ad aprire il link della videocall. La schermata di inserimento nome e cognome non viene piu mostrata.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.text.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Haptics.strong();
                        _redirectToCalendly();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        context.l10n.text('Apri Calendly'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      Haptics.tap();
                      _goBack();
                    },
                    child: Text(context.l10n.text('Indietro')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.background,
      padding: EdgeInsets.zero,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _isLaunching && !_launchFailed
            ? _buildLoadingState()
            : _buildErrorState(),
      ),
    );
  }
}
