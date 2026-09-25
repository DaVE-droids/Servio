import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the browser (a new tab on web), and tells the user if
/// nothing could open it rather than failing silently.
Future<void> openExternalLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text('Couldn’t open $url. Try again later.')),
    );
  }
}
