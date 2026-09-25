import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import 'safe_image.dart';

/// Opens [url] full screen with pinch-to-zoom (payment slips, chat photos).
Future<void> showImageViewer(
  BuildContext context, {
  required String url,
  String? title,
}) {
  return Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ImageViewerScreen(url: url, title: title),
  ));
}

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? context.l10n.chatPhoto),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SafeImage(
            path: url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_outlined,
                      color: Colors.white70, size: 48),
                  const SizedBox(height: 8),
                  Text(context.l10n.widgetImageLoadFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
