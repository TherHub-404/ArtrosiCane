import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:flutter/material.dart';

class NonMedicalDisclaimer extends StatelessWidget {
  const NonMedicalDisclaimer({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ctaApricot.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Questo strumento supporta la gestione quotidiana e non sostituisce la visita veterinaria né fornisce diagnosi o prescrizioni.',
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          height: 1.25,
          color: AppColors.text.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
