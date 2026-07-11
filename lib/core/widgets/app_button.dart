import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final activeCallback = enabled ? Haptics.wrap(onPressed) : null;
    return ElevatedButton(
      onPressed: activeCallback,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
            )
          : null,
      child: Text(label),
    );
  }
}
