import 'package:artrosi_cane/core/widgets/app_button.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/auth/data/auth_repository.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/dog_supabase_repository.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPromptScreen extends ConsumerStatefulWidget {
  const AuthPromptScreen({super.key});

  @override
  ConsumerState<AuthPromptScreen> createState() => _AuthPromptScreenState();
}

class _AuthPromptScreenState extends ConsumerState<AuthPromptScreen> {
  bool _isLogin = false;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String? _bannerMessage;
  Color _bannerColor = AppColors.ctaApricot;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Inserisci email e password');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await authRepo.signIn(email: email, password: password);
        await _syncDogProfileToRemote();
        if (mounted) context.go('/entry');
      } else {
        final needsEmailConfirm = await authRepo.signUp(
          email: email,
          password: password,
          nickname: nickname,
        );
        if (needsEmailConfirm) {
          _setBanner(
            'Registrazione inviata. Controlla la mail e conferma l\'account, poi accedi.',
            AppColors.primaryBlue,
          );
          if (mounted) setState(() => _isLogin = true);
        } else {
          if (mounted) context.go('/entry');
        }
      }
    } on AuthException catch (e) {
      final message = _friendlyAuthMessage(e);
      _showSnack(message);
      _setBanner(message, Colors.red.shade700);
    } catch (e) {
      _showSnack('Errore: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _syncDogProfileToRemote() async {
    try {
      final loadProfile = ref.read(loadDogProfileUseCaseProvider);
      final profile = await loadProfile.call();
      if (profile == null) return;
      await ref.read(dogSupabaseRepositoryProvider).upsertDog(profile);
    } catch (_) {
      // non blocking sync
    }
  }

  void _setBanner(String message, Color color) {
    setState(() {
      _bannerMessage = message;
      _bannerColor = color;
    });
  }

  String _friendlyAuthMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('confirm') || msg.contains('confirmed')) {
      return 'Devi confermare l\'email prima di accedere. Controlla la posta e riprova.';
    }
    return e.message;
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
                duration: const Duration(milliseconds: 250),
                child: _bannerMessage == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(_bannerMessage),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _bannerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _bannerColor, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _bannerColor == AppColors.primaryBlue ? Icons.info_outline : Icons.error_outline,
                              color: _bannerColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _bannerMessage!,
                                style: TextStyle(
                                  color: _bannerColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // White Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText.h1(
                      _isLogin ? 'Bentornato!' : 'Benvenuto!',
                      align: TextAlign.center,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppText.body(
                      _isLogin
                          ? 'Accedi per continuare a gestire l\'artrosi del tuo cane.'
                          : 'Registra un profilo per iniziare a gestire l\'artrosi del tuo cane.',
                      align: TextAlign.center,
                      color: AppColors.text.withOpacity(0.7),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (!_isLogin) ...[
                      _buildTextField(
                        controller: _nicknameController,
                        hint: 'Nickname',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Primary Button (Orange)
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        foregroundColor: Colors.white,
                        elevation: 4, // Restored elevation/shadow
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isSubmitting
                            ? 'ATTENDERE...'
                            : _isLogin
                                ? 'ACCEDI'
                                : 'REGISTRATI',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14, // Reduced from 18
                          letterSpacing: 1.0,
                          fontFamily: 'Anton',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Secondary Button (Blue)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue, // Blue background
                        foregroundColor: Colors.white,
                        elevation: 4,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isLogin ? 'NON HAI UN ACCOUNT? REGISTRATI' : 'HAI GIÀ UN ACCOUNT? ACCEDI',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11, // Reduced from 14
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Oppure Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'oppure',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Google Button
              ElevatedButton.icon(
                onPressed: () => context.go('/entry'),
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 22,
                ),
                label: const Text('CONTINUA CON GOOGLE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.text,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2, // Reduced elevation
                  textStyle: AppTypography.bodyBold,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Footer
              Text(
                'L\'accesso è gestito da Supabase. La sessione rimane attiva per uso offline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
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
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.2), // Black border
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !isPasswordVisible,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.text.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.text.withOpacity(0.5),
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
        ),
      ),
    );
  }
}
