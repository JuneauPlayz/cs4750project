import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/web_resource_screen.dart';

class LinkLauncherService {
  Future<void> open(BuildContext context, Uri url, {String? title}) async {
    final normalizedUrl = _normalizeUrl(url);

    if (_isWebUrl(normalizedUrl)) {
      if (_shouldUseEmbeddedWebViewFirst()) {
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WebResourceScreen(
              url: normalizedUrl,
              title: title ?? normalizedUrl.host,
            ),
          ),
        );
        return;
      }

      for (final mode in const [
        LaunchMode.inAppBrowserView,
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
      ]) {
        try {
          final launched = await launchUrl(normalizedUrl, mode: mode);
          if (launched) return;
        } catch (_) {
          // Try the next fallback mode.
        }
      }

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WebResourceScreen(
            url: normalizedUrl,
            title: title ?? normalizedUrl.host,
          ),
        ),
      );
      return;
    }

    for (final mode in const [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ]) {
      try {
        final launched = await launchUrl(normalizedUrl, mode: mode);
        if (launched) return;
      } catch (_) {
        // Try the next fallback mode.
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to open ${normalizedUrl.host}.')),
    );
  }

  bool _isWebUrl(Uri url) => url.scheme == 'http' || url.scheme == 'https';

  bool _shouldUseEmbeddedWebViewFirst() {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Uri _normalizeUrl(Uri url) {
    if (url.hasScheme) return url;
    final rawValue = url.toString().trim();
    if (rawValue.startsWith('//')) {
      return Uri.parse('https:$rawValue');
    }
    return Uri.parse('https://$rawValue');
  }
}
