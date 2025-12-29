import 'package:flutter/material.dart';
import 'package:artrosi_cane/theme/app_typography.dart';

class AppText {
  const AppText._();

  static Widget h1(String text, {Color? color, TextAlign? align}) {
    return Text(
      text,
      textAlign: align,
      style: AppTypography.h1.copyWith(color: color),
    );
  }

  static Widget body(
    String text, {
    bool bold = false,
    TextAlign? align,
    Color? color,
  }) {
    final baseStyle = bold ? AppTypography.bodyBold : AppTypography.body;
    return Text(
      text,
      textAlign: align,
      style: baseStyle.copyWith(color: color),
    );
  }

  static Widget custom(
    String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? align,
    double? height,
  }) {
    return Text(
      text,
      textAlign: align,
      style: AppTypography.body.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      ),
    );
  }
}
