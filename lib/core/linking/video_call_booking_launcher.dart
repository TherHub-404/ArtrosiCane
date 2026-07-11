import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoCallBookingLauncher {
  static const String calendlyUrl = 'https://calendly.com/adriano-monino/30min';

  static Future<bool> open(BuildContext context) async {
    final uri = Uri.parse(calendlyUrl);

    var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text('Impossibile aprire Calendly. Riprova tra poco.'),
          ),
        ),
      );
    }

    return opened;
  }
}
