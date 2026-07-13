import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/auth/data/auth_repository.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeTempPasswordScreen extends ConsumerStatefulWidget {
  const ChangeTempPasswordScreen({super.key});

  @override
  ConsumerState<ChangeTempPasswordScreen> createState() =>
      _ChangeTempPasswordScreenState();
}

class _ChangeTempPasswordScreenState
    extends ConsumerState<ChangeTempPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isSubmitting = false;
  _ChangePwdNotice? _bannerNotice;

  String _t(String key, [Map<String, String> params = const {}]) =>
      AppLocalizations.of(context).text(key, params);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showNotice(
        _ChangePwdNotice(
          title: _t('Campi mancanti'),
          message: _t('Inserisci e conferma la nuova password.'),
          tone: _ChangePwdNoticeTone.error,
        ),
      );
      return;
    }
    if (password.length < 6) {
      _showNotice(
        _ChangePwdNotice(
          title: _t('Password troppo corta'),
          message: _t('Usa almeno 6 caratteri per la nuova password.'),
          tone: _ChangePwdNoticeTone.error,
        ),
      );
      return;
    }
    if (password != confirm) {
      _showNotice(
        _ChangePwdNotice(
          title: _t('Le password non coincidono'),
          message: _t(
            'Riscrivi la stessa password nei due campi per continuare.',
          ),
          tone: _ChangePwdNoticeTone.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _bannerNotice = null;
    });
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.finalizeMigratedPassword(newPassword: password);
      if (!mounted) return;
      // Intentionally no dog data: the user's profile lives on Supabase
      // (web-migrated) and EntryScreen hydrates the local cache from there.
      context.go('/entry');
    } on AuthException catch (e) {
      _showNotice(_friendlyNotice(e));
    } catch (e) {
      _showNotice(
        _ChangePwdNotice(
          title: _t('Qualcosa non va'),
          message: _t(
            'Non siamo riusciti ad aggiornare la password. Riprova tra poco.',
          ),
          tone: _ChangePwdNoticeTone.error,
          debugDetails: kDebugMode ? e.toString() : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  _ChangePwdNotice _friendlyNotice(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('password should be at least') ||
        msg.contains('password is too weak') ||
        msg.contains('weak password')) {
      return _ChangePwdNotice(
        title: _t('Password troppo debole'),
        message: _t('Scegli una password più sicura, con almeno 6 caratteri.'),
        tone: _ChangePwdNoticeTone.error,
      );
    }
    if (msg.contains('same password') ||
        msg.contains('new password should be different')) {
      return _ChangePwdNotice(
        title: _t('Password già in uso'),
        message: _t('La nuova password deve essere diversa da quella attuale.'),
        tone: _ChangePwdNoticeTone.error,
      );
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('timeout') ||
        msg.contains('connection')) {
      return _ChangePwdNotice(
        title: _t('Connessione assente'),
        message: _t(
          'Sembra esserci un problema di rete. Controlla la connessione e riprova.',
        ),
        tone: _ChangePwdNoticeTone.error,
      );
    }
    return _ChangePwdNotice(
      title: _t('Aggiornamento non riuscito'),
      message: _t(
        'Non siamo riusciti ad aggiornare la password. Riprova tra poco.',
      ),
      tone: _ChangePwdNoticeTone.error,
      debugDetails: kDebugMode ? e.message : null,
    );
  }

  void _showNotice(_ChangePwdNotice notice) {
    if (mounted) setState(() => _bannerNotice = notice);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          padding: EdgeInsets.zero,
          content: _ChangePwdNoticeCard(notice: notice, compact: true),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.ctaApricot,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                child: _bannerNotice == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(
                          '${_bannerNotice!.title}-${_bannerNotice!.message}',
                        ),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ChangePwdNoticeCard(notice: _bannerNotice!),
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText.h1(
                      _t('Imposta la tua password'),
                      align: TextAlign.center,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppText.body(
                      _t(
                        'Hai effettuato l\'accesso con una password temporanea. Scegli ora una password definitiva per il tuo account.',
                      ),
                      align: TextAlign.center,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTextField(
                      controller: _passwordController,
                      hint: _t('Nuova password'),
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _confirmController,
                      hint: _t('Conferma nuova password'),
                      isPassword: true,
                      isPasswordVisible: _isConfirmVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isConfirmVisible = !_isConfirmVisible;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _t('Almeno 6 caratteri.'),
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Haptics.strong();
                              _submit();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isSubmitting
                            ? _t('ATTENDERE...')
                            : _t('SALVA PASSWORD'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0,
                          fontFamily: 'Anton',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _t(
                  'Questo passaggio serve solo questa volta: al prossimo accesso userai la nuova password.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.text.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.text.withValues(alpha: 0.5),
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
        ),
      ),
    );
  }
}

enum _ChangePwdNoticeTone { info, success, error }

class _ChangePwdNotice {
  const _ChangePwdNotice({
    required this.title,
    required this.message,
    required this.tone,
    this.debugDetails,
  });

  final String title;
  final String message;
  final _ChangePwdNoticeTone tone;
  final String? debugDetails;
}

class _ChangePwdNoticePalette {
  const _ChangePwdNoticePalette({
    required this.background,
    required this.border,
    required this.iconColor,
    required this.titleColor,
    required this.messageColor,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color iconColor;
  final Color titleColor;
  final Color messageColor;
  final IconData icon;
}

class _ChangePwdNoticeCard extends StatelessWidget {
  const _ChangePwdNoticeCard({required this.notice, this.compact = false});

  final _ChangePwdNotice notice;
  final bool compact;

  _ChangePwdNoticePalette _paletteFor(_ChangePwdNoticeTone tone) {
    switch (tone) {
      case _ChangePwdNoticeTone.success:
        return const _ChangePwdNoticePalette(
          background: Color(0xFFEAF7ED),
          border: Color(0xFF6EBB7A),
          iconColor: Color(0xFF2E7D32),
          titleColor: Color(0xFF1F5A24),
          messageColor: Color(0xFF35663C),
          icon: Icons.check_circle_rounded,
        );
      case _ChangePwdNoticeTone.info:
        return const _ChangePwdNoticePalette(
          background: Color(0xFFEFF3FF),
          border: Color(0xFF91A6E8),
          iconColor: AppColors.primaryBlue,
          titleColor: Color(0xFF32457F),
          messageColor: Color(0xFF4B5D9E),
          icon: Icons.lock_reset_rounded,
        );
      case _ChangePwdNoticeTone.error:
        return const _ChangePwdNoticePalette(
          background: Color(0xFFFFF1EE),
          border: Color(0xFFFFB3A7),
          iconColor: Color(0xFFD24B34),
          titleColor: Color(0xFF9D2F20),
          messageColor: Color(0xFF7A3026),
          icon: Icons.error_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(notice.tone);

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(compact ? 24 : 22),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: compact ? 0.12 : 0.08),
            blurRadius: compact ? 20 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 18,
          vertical: compact ? 14 : 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 36 : 40,
              height: compact ? 36 : 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
              child: Icon(palette.icon, color: palette.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: TextStyle(
                      color: palette.titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 14 : 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notice.message,
                    style: TextStyle(
                      color: palette.messageColor,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 12.5 : 13.5,
                      height: 1.35,
                    ),
                  ),
                  if (notice.debugDetails != null &&
                      notice.debugDetails!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notice.debugDetails!,
                      style: TextStyle(
                        color: palette.messageColor.withValues(alpha: 0.78),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
