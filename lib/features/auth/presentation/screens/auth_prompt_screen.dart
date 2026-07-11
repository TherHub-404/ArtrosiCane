import 'package:artrosi_cane/core/providers/preferences_data_source_provider.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/auth/data/auth_repository.dart';
import 'package:artrosi_cane/features/onboarding/data/repositories/dog_supabase_repository.dart';
import 'package:artrosi_cane/features/onboarding/domain/entities/dog_profile.dart';
import 'package:artrosi_cane/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:artrosi_cane/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:artrosi_cane/theme/app_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPromptScreen extends ConsumerStatefulWidget {
  const AuthPromptScreen({
    super.key,
    this.entryContext,
    this.dogData,
    this.startInLoginMode = false,
  });

  final String? entryContext;
  final Map<String, dynamic>? dogData;
  final bool startInLoginMode;

  @override
  ConsumerState<AuthPromptScreen> createState() => _AuthPromptScreenState();
}

class _AuthPromptScreenState extends ConsumerState<AuthPromptScreen> {
  late bool _isLogin = widget.startInLoginMode;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  _AuthNotice? _bannerNotice;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  String _t(String key, [Map<String, String> params = const {}]) =>
      AppLocalizations.of(context).text(key, params);

  @override
  void initState() {
    super.initState();
    if (widget.entryContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _trackAuthContextEvent(
          'auth_prompt_viewed',
          payload: {'entryContext': widget.entryContext},
        );
      });
    }
  }

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
      _showNotice(
        _AuthNotice(
          title: _t('Campi mancanti'),
          message: _t('Inserisci email e password per continuare.'),
          tone: _AuthNoticeTone.error,
        ),
      );
      return;
    }
    if (!_isLogin && nickname.isEmpty) {
      _showNotice(
        _AuthNotice(
          title: _t('Manca il nickname'),
          message: _t(
            'Inserisci almeno un nickname per creare il tuo account.',
          ),
          tone: _AuthNoticeTone.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _bannerNotice = null;
    });
    try {
      await _trackAuthContextEvent(
        'auth_submit_attempt',
        payload: {'entryContext': widget.entryContext, 'isLogin': _isLogin},
      );
      final authRepo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await authRepo.signIn(email: email, password: password);

        // Check is_web_migrated immediately after auth, before any local
        // sync. Web-migrated users already have a profile on Supabase
        // (populated by the marketing website), so any onboarding data
        // collected locally before login must be discarded — never pushed
        // over the existing server profile. The migrated profile will be
        // hydrated into the local cache by EntryScreen after the user sets
        // a permanent password.
        final needsPasswordChange = await authRepo.isCurrentUserWebMigrated();
        if (needsPasswordChange) {
          await _resetLocalDataIfUserChanged(forceReset: true);
          await _trackAuthContextEvent(
            'auth_submit_success',
            payload: {'entryContext': widget.entryContext, 'isLogin': true},
          );
          if (mounted) {
            context.go('/change-temp-password');
          }
          return;
        }

        await _handlePostAuthState(authRepo);
        await _syncDogProfileToRemote();
        await _trackAuthContextEvent(
          'auth_submit_success',
          payload: {'entryContext': widget.entryContext, 'isLogin': true},
        );
        if (mounted) {
          context.go('/entry', extra: {'dog': widget.dogData});
        }
      } else {
        await authRepo.signUp(
          email: email,
          password: password,
          nickname: nickname,
        );
        await _handlePostAuthState(authRepo);
        await _syncDogProfileToRemote();
        await _trackAuthContextEvent(
          'auth_submit_success',
          payload: {'entryContext': widget.entryContext, 'isLogin': false},
        );
        if (mounted) {
          context.go('/entry', extra: {'dog': widget.dogData});
        }
      }
    } on AuthException catch (e) {
      _showNotice(_friendlyAuthNotice(e, isLogin: _isLogin));
    } catch (e) {
      _showNotice(
        _genericUnexpectedNotice(details: kDebugMode ? e.toString() : null),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _trackAuthContextEvent(
    String eventName, {
    Map<String, dynamic> payload = const {},
  }) async {
    if (widget.entryContext == null) return;
    try {
      await ref
          .read(preferencesDataSourceProvider)
          .appendOnboardingEvent(eventName: eventName, payload: payload);
    } catch (_) {
      // Ignore local telemetry errors.
    }

    await ref
        .read(quizRemoteDataSourceProvider)
        .saveOnboardingEvent(eventName: eventName, payload: payload);
  }

  void _showNotice(_AuthNotice notice, {bool persistInBanner = true}) {
    if (persistInBanner && mounted) {
      setState(() => _bannerNotice = notice);
    }
    _showPopupNotice(notice);
  }

  void _showPopupNotice(_AuthNotice notice) {
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
          content: _AuthNoticeCard(notice: notice, compact: true),
        ),
      );
  }

  Future<void> _handlePostAuthState(AuthRepository authRepo) async {
    final didFreshStart = authRepo.consumeFreshStartFlag();
    final preservedProfile = didFreshStart
        ? await _loadCurrentOnboardingProfileForFreshStart()
        : null;
    final preservedLastResult = didFreshStart && widget.dogData != null
        ? await ref.read(preferencesDataSourceProvider).loadLastResult()
        : null;

    await _resetLocalDataIfUserChanged(forceReset: didFreshStart);
    if (!didFreshStart) return;

    if (preservedProfile != null) {
      await ref
          .read(saveDogProfileUseCaseProvider)
          .call(preservedProfile.copyWith(id: null));
    }
    if (preservedLastResult != null) {
      await ref
          .read(preferencesDataSourceProvider)
          .saveLastResult(preservedLastResult);
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      'postAuthInfoMessage',
      _t(
        'Account precedente eliminato. Abbiamo creato un nuovo profilo pulito.',
      ),
    );
  }

  Future<DogProfile?> _loadCurrentOnboardingProfileForFreshStart() async {
    if (widget.dogData == null) return null;

    final savedProfile = await ref.read(loadDogProfileUseCaseProvider).call();
    if (savedProfile != null && (savedProfile.name ?? '').trim().isNotEmpty) {
      return savedProfile;
    }

    return _profileFromDogData(widget.dogData!);
  }

  DogProfile? _profileFromDogData(Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final breedName =
        (data['breed'] as String?)?.trim() ??
        (data['breedName'] as String?)?.trim();

    return DogProfile(
      id: data['id'] as String?,
      name: name,
      ageYears:
          (data['age'] as num?)?.toDouble() ??
          (data['ageYears'] as num?)?.toDouble(),
      weightKg:
          (data['weight'] as num?)?.toDouble() ??
          (data['weightKg'] as num?)?.toDouble(),
      breedId: (data['breedId'] as String?)?.trim(),
      breedName: breedName,
      breedImageUrl:
          (data['imagePath'] as String?) ?? (data['breedImageUrl'] as String?),
      riskLevel: (data['riskLevel'] as String?)?.trim(),
      riskScore: data['riskScore'] as int?,
      diagnosisStatus: _parseDiagnosisStatus(data['diagnosisStatus']),
    );
  }

  ArthrosisDiagnosisStatus? _parseDiagnosisStatus(dynamic rawStatus) {
    final normalized = rawStatus?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final status in ArthrosisDiagnosisStatus.values) {
      if (status.name == normalized) return status;
    }
    return null;
  }

  Future<void> _syncDogProfileToRemote() async {
    try {
      final loadProfile = ref.read(loadDogProfileUseCaseProvider);
      var profile = await loadProfile.call();
      if (profile == null) return;
      final repository = ref.read(dogSupabaseRepositoryProvider);
      profile = await repository.resolvePendingDiagnosisFiles(profile);
      await ref.read(saveDogProfileUseCaseProvider).call(profile);
      final id = await repository.upsertDog(profile);
      await ref
          .read(saveDogProfileUseCaseProvider)
          .call(profile.copyWith(id: id ?? profile.id));
    } catch (_) {
      // non blocking sync
    }
  }

  _AuthNotice _friendlyAuthNotice(AuthException e, {required bool isLogin}) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('credenziali non valide')) {
      return _AuthNotice(
        title: _t('Credenziali non corrette'),
        message: _t('Controlla email e password e riprova.'),
        tone: _AuthNoticeTone.error,
      );
    }
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user already registered') ||
        msg.contains('already exists')) {
      return _AuthNotice(
        title: _t('Account già esistente'),
        message: isLogin
            ? _t(
                'Questo account esiste già. Prova ad accedere con la password.',
              )
            : _t(
                'Esiste già un account con questa email. Prova ad accedere invece di registrarti.',
              ),
        tone: _AuthNoticeTone.info,
      );
    }
    if (msg.contains('password should be at least') ||
        msg.contains('password is too weak') ||
        msg.contains('weak password')) {
      return _AuthNotice(
        title: _t('Password troppo debole'),
        message: _t(
          'Usa una password più sicura, con almeno 6 caratteri, per completare la registrazione.',
        ),
        tone: _AuthNoticeTone.error,
      );
    }
    if (msg.contains('too many requests') ||
        msg.contains('rate limit') ||
        msg.contains('over_email_send_rate_limit') ||
        msg.contains('security purposes')) {
      return _AuthNotice(
        title: _t('Troppi tentativi'),
        message: _t(
          'Hai fatto diversi tentativi in poco tempo. Aspetta qualche minuto e riprova.',
        ),
        tone: _AuthNoticeTone.info,
      );
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return _AuthNotice(
        title: _t('Connessione assente'),
        message: _t(
          'Sembra esserci un problema di rete. Controlla la connessione e riprova.',
        ),
        tone: _AuthNoticeTone.error,
      );
    }
    if (msg.contains('annullato')) {
      return _AuthNotice(
        title: _t('Operazione annullata'),
        message: _t('Nessun problema, puoi riprovare quando vuoi.'),
        tone: _AuthNoticeTone.info,
      );
    }
    if (msg.contains('accesso apple non riuscito') ||
        msg.contains('accesso apple non disponibile') ||
        msg.contains('accesso apple non supportato')) {
      return _AuthNotice(
        title: _t('Apple Login non disponibile'),
        message: _t(
          'Su questo simulatore potrebbe non funzionare. Prova da un iPhone reale e controlla la capability "Sign In with Apple" in Xcode.',
        ),
        tone: _AuthNoticeTone.info,
      );
    }
    if (msg.contains('accesso google fallito') ||
        msg.contains('token google non disponibile') ||
        msg.contains('accesso google non disponibile') ||
        msg.contains('accesso google non riuscito')) {
      return _AuthNotice(
        title: _t('Google Login non disponibile'),
        message: e.message,
        tone: _AuthNoticeTone.error,
        debugDetails: kDebugMode ? e.message : null,
      );
    }
    return _AuthNotice(
      title: isLogin
          ? _t('Accesso non riuscito')
          : _t('Registrazione non riuscita'),
      message: isLogin
          ? _t('Non siamo riusciti a completare l\'accesso. Riprova tra poco.')
          : _t('Non siamo riusciti a creare l\'account. Riprova tra poco.'),
      tone: _AuthNoticeTone.error,
      debugDetails: kDebugMode ? e.message : null,
    );
  }

  _AuthNotice _genericUnexpectedNotice({String? details}) {
    return _AuthNotice(
      title: _t('Qualcosa non va'),
      message: _t('Si è verificato un problema inatteso. Riprova tra poco.'),
      tone: _AuthNoticeTone.error,
      debugDetails: details,
    );
  }

  String _contextHeadline() {
    switch (widget.entryContext) {
      case 'videocall':
        return _t('Sblocca la videocall iniziale');
      case 'percorso_annuale':
        return _t('Attiva il Percorso Annuale');
      case 'autonomia':
        return _t('Login');
      default:
        return _isLogin ? _t('Bentornato!') : _t('Benvenuto!');
    }
  }

  String _contextSubtitle() {
    switch (widget.entryContext) {
      case 'videocall':
        return _t(
          'Accedi per prenotare la prima videocall e salvare la tua mappa priorita.',
        );
      case 'percorso_annuale':
        return _t(
          'Accedi per iniziare il piano personalizzato con check periodici.',
        );
      case 'autonomia':
        return _t(
          'Accedi per conservare progressi e consigli personalizzati nel tempo.',
        );
      default:
        return _isLogin
            ? _t('Accedi per continuare a gestire l\'artrosi del tuo cane.')
            : _t(
                'Registra un profilo per iniziare a gestire l\'artrosi del tuo cane.',
              );
    }
  }

  Future<void> _resetLocalDataIfUserChanged({bool forceReset = false}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    final lastUserId = prefs.getString('lastUserId');
    if (forceReset || (lastUserId != null && lastUserId != currentUserId)) {
      await prefs.remove('onboardingCompleted');
      await prefs.remove('dogProfile');
      await prefs.remove('quizProgress');
      await prefs.remove('lastResult');
      await prefs.remove('lastResultSyncedSignature');
    }
    await prefs.setString('lastUserId', currentUserId);
  }

  Future<void> _signInWithGoogle() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
      await _handlePostAuthState(authRepo);
      await _syncDogProfileToRemote();
      if (mounted) context.go('/entry', extra: {'dog': widget.dogData});
    } on AuthException catch (e) {
      _showNotice(_friendlyAuthNotice(e, isLogin: true));
    } catch (e) {
      _showNotice(
        _genericUnexpectedNotice(details: kDebugMode ? e.toString() : null),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signInWithApple() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithApple();
      await _handlePostAuthState(authRepo);
      await _syncDogProfileToRemote();
      if (mounted) context.go('/entry', extra: {'dog': widget.dogData});
    } on AuthException catch (e) {
      _showNotice(_friendlyAuthNotice(e, isLogin: true));
    } catch (e) {
      _showNotice(
        _genericUnexpectedNotice(details: kDebugMode ? e.toString() : null),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                        child: _AuthNoticeCard(
                          notice: _bannerNotice!,
                          onClose: () => setState(() => _bannerNotice = null),
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
                      _contextHeadline(),
                      align: TextAlign.center,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppText.body(
                      _contextSubtitle(),
                      align: TextAlign.center,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (!_isLogin) ...[
                      _buildTextField(
                        controller: _nicknameController,
                        hint: _t('Nickname'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildTextField(
                      controller: _emailController,
                      hint: _t('Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _passwordController,
                      hint: _t('Password'),
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
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Haptics.strong();
                              _submit();
                            },
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
                            ? _t('ATTENDERE...')
                            : _isLogin
                            ? _t('ACCEDI')
                            : _t('REGISTRATI'),
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
                        Haptics.tap();
                        setState(() {
                          _isLogin = !_isLogin;
                          _bannerNotice = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryBlue, // Blue background
                        foregroundColor: Colors.white,
                        elevation: 4,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isLogin
                            ? _t('NON HAI UN ACCOUNT? REGISTRATI')
                            : _t('HAI GIÀ UN ACCOUNT? ACCEDI'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      _t('oppure'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Google Button
              ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        Haptics.tap();
                        _signInWithGoogle();
                      },
                icon: Image.asset('assets/google_logo.png', height: 22),
                label: Text(_t('CONTINUA CON GOOGLE')),
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

              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                const SizedBox(height: AppSpacing.md),
                SignInWithAppleButton(
                  onPressed: () {
                    if (_isSubmitting) return;
                    Haptics.tap();
                    _signInWithApple();
                  },
                  style: SignInWithAppleButtonStyle.black,
                  height: 52,
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  text: _t('Continua con Apple'),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Footer
              Text(
                _t(
                  'L\'accesso è gestito da Supabase. La sessione rimane attiva per uso offline.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
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

enum _AuthNoticeTone { info, success, error }

class _AuthNotice {
  const _AuthNotice({
    required this.title,
    required this.message,
    required this.tone,
    this.debugDetails,
  });

  final String title;
  final String message;
  final _AuthNoticeTone tone;
  final String? debugDetails;
}

class _AuthNoticePalette {
  const _AuthNoticePalette({
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

class _AuthNoticeCard extends StatelessWidget {
  const _AuthNoticeCard({
    required this.notice,
    this.compact = false,
    this.onClose,
  });

  final _AuthNotice notice;
  final bool compact;
  final VoidCallback? onClose;

  _AuthNoticePalette _paletteFor(_AuthNoticeTone tone) {
    switch (tone) {
      case _AuthNoticeTone.success:
        return const _AuthNoticePalette(
          background: Color(0xFFEAF7ED),
          border: Color(0xFF6EBB7A),
          iconColor: Color(0xFF2E7D32),
          titleColor: Color(0xFF1F5A24),
          messageColor: Color(0xFF35663C),
          icon: Icons.check_circle_rounded,
        );
      case _AuthNoticeTone.info:
        return const _AuthNoticePalette(
          background: Color(0xFFEFF3FF),
          border: Color(0xFF91A6E8),
          iconColor: AppColors.primaryBlue,
          titleColor: Color(0xFF32457F),
          messageColor: Color(0xFF4B5D9E),
          icon: Icons.mark_email_read_rounded,
        );
      case _AuthNoticeTone.error:
        return const _AuthNoticePalette(
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
            if (!compact && onClose != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    color: palette.messageColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
