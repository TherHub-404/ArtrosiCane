import 'package:artrosi_cane/core/widgets/app_scaffold.dart';
import 'package:artrosi_cane/core/widgets/app_text.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/pet_card.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/add_pet_dialog.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/delete_pet_dialog.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:artrosi_cane/features/home/presentation/providers/home_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final speedDialBottomOffset = 90.0 + 40.0 + 16.0 + bottomInset;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipPath(
          clipper: _AppBarWaveClipper(),
          child: AppBar(
            backgroundColor: AppColors.ctaApricot,
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
              leading: const Icon(Icons.logout, color: AppColors.primaryBlue),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              onTap: () {
                context.go('/auth');
              },
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
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _NewsCarousel(),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'My Pets',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Montserrat',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  width: double.infinity,
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
                                    border: Border.all(
                                      color: AppColors.ctaApricot.withOpacity(
                                        0.4,
                                      ),
                                      width: 1.5,
                                    ),
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
                            );
                          }
                          return PageView.builder(
                            clipBehavior: Clip.none,
                            itemCount:
                                list.length + 1, // +1 for "Aggiungi Pet" card
                            controller: PageController(viewportFraction: 0.85),
                            itemBuilder: (context, index) {
                              // Last item is "Aggiungi Pet" card
                              if (index == list.length) {
                                return Center(child: _buildAddPetCard());
                              }

                              // Regular pet cards
                              final dog = list[index];
                              final riskLabel = _mapRisk(dog.riskLevel);
                              return Center(
                                child: PetCard(
                                  name: dog.name ?? 'Il tuo cane',
                                  breed: dog.breedName ?? 'Razza non indicata',
                                  subtitle: null,
                                  showWarning: riskLabel == null,
                                  age: dog.ageYears,
                                  weight: dog.weightKg,
                                  arthrosisGrade: riskLabel,
                                  imagePath:
                                      dog.breedImageUrl ??
                                      'assets/first-dog.png',
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
                                        'arthrosisGrade':
                                            riskLabel ?? 'Non rilevato',
                                      },
                                    );
                                  },
                                ),
                              );
                            },
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
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Consigli per te',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Montserrat',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildConsigliCard(
                  title: 'Attività fisica',
                  subtitle: 'Esercizi consigliati per la settimana',
                  progress: 0.6,
                  icon: Icons.directions_run,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildConsigliCard(
                  title: 'Alimentazione',
                  subtitle: 'Piano nutrizionale personalizzato',
                  progress: 0.8,
                  icon: Icons.restaurant_menu,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildConsigliCard(
                  title: 'Monitoraggio salute',
                  subtitle: 'Prossimo controllo tra 15 giorni',
                  progress: 0.4,
                  icon: Icons.favorite,
                ),
                const SizedBox(height: 100),
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
      child: Container(
        width: 300,
        height: 380,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.ctaApricot.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 64,
                color: AppColors.ctaApricot,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Aggiungi un cane',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.ctaApricot,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Tocca per aggiungere un nuovo amico a quattro zampe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsigliCard({
    required String title,
    required String subtitle,
    required double progress,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ctaApricot.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.ctaApricot, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.ctaApricot,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _NewsCarousel extends StatefulWidget {
  const _NewsCarousel();

  @override
  State<_NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<_NewsCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _newsItems = [
    {
      "title": "Cos'è l'artrosi?",
      "subtitle": "Segni precoci",
      "color": Colors.white, // White
      "textColor": AppColors.primaryBlue,
      "icon": Icons.info_outline,
      "buttonText": "Scopri di più",
    },
    {
      "title": "Nuovi snack",
      "subtitle": "Ricette sane",
      "color": Color(0xFFFFE0B2), // Light Orange (Apricot-ish)
      "textColor": Color(0xFF2D2D2D),
      "icon": Icons.restaurant_menu,
      "buttonText": "Leggi ora",
    },
    {
      "title": "Esercizi",
      "subtitle": "Movimento",
      "color": Color(0xFFBBDEFB), // Light Blue
      "textColor": AppColors.primaryBlue,
      "icon": Icons.directions_run,
      "buttonText": "Inizia",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 130,
      decoration: BoxDecoration(
        color: _newsItems[_currentIndex]['color'],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _newsItems.length,
            itemBuilder: (context, index) {
              final item = _newsItems[index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Montserrat',
                              color: item['textColor'],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'],
                            style: TextStyle(
                              fontSize: 14,
                              color: item['textColor'].withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Text(
                              item['buttonText'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item['textColor'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Icon placeholder to keep spacing, actual icon is static or sliding?
                    // User said "informazioni devono scorrere". So icon slides too.
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'],
                        size: 32,
                        color: item['textColor'],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Dots Indicator
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_newsItems.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentIndex == index ? 20 : 8,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? (_newsItems[_currentIndex]['textColor'] as Color)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from top-left
    path.lineTo(0, size.height - 10);

    // Create wave at the bottom (same curvature as PetCard)
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height, // Control point
      size.width * 0.5,
      size.height - 10, // End point
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 20, // Control point
      size.width,
      size.height - 10, // End point
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
