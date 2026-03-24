import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebResourceScreen extends StatefulWidget {
  final Uri url;
  final String title;

  const WebResourceScreen({super.key, required this.url, required this.title});

  @override
  State<WebResourceScreen> createState() => _WebResourceScreenState();
}

class _WebResourceScreenState extends State<WebResourceScreen> {
  late final WebViewController _controller;
  late final WebViewWidget _webViewWidget;
  int _progress = 0;
  WebResourceError? _loadError;

  @override
  void initState() {
    super.initState();
    final controllerParams = _buildControllerParams();
    _controller = WebViewController.fromPlatformCreationParams(controllerParams)
      ..setBackgroundColor(const Color(0xFF111418))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loadError = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _progress = 100;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loadError = error;
            });
          },
        ),
      )
      ..loadRequest(widget.url);

    _webViewWidget = WebViewWidget.fromPlatformCreationParams(
      params: _buildWidgetParams(),
    );
  }

  PlatformWebViewControllerCreationParams _buildControllerParams() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
        const PlatformWebViewControllerCreationParams(),
      );
    }

    return const PlatformWebViewControllerCreationParams();
  }

  PlatformWebViewWidgetCreationParams _buildWidgetParams() {
    final params = PlatformWebViewWidgetCreationParams(
      controller: _controller.platform,
      layoutDirection: TextDirection.ltr,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
        params,
        displayWithHybridComposition: true,
      );
    }

    return params;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Copy Link',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: widget.url.toString()),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Link copied')));
            },
            icon: const Icon(Icons.content_copy_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          ColoredBox(color: colorScheme.surface, child: _webViewWidget),
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_browser_outlined,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This page could not be shown inside the app.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.url.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _loadError = null;
                          _progress = 0;
                        });
                        _controller.loadRequest(widget.url);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
        ],
      ),
    );
  }
}
