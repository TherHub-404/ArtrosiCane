import 'package:artrosi_cane/app.dart';
import 'package:artrosi_cane/core/providers/shared_prefs_provider.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapLoaderApp());
}

class _BootstrapLoaderApp extends StatefulWidget {
  const _BootstrapLoaderApp();

  @override
  State<_BootstrapLoaderApp> createState() => _BootstrapLoaderAppState();
}

class _BootstrapLoaderAppState extends State<_BootstrapLoaderApp> {
  late Future<SharedPreferences> _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = _loadPrefs();
  }

  Future<SharedPreferences> _loadPrefs() {
    return SharedPreferences.getInstance().timeout(
      const Duration(seconds: 8),
      onTimeout: () =>
          throw StateError('SharedPreferences initialization timed out'),
    );
  }

  void _retry() {
    setState(() {
      _prefsFuture = _loadPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(snapshot.data!),
            ],
            child: const ArtrosiCaneApp(),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _BootstrapFallbackScreen(
            hasError: snapshot.hasError,
            onRetry: _retry,
          ),
        );
      },
    );
  }
}

class _BootstrapFallbackScreen extends StatelessWidget {
  const _BootstrapFallbackScreen({
    required this.hasError,
    required this.onRetry,
  });

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/ArtrosiCane-Logo.png', width: 180),
                const SizedBox(height: 24),
                Text(
                  hasError
                      ? l10n.text(
                          'L\'app sta impiegando troppo tempo ad avviarsi.',
                        )
                      : l10n.text('Stiamo avviando ZampaSiCura...'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E305A),
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.text('Tocca qui sotto per riprovare.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1E305A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onRetry,
                    child: Text(l10n.text('Riprova')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
