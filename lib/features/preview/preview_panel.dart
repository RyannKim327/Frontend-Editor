import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.controller,
    required this.loadingProgress,
    required this.error,
  });

  final WebViewController? controller;
  final int loadingProgress;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final webController = controller;

    if (webController == null) {
      return const Center(child: Text('Starting local server...'));
    }

    return Stack(
      children: [
        WebViewWidget(controller: webController),
        if (loadingProgress < 100)
          LinearProgressIndicator(value: loadingProgress / 100),
        if (error != null)
          Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
