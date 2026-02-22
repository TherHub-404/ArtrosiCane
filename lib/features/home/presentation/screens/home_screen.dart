import 'dart:ui';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/pet_card.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/add_pet_dialog.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/delete_pet_dialog.dart';
import 'package:artrosi_cane/features/home/data/monthly_sentence_repository.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/core/providers/supabase_provider.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSpeedDialOpen = false;
  late AnimationController _speedDialController;
  late Animation<double> _speedDialAnimation;

  @override
  void initState() {
    super.initState();
    _speedDialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _speedDialAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _speedDialController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _speedDialController.forward();
      } else {
        _speedDialController.reverse();
      }
    });
  }

  void _closeSpeedDial() {
    if (_isSpeedDialOpen) {
      setState(() {
        _isSpeedDialOpen = false;
        _speedDialController.reverse();
      });
    }
  }

  void _openAddPetDialog() {
    showDialog(context: context, builder: (context) => const AddPetDialog());
  }

  Future<void> _handleLogout() async {
    Navigator.of(context).pop();
    try {
      await ref.read(supabaseClientProvider).auth.signOut();
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('onboardingCompleted');
      await prefs.remove('dogProfile');
      await prefs.remove('quizProgress');
      await prefs.remove('lastResult');
      await prefs.remove('lastUserId');
      ref.invalidate(userDogsProvider);
      if (mounted) context.go('/auth');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout fallito: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final speedDialBottomOffset = 90.0 + 40.0 + 16.0 + bottomInset;
    const appBarHeight = 110.0;
    final contentTopPadding = appBarHeight + topInset;
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipPath(
          clipper: _AppBarWaveClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.ctaApricot, // Apricot
                  Color(0xFFFFCC80), // Lighter orange
                ],
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent, // Important for gradient
              elevation: 0,
              toolbarHeight: 80,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.primaryBlue,
                    size: 32,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(Icons.person, color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.ctaApricot),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.ctaApricot,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primaryBlue),
              title: const Text('Impostazioni'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomBar(
        onCenterButtonTap: _toggleSpeedDial,
        isExpanded: _isSpeedDialOpen,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          // Main Content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              contentTopPadding,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _NewsCarousel(),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.ctaApricot.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.pets_rounded,
                            color: AppColors.ctaApricot,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'I tuoi Cani',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Montserrat',
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 400,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final pets = ref.watch(userDogsProvider);
                      return pets.when(
                        data: (list) {
                          if (list.isEmpty) {
                            return Center(
                              child: GestureDetector(
                                onTap: _openAddPetDialog,
                                child: CustomPaint(
                                  painter: _DashedBorderPainter(
                                    color: AppColors.ctaApricot.withOpacity(
                                      0.5,
                                    ),
                                    strokeWidth: 2,
                                    gap: 6,
                                    radius: 28,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.ctaApricot
                                                .withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.pets_rounded,
                                            color: AppColors.ctaApricot,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        const Text(
                                          'Nessun cane presente',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Aggiungilo ora con un tap',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.text.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.ctaApricot,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Aggiungi il tuo cane',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return _PetCarousel(
                            dogs: list,
                            onAddTap: _openAddPetDialog,
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.ctaApricot,
                          ),
                        ),
                        error: (_, __) => Center(
                          child: AppText.body(
                            'Errore nel caricamento dei tuoi pet',
                            color: Colors.red,
                            align: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Consigli Section
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E0), // Soft cream/yellow
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.ctaApricot,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONSIGLI SU MISURA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.ctaApricot,
                            ),
                          ),
                          Text(
                            'Salute e Benessere',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Montserrat',
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Consumer(
                  builder: (context, ref, _) {
                    final pets = ref.watch(userDogsProvider);
                    return pets.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.ctaApricot.withOpacity(
                                      0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.pets_rounded,
                                    color: AppColors.ctaApricot,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Aggiungi un cane per ricevere consigli personalizzati.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.text.withOpacity(0.75),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final dog in list) ...[
                              _buildDogAdviceCard(context, dog),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.ctaApricot,
                        ),
                      ),
                      error: (_, __) => Center(
                        child: AppText.body(
                          'Errore nel caricamento dei consigli',
                          color: Colors.red,
                          align: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 140,
                ), // Extra space for bottom navigation bar
              ],
            ),
          ),

          // Speed Dial Buttons Overlay
          if (_isSpeedDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSpeedDial,
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

          // Add Button
          AnimatedBuilder(
            animation: _speedDialAnimation,
            builder: (context, child) {
              final opacity = _speedDialAnimation.value.clamp(0.0, 1.0);
              return Positioned(
                bottom: speedDialBottomOffset,
                left: MediaQuery.of(context).size.width / 2 - 80,
                child: IgnorePointer(
                  ignoring: !_isSpeedDialOpen,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: _speedDialAnimation.value,
                      child: _buildSpeedDialButton(
                        icon: Icons.add,
                        label: 'Aggiungi',
                        color: AppColors.primaryBlue,
                        onTap: () {
                          _closeSpeedDial();
                          showDialog(
                            context: context,
                            builder: (context) => const AddPetDialog(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Remove Button
          AnimatedBuilder(
            animation: _speedDialAnimation,
            builder: (context, child) {
              final opacity = _speedDialAnimation.value.clamp(0.0, 1.0);
              return Positioned(
                bottom: speedDialBottomOffset,
                right: MediaQuery.of(context).size.width / 2 - 80,
                child: IgnorePointer(
                  ignoring: !_isSpeedDialOpen,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: _speedDialAnimation.value,
                      child: _buildSpeedDialButton(
                        icon: Icons.delete_outline,
                        label: 'Rimuovi',
                        color: Colors.redAccent,
                        onTap: () {
                          _closeSpeedDial();
                          showDialog(
                            context: context,
                            builder: (context) => const DeletePetDialog(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 8,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPetCard() {
    return GestureDetector(
      onTap: _openAddPetDialog,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.ctaApricot.withOpacity(0.5),
          strokeWidth: 2,
          gap: 6,
          radius: 28,
        ),
        child: Container(
          width: 300,
          height: 380,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.8,
            ), // Slight transparency for texture
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.ctaApricot.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 56,
                  color: AppColors.ctaApricot,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Aggiungi un cane',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  'Crea il profilo per il tuo\namico a quattro zampe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDogAdviceCard(BuildContext context, dynamic dog) {
    final dogName = dog.name ?? 'Il tuo cane';
    final riskLabel = _mapRisk(dog.riskLevel);
    final gradeString = riskLabel ?? (dog.riskLevel ?? '');
    final imagePath = dog.breedImageUrl ?? dog.imagePath;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null && imagePath.toString().isNotEmpty
                    ? Image.network(
                        imagePath.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.pets_rounded,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : const Icon(
                        Icons.pets_rounded,
                        color: AppColors.primaryBlue,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dogName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    if (riskLabel != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _riskPillColor(riskLabel).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _riskPillColor(riskLabel).withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          riskLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _riskPillColor(riskLabel),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: AppColors.primaryBlue,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildAdviceShortcut(
                  label: 'Passeggiate',
                  icon: Icons.map_outlined,
                  color: AppColors.primaryBlue,
                  onTap: () {
                    context.push(
                      '/walks',
                      extra: {'grade': gradeString, 'name': dogName},
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildAdviceShortcut(
                  label: 'Esercizi',
                  icon: Icons.fitness_center,
                  color: AppColors.ctaApricot,
                  onTap: () {
                    context.push(
                      '/exercise',
                      extra: {'grade': gradeString, 'name': dogName},
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceShortcut({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final soft = Color.lerp(color, Colors.white, 0.82)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _mapRisk(String? risk) {
    switch (risk) {
      case 'alto':
        return 'Artrosi Grave';
      case 'medio':
        return 'Artrosi Lieve';
      case 'basso':
        return 'Nessun Livello di artrosi';
      default:
        return null;
    }
  }

  Color _riskPillColor(String riskLabel) {
    final normalized = riskLabel.toLowerCase();
    if (normalized.contains('grave')) return Colors.red.shade500;
    if (normalized.contains('lieve')) return Colors.orange.shade500;
    return Colors.green.shade500;
  }
}

class _NewsCarousel extends ConsumerStatefulWidget {
  const _NewsCarousel();

  @override
  ConsumerState<_NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends ConsumerState<_NewsCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  static final Uri _siteUri = Uri.parse('https://www.artrosicane.com');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildNewsItems({
    required MonthlySentence? monthlySentence,
    required bool monthlyLoading,
  }) {
    final monthlySubtitle = monthlyLoading
        ? 'Caricamento tema del mese...'
        : monthlySentence == null
        ? 'Contenuto mensile in aggiornamento.'
        : monthlySentence.focus.isEmpty
        ? 'Scopri il focus del mese.'
        : 'Focus: ${monthlySentence.focus}';

    return [
      {
        'kind': 'walks',
        'title': 'Passeggiate',
        'subtitle': 'Scopri i percorsi consigliati',
        'textColor': Colors.white,
        'image': 'assets/Marina-di-Bibbiona.jpg',
        'isFullBackground': true,
        'buttonText': 'Scopri di più',
      },
      {
        'kind': 'monthly',
        'title': monthlySentence?.title ?? 'Tema del mese',
        'subtitle': monthlySubtitle,
        'colors': const [Color(0xFFEAF2FF), Color(0xFFDDEAFF)],
        'textColor': AppColors.primaryBlue,
        'icon': Icons.calendar_month_rounded,
        'badgeLabel': monthlySentence?.monthName ?? 'Mese corrente',
        'buttonText': 'Apri tema',
        'monthlySentence': monthlySentence,
      },
      {
        'kind': 'article',
        'title': "Cos'e l'artrosi?",
        'subtitle': 'Segnali precoci da non ignorare',
        'colors': const [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
        'textColor': AppColors.primaryBlue,
        'icon': Icons.info_outline,
        'badgeLabel': 'Guida',
        'buttonText': 'Approfondisci',
      },
    ];
  }

  Future<void> _handleNewsTap(Map<String, dynamic> item) async {
    final kind = item['kind'] as String?;
    if (kind == 'walks') {
      if (mounted) await context.push('/walks-overview');
      return;
    }

    if (kind == 'monthly') {
      final sentence = item['monthlySentence'] as MonthlySentence?;
      if (sentence == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tema del mese in aggiornamento.')),
        );
        return;
      }
      _openMonthlySentenceBottomSheet(sentence);
      return;
    }

    final launched = await launchUrl(
      _siteUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire il sito.')),
      );
    }
  }

  void _openMonthlySentenceBottomSheet(MonthlySentence sentence) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ctaApricot.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      sentence.monthName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sentence.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (sentence.focus.isNotEmpty) ...[
                    const Text(
                      'Focus',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sentence.focus,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: Color(0xFF2B3D5A),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (sentence.objective.isNotEmpty) ...[
                    const Text(
                      'Obiettivo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sentence.objective,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: Color(0xFF2B3D5A),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (sentence.areas.isNotEmpty) ...[
                    const Text(
                      'Aree',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sentence.areas.map(
                      (area) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(
                                Icons.circle,
                                size: 7,
                                color: AppColors.ctaApricot,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                area,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                  color: Color(0xFF2B3D5A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlySentenceAsync = ref.watch(currentMonthlySentenceProvider);
    final monthlySentence = monthlySentenceAsync.valueOrNull;
    final monthlyLoading = monthlySentenceAsync.isLoading;
    final newsItems = _buildNewsItems(
      monthlySentence: monthlySentence,
      monthlyLoading: monthlyLoading,
    );

    final safeIndex = newsItems.isEmpty
        ? 0
        : (_currentIndex < 0
              ? 0
              : (_currentIndex > newsItems.length - 1
                    ? newsItems.length - 1
                    : _currentIndex));
    final isFullBackgroundSelected =
        newsItems[safeIndex]['isFullBackground'] == true;

    return Container(
      height: 160, // Increased height to prevent overflow
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Smooth Background Transition
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double page = 0;
                if (_controller.hasClients &&
                    _controller.position.haveDimensions) {
                  page = _controller.page ?? 0;
                } else {
                  page = _currentIndex.toDouble();
                }

                return Stack(
                  children: List.generate(newsItems.length, (index) {
                    final double opacity = (1 - (page - index).abs()).clamp(
                      0.0,
                      1.0,
                    );
                    if (opacity == 0) return const SizedBox.shrink();

                    final item = newsItems[index];
                    final bool isFullBackground =
                        item['isFullBackground'] ?? false;

                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: !isFullBackground
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: item['colors'],
                                )
                              : null,
                        ),
                        child: isFullBackground
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      item['image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.black.withOpacity(0.2),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }),
                );
              },
            ),

            // Content PageView
            PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: newsItems.length,
              itemBuilder: (context, index) {
                final item = newsItems[index];
                final bool isFullBackground = item['isFullBackground'] ?? false;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isFullBackground && item['icon'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 15,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item['badgeLabel'] as String? ?? 'Info',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Montserrat',
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        item['title'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Montserrat',
                          color: isFullBackground
                              ? Colors.white
                              : item['textColor'],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              (isFullBackground
                                      ? Colors.white
                                      : item['textColor'])
                                  .withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _handleNewsTap(item),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            item['buttonText'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color:
                                  AppColors.primaryBlue, // App's specific blue
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Dots Indicator
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(newsItems.length, (index) {
                  final bool isSelected = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 24 : 8,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isFullBackgroundSelected
                                ? Colors.white.withOpacity(0.9)
                                : AppColors.primaryBlue.withOpacity(0.85))
                          : (isFullBackgroundSelected
                                ? Colors.white.withOpacity(0.3)
                                : AppColors.primaryBlue.withOpacity(0.26)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Height of the control points to create a deeper wave
    const waveHeight = 25.0;

    path.lineTo(0, size.height - waveHeight);

    // Create a smooth S-curve
    path.cubicTo(
      size.width * 0.35, // P1x
      size.height + 10, // P1y (Down)
      size.width * 0.65, // P2x
      size.height - 40, // P2y (Up)
      size.width, // P3x
      size.height - 15, // P3y
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _PetCarousel extends StatefulWidget {
  const _PetCarousel({required this.dogs, required this.onAddTap});

  final List<dynamic> dogs;
  final VoidCallback onAddTap;

  @override
  State<_PetCarousel> createState() => _PetCarouselState();
}

class _PetCarouselState extends State<_PetCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  final double _viewportFraction = 0.8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Total items = dogs + 1 (add button)
    final itemCount = widget.dogs.length + 1;

    return PageView.builder(
      controller: _pageController,
      itemCount: itemCount,
      clipBehavior: Clip.none,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        // Calculate Scale
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = _currentPage.toDouble();
            if (_pageController.position.haveDimensions) {
              page = _pageController.page!;
            }
            // Logic: 1.0 at center, 0.9 at sides
            // distance from current centered page
            final distance = (page - index).abs();
            final scale = (1 - (distance * 0.1)).clamp(0.9, 1.0);

            // Opacity fade
            // final opacity = (1 - (distance * 0.3)).clamp(0.5, 1.0);

            return Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: Center(child: _buildItem(context, index)),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index == widget.dogs.length) {
      return _buildAddCard();
    }
    final dog = widget.dogs[index];
    final riskLabel = _mapRisk(dog.riskLevel);

    return PetCard(
      name: dog.name ?? 'Il tuo cane',
      breed: dog.breedName ?? 'Razza non indicata',
      showWarning: riskLabel == null,
      age: dog.ageYears,
      weight: dog.weightKg,
      arthrosisGrade: riskLabel,
      imagePath: dog.breedImageUrl ?? 'assets/first-dog.png',
      backgroundColor: Colors.white,
      onTap: () {
        context.push(
          '/dog-dashboard',
          extra: {
            'id': dog.id,
            'name': dog.name,
            'breed': dog.breedName,
            'imagePath': dog.breedImageUrl,
            'age': dog.ageYears,
            'weight': dog.weightKg,
            'arthrosisGrade': riskLabel ?? 'Non rilevato',
          },
        );
      },
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: widget.onAddTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.ctaApricot.withOpacity(0.5),
          strokeWidth: 2,
          gap: 6,
          radius: 28,
        ),
        child: Container(
          width: 300,
          height: 380, // Match PetCard height
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.ctaApricot.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 56,
                  color: AppColors.ctaApricot,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Aggiungi un cane',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Crea il profilo per il tuo\namico a quattro zampe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _mapRisk(String? risk) {
    switch (risk) {
      case 'alto':
        return 'Artrosi Grave';
      case 'medio':
        return 'Artrosi Lieve';
      case 'basso':
        return 'Nessun Livello di artrosi';
      default:
        return null;
    }
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 5.0,
    this.radius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
