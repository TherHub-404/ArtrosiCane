import 'package:artrosi_cane/core/linking/link_service.dart';
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
    Future<void>.microtask(() => ref.read(linkServiceProvider).start());
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'it';
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ZampaSicura',
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
