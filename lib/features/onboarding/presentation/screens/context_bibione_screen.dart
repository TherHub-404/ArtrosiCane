import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/core/utils/responsive.dart';
import 'package:artrosi_cane/core/widgets/web_view_bottom_sheet.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bibione-only context screen shown between the onboarding welcome screen
/// and the quiz. Introduces the Bibione partnership and invites the user to
/// explore the Bibione web app before adding their dog.
class ContextBibioneScreen extends ConsumerStatefulWidget {
  const ContextBibioneScreen({super.key});

  @override
  ConsumerState<ContextBibioneScreen> createState() =>
      _ContextBibioneScreenState();
}

class _ContextBibioneScreenState extends ConsumerState<ContextBibioneScreen> {
  static const _bibioneWebAppUrl = 'https://discover.bibione.com/#/home';

  bool _continuing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/Marina-di-Bibbiona.jpg'), context);
  }

  Future<void> _openBibioneWebApp() async {
    await Haptics.tap();
    if (!mounted) return;
    // Open the Bibione web app inside an in-app bottom sheet rather than
    // handing the user off to an external browser.
    await showWebViewBottomSheet(
      context,
      url: Uri.parse(_bibioneWebAppUrl),
      title: context.l10n.text('Scopri Bibione'),
    );
  }

  void _handleContinue() {
    if (_continuing) return;
    Haptics.tap();
    setState(() => _continuing = true);
    // Returning, logged-in users skip the quiz and go straight home.
    final isLoggedIn =
        ref.read(supabaseClientProvider).auth.currentSession != null;
    context.go(isLoggedIn ? '/home' : '/quiz');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoggedIn =
        ref.read(supabaseClientProvider).auth.currentSession != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/ArtrosiCane-Logo.png',
                    width: context.scaled(150),
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/logo-bibione.png',
                    width: context.scaled(130),
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/Marina-di-Bibbiona.jpg',
                  height: context.scaled(240),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Container(
                  width: 56,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.ctaApricot,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.text(
                  'Bibione ama i suoi amici a quattro zampe e oggi ti '
                  'stringe la mano per proteggere insieme, con cura, la '
                  'salute del tuo cane.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 19,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.text(
                  'Esplora la web app di Bibione per scoprire servizi, '
                  'eventi e luoghi pet-friendly.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _openBibioneWebApp,
                icon: const Icon(Icons.travel_explore_rounded, size: 22),
                label: Text(l10n.text('Scopri Bibione')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _continuing ? null : _handleContinue,
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
                child: _continuing
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
                          isLoggedIn ? 'Continua' : 'Aggiungi il tuo cucciolo',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
