import 'package:flutter/material.dart';
import 'package:artrosi_cane/theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor = AppColors.background,
    this.padding = const EdgeInsets.all(16),
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color backgroundColor;
  final EdgeInsets padding;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : SafeArea(top: false, child: bottomNavigationBar!),
    );
  }
}
