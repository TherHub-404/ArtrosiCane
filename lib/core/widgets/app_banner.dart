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
    );
  }

  static void _showBanner(
    BuildContext context,
    String message, {
    required Color background,
    required IconData icon,
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
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text(
              'Chiudi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
