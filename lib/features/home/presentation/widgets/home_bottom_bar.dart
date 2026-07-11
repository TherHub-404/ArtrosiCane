import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/features/home/presentation/widgets/video_call_intro_dialog.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.onCenterButtonTap,
    required this.isExpanded,
  });

  final VoidCallback onCenterButtonTap;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    // Keep the floating bar above the gesture navigation inset so its tap
    // targets stay reachable on devices like the Galaxy S26+.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 90,
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue, // Changed to Primary Blue
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3), // Blue shadow
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
                  icon: Icons.videocam_rounded,
                  label: context.l10n.text('Videocall'),
                  onTap: () {
                    Haptics.tap();
                    VideoCallIntroDialog.show(context);
                  },
                ),
                _BottomBarItem(
                  icon: Icons.directions_walk_rounded,
                  label: context.l10n.text('Passeggiate'),
                  onTap: () {
                    Haptics.tap();
                    context.push('/walks-overview');
                  },
                ),
              ],
            ),
          ),

          // Center Paw Button
          Positioned(
            top: -40,
            child: GestureDetector(
              onTap: () {
                Haptics.tap();
                onCenterButtonTap();
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.ctaApricot,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctaApricot.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isExpanded ? Icons.close : Icons.pets_rounded,
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

class _BottomBarItem extends StatefulWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_BottomBarItem> createState() => _BottomBarItemState();
}

class _BottomBarItemState extends State<_BottomBarItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.94 : 1.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: _setPressed,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.10),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Icon(widget.icon, size: 22, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
