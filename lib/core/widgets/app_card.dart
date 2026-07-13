import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    return Card(
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: content,
            )
          : content,
    );
  }
}
