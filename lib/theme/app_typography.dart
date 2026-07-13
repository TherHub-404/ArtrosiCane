import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  const AppTypography._();

  static TextStyle get h1 => GoogleFonts.montserrat(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryBlue,
  );

  static TextStyle get body => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static TextStyle get bodyBold => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static TextTheme textTheme = TextTheme(
    displayLarge: h1,
    bodyMedium: body,
    bodyLarge: bodyBold,
  );
}
