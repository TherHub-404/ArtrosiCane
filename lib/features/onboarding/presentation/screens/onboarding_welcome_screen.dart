import 'package:artrosi_cane/core/linking/feature_flags_controller.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/core/utils/responsive.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState
    extends ConsumerState<OnboardingWelcomeScreen> {
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/dog-entry-page.png'), context);
    precacheImage(
      const AssetImage('assets/normal-dog-entry-page.jpeg'),
      context,
    );
    precacheImage(const AssetImage('assets/ArtrosiCane-Logo.png'), context);
    precacheImage(const AssetImage('assets/logo-bibione.png'), context);
  }

  void _handleStartPressed() {
    if (_starting) return;
    Haptics.tap();
    setState(() => _starting = true);
    final flagsState = ref.read(featureFlagsControllerProvider);
    final inviteLocation = flagsState.inviteLocation;
    final isBibbioneMode =
        inviteLocation == 'bibbione' || inviteLocation == 'bibione';
    if (isBibbioneMode) {
      // Bibione mode always shows the context screen next.
      context.go('/context-bibione');
      return;
    }
    // Returning, logged-in users skip the quiz and go straight home.
    final isLoggedIn =
        ref.read(supabaseClientProvider).auth.currentSession != null;
    if (isLoggedIn) {
      context.go('/home');
      return;
    }
    // Skip-onboard users bypass the quiz and land directly on the login
    // screen (pre-selected on login, not registration).
    if (flagsState.shouldSkipOnboarding) {
      context.go('/auth', extra: {'isLogin': true});
      return;
    }
    context.go('/quiz');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inviteLocation = ref.watch(
      featureFlagsControllerProvider.select((state) => state.inviteLocation),
    );
    final isBibbioneMode =
        inviteLocation == 'bibbione' || inviteLocation == 'bibione';

    final title = isBibbioneMode
        ? l10n.text('Un progetto pilota per il benessere del tuo cane in vacanza.')
        : l10n.text('Un percorso per il benessere del tuo cane, ogni giorno.');
    final subtitle = isBibbioneMode
        ? l10n.text(
            'Ti accompagniamo ogni giorno con informazioni semplici, per '
            'aiutarti a osservare, interpretare e agire nel modo giusto '
            'nella gestione quotidiana.',
          )
        : l10n.text(
            'Ti accompagniamo con contenuti semplici per osservare, capire '
            'e gestire al meglio il tuo cane nella vita quotidiana.',
          );
    final dogImageAsset = isBibbioneMode
        ? 'assets/dog-entry-page.png'
        : 'assets/normal-dog-entry-page.jpeg';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _TopSection(showBibbionePartner: isBibbioneMode),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: 56,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.ctaApricot,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Stack(
              children: [
                Image.asset(
                  dogImageAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: -1,
                  child: SizedBox(
                    height: 48,
                    child: ClipPath(
                      clipper: _TopWaveClipper(),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  child: SizedBox(
                    height: 56,
                    child: ClipPath(
                      clipper: _BottomWaveClipper(),
                      child: Container(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
            _BottomSection(
              starting: _starting,
              onStart: _handleStartPressed,
              isBibbioneMode: isBibbioneMode,
              isLoggedIn:
                  ref.read(supabaseClientProvider).auth.currentSession != null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({required this.showBibbionePartner});

  final bool showBibbionePartner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/ArtrosiCane-Logo.png',
            width: context.scaled(168),
            fit: BoxFit.contain,
          ),
          if (showBibbionePartner) ...[
            const Spacer(),
            Image.asset(
              'assets/logo-bibione.png',
              width: context.scaled(152),
              fit: BoxFit.contain,
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.starting,
    required this.onStart,
    required this.isBibbioneMode,
    required this.isLoggedIn,
  });

  final bool starting;
  final VoidCallback onStart;
  final bool isBibbioneMode;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            top: 80,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.pets, size: 160, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeatureRow(
                icon: Icons.remove_red_eye_outlined,
                circleColor: const Color(0xFF6E80BA),
                title: l10n.text('Osserva'),
                subtitle: l10n.text('Impara a riconoscere i segnali importanti.'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FeatureRow(
                icon: Icons.explore_outlined,
                circleColor: AppColors.ctaApricot,
                title: l10n.text('Interpreta'),
                subtitle: l10n.text('Capisci cosa sta dicendo il tuo cane.'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FeatureRow(
                icon: Icons.verified_user_outlined,
                circleColor: const Color(0xFF6E80BA),
                title: l10n.text('Agisci'),
                subtitle: l10n.text('Scopri i comportamenti migliori per lui.'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FeatureRow(
                icon: Icons.play_arrow_rounded,
                circleColor: AppColors.ctaApricot,
                title: l10n.text('Cresci insieme'),
                subtitle: l10n.text(
                  'Contenuti chiari e progressivi che ti accompagnano sempre.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isBibbioneMode)
                Text(
                  l10n.text(
                    'Un progetto di studio e informazione, ideato a Bibione '
                    'per accompagnarti ogni giorno, anche dopo la vacanza.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    children: [
                      TextSpan(
                        text: l10n.text(
                          'Un percorso di informazione e accompagnamento '
                          'per aiutarti a prenderti cura del tuo cane ',
                        ),
                      ),
                      TextSpan(
                        text: l10n.text('nel tempo'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: starting ? null : onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaApricot,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.ctaApricot.withValues(
                      alpha: 0.7,
                    ),
                    minimumSize: const Size.fromHeight(58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: starting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          l10n.text(
                            isLoggedIn ? 'Continua' : 'Inizia il percorso',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.45);
    path.cubicTo(
      size.width * 0.55,
      -size.height * 0.10,
      size.width * 0.22,
      size.height * 1.10,
      0,
      size.height * 0.55,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.55);
    path.cubicTo(
      size.width * 0.22,
      -size.height * 0.15,
      size.width * 0.55,
      size.height * 1.05,
      size.width,
      size.height * 0.30,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.circleColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color circleColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.scaled(48),
          height: context.scaled(48),
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: context.scaled(26)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
