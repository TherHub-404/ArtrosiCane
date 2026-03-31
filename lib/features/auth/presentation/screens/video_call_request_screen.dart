import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/features/auth/data/auth_repository.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _VideoCallStep { form, loading, success }

class VideoCallRequestScreen extends ConsumerStatefulWidget {
  const VideoCallRequestScreen({super.key, this.dogData});

  final Map<String, dynamic>? dogData;

  @override
  ConsumerState<VideoCallRequestScreen> createState() =>
      _VideoCallRequestScreenState();
}

class _VideoCallRequestScreenState
    extends ConsumerState<VideoCallRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  _VideoCallStep _step = _VideoCallStep.form;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _isSubmitting = true;
      _step = _VideoCallStep.loading;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .scheduleVideoCallRequest(
            firstName: _nameController.text.trim(),
            lastName: _surnameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            dogName: widget.dogData?['name']?.toString(),
          );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _step = _VideoCallStep.form;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _step = _VideoCallStep.form;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Prenotazione non riuscita. Riprova tra qualche secondo.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _step = _VideoCallStep.success;
    });
  }

  void _goBackToApp() {
    context.go('/auth');
  }

  String? _requiredValidator(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label obbligatorio';
    return null;
  }

  String? _emailValidator(String? value) {
    final required = _requiredValidator(value, 'Email');
    if (required != null) return required;
    final text = value!.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Inserisci una email valida';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final required = _requiredValidator(value, 'Numero di telefono');
    if (required != null) return required;
    final text = value!.trim();
    final phoneRegex = RegExp(r'^[0-9+\s()\-]{6,}$');
    if (!phoneRegex.hasMatch(text)) {
      return 'Inserisci un numero valido';
    }
    return null;
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.3),
      ),
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primaryBlue,
              tooltip: 'Indietro',
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Image.asset('assets/ArtrosiCane-Logo.png', width: 180),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Prenota video Call',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
                height: 1.05,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Compila i campi per ricevere una consulenza personalizzata.',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Nome'),
                    validator: (value) => _requiredValidator(value, 'Nome'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _surnameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Cognome'),
                    validator: (value) => _requiredValidator(value, 'Cognome'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phoneController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Numero di telefono (backup)'),
                    validator: _phoneValidator,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _emailController,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email'),
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Prenota',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/paw.json', width: 170),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Stiamo prenotando la tua videocall...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
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
          children: [
            Image.asset('assets/ArtrosiCane-Logo.png', width: 170),
            const SizedBox(height: AppSpacing.md),
            Image.asset('assets/first-dog.png', width: 220),
            const SizedBox(height: AppSpacing.lg),
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
                  const Text(
                    'Grazie per aver chiesto una consulenza!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Richiesta inviata con successo: l\'invito e stato '
                    'creato su Google Calendar e inviato a te e ad '
                    'adriano.monino@gmail.com.',
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
                      onPressed: _goBackToApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaApricot,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Torna all\'app',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
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
        child: switch (_step) {
          _VideoCallStep.form => _buildFormStep(),
          _VideoCallStep.loading => _buildLoadingStep(),
          _VideoCallStep.success => _buildSuccessStep(),
        },
      ),
    );
  }
}
