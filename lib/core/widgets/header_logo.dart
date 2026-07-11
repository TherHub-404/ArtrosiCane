import 'package:flutter/material.dart';

class HeaderLogo extends StatelessWidget {
  const HeaderLogo({
    super.key,
    this.leftWidth = 152,
    this.rightWidth = 132,
    this.leftAssetPath = 'assets/ArtrosiCane-Logo.png',
    this.rightAssetPath = 'assets/logo-bibione.png',
    this.showRight = true,
  });

  final double leftWidth;
  final double rightWidth;
  final String leftAssetPath;
  final String rightAssetPath;
  final bool showRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: showRight
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(leftAssetPath, width: leftWidth, fit: BoxFit.contain),
        if (showRight)
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                rightAssetPath,
                width: rightWidth,
                fit: BoxFit.contain,
              ),
            ),
          ),
        if (!showRight) const Spacer(),
      ],
    );
  }
}
