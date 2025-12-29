import 'package:artrosi_cane/router/app_router.dart';
import 'package:artrosi_cane/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ArtrosiCaneApp extends ConsumerWidget {
  const ArtrosiCaneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Intl.defaultLocale = 'it';
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Artrosi Cane',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it')],
    );
  }
}
