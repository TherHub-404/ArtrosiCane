import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppBanner {
  const AppBanner._();

  static void showSuccess(BuildContext context, String message) {
    _showBanner(
      context,
      message,
      background: AppColors.primaryBlue,
      icon: Icons.check_circle_rounded,
      duration: const Duration(seconds: 3),
      showCloseButton: false,
    );
  }

  static void _showBanner(
    BuildContext context,
    String message, {
    required Color background,
    required IconData icon,
    Duration? duration,
    bool showCloseButton = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();

    messenger.showMaterialBanner(
      MaterialBanner(
        elevation: 6,
        backgroundColor: background,
        leading: Icon(icon, color: Colors.white),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (showCloseButton)
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: Text(
                context.l10n.text('Chiudi'),
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );

    if (duration != null) {
      Future.delayed(duration, () {
        messenger.hideCurrentMaterialBanner();
      });
    }
  }
}
