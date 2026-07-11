import 'package:artrosi_cane/core/auth/session_guard.dart';
import 'package:artrosi_cane/core/bootstrap/app_bootstrap.dart';
import 'package:artrosi_cane/core/providers/app_locale_provider.dart';
import 'package:artrosi_cane/core/utils/responsive.dart';
import 'package:artrosi_cane/l10n/app_locale.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/router/app_router.dart';
import 'package:artrosi_cane/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ArtrosiCaneApp extends ConsumerStatefulWidget {
  const ArtrosiCaneApp({super.key});

  @override
  ConsumerState<ArtrosiCaneApp> createState() => _ArtrosiCaneAppState();
}

class _ArtrosiCaneAppState extends ConsumerState<ArtrosiCaneApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localeOverride = ref.watch(appLocaleProvider);
    final activeLocale =
        localeOverride ?? WidgetsBinding.instance.platformDispatcher.locale;
    Intl.defaultLocale = AppLanguage.fromPlatformLocale(activeLocale).code;
    ref.watch(appBootstrapProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.text('ZampaSiCura'),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Fold two factors into one app-wide text scaler so every screen
        // adapts without per-widget code:
        //  - OS font / display-zoom preference, clamped (it is aggressive
        //    on Samsung devices) so it cannot rewrap or overflow layouts.
        //  - Screen width vs the design baseline, so narrow phones (e.g.
        //    Galaxy S26 / S26+ at ~360 dp) scale type down to fit.
        final osFactor = mediaQuery.textScaler.scale(1).clamp(0.9, 1.15);
        final widthFactor =
            (mediaQuery.size.width / kBaselineWidth).clamp(0.85, 1.10);
        final effectiveTextScaler =
            TextScaler.linear((osFactor * widthFactor).toDouble());
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: effectiveTextScaler),
          child: SessionGuard(child: child ?? const SizedBox.shrink()),
        );
      },
      theme: AppTheme.light(),
      locale: localeOverride,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLanguage.supportedLocales,
    );
  }
}
