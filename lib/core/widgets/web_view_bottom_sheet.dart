import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Presents [url] inside an in-app [WebView] rendered as a rounded modal
/// bottom sheet, so the user never leaves the app for an external browser.
Future<void> showWebViewBottomSheet(
  BuildContext context, {
  required Uri url,
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            color: Colors.white,
            elevation: 20,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.82,
              child: _WebViewSheet(initialUri: url, title: title),
            ),
          ),
        ),
      );
    },
  );
}

class _WebViewSheet extends StatefulWidget {
  const _WebViewSheet({required this.initialUri, required this.title});

  final Uri initialUri;
  final String title;

  @override
  State<_WebViewSheet> createState() => _WebViewSheetState();
}

class _WebViewSheetState extends State<_WebViewSheet> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(widget.initialUri);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Montserrat',
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(
                controller: _controller,
                // Let the WebView eagerly claim vertical drags so the page
                // scrolls instead of the modal sheet capturing the gesture.
                gestureRecognizers: const {
                  Factory<OneSequenceGestureRecognizer>(
                    EagerGestureRecognizer.new,
                  ),
                },
              ),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
