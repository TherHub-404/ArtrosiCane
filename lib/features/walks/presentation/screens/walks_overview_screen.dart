import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WalksOverviewScreen extends StatelessWidget {
  const WalksOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
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
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 80,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              centerTitle: true,
              title: const Text(
                'Passeggiate',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Montserrat',
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _WalksBottomBar(
        onCenterButtonTap: () => context.go('/home'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          SizedBox(height: AppSpacing.sm),
          _WalkCard(
            badgeText: 'Rischio Basso',
            badgeColor: Color(0xFF4CAF50),
            title: 'Pineta di Bibbona',
            location: 'Marina di Bibbona',
            distance: '2.5 km',
            duration: '45 min',
            terrain: 'Pianeggiante',
            imageAsset: 'assets/Pineta-di-Bibbiona.jpg',
          ),
          SizedBox(height: AppSpacing.lg),
          _WalkCard(
            badgeText: 'Artrosi Lieve',
            badgeColor: Color(0xFFFF9800),
            title: 'Sentiero delle Dune',
            location: 'Marina di Bibbona',
            distance: '1.2 km',
            duration: '20 min',
            terrain: 'Sabbioso',
            imageAsset: 'assets/Sentiero-delle-dune.jpg',
          ),
          SizedBox(height: AppSpacing.lg),
          _WalkCard(
            badgeText: 'Artrosi Grave',
            badgeColor: Color(0xFFF44336),
            title: 'Percorso Soft Ombreggiato',
            location: 'Parco Comunale',
            distance: '0.5 km',
            duration: '10 min',
            terrain: 'Liscio/Erba',
            imageAsset: 'assets/Sentiero-Soft-Bibbiona.jpg',
          ),
          SizedBox(height: 120), // Space for bottom bar
        ],
      ),
    );
  }
}

class _WalkCard extends StatelessWidget {
  const _WalkCard({
    required this.badgeText,
    required this.badgeColor,
    required this.title,
    required this.location,
    required this.distance,
    required this.duration,
    required this.terrain,
    required this.imageAsset,
  });

  final String badgeText;
  final Color badgeColor;
  final String title;
  final String location;
  final String distance;
  final String duration;
  final String terrain;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.asset(
                  imageAsset,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: AppColors.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Montserrat',
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.accessibility_new,
                      color: AppColors.ctaApricot,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Info row
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.straighten,
                      label: distance,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.access_time,
                      label: duration,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.terrain,
                      label: terrain,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.text.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _WalksBottomBar extends StatelessWidget {
  const _WalksBottomBar({
    required this.onCenterButtonTap,
  });

  final VoidCallback onCenterButtonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BottomBarItem(
                  icon: Icons.edit_note_rounded,
                  label: 'Blog',
                  onTap: () {},
                ),
                _BottomBarItem(
                  icon: Icons.map_rounded,
                  label: 'Passeggiate',
                  onTap: () {},
                  isActive: true,
                ),
              ],
            ),
          ),

          // Center Home Button
          Positioned(
            top: -40,
            child: GestureDetector(
              onTap: onCenterButtonTap,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.ctaApricot,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctaApricot.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.home_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isActive ? AppColors.ctaApricot : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.ctaApricot : Colors.white,
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
      size.height + 10,  // P1y (Down)
      size.width * 0.65, // P2x
      size.height - 40,  // P2y (Up)
      size.width,        // P3x
      size.height - 15,  // P3y
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
