import 'package:flutter/material.dart';

import 'safe_image.dart';

/// Opens [url] full screen with pinch-to-zoom (payment slips, chat photos).
Future<void> showImageViewer(
  BuildContext context, {
  required String url,
  String title = 'Photo',
}) {
  return Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ImageViewerScreen(url: url, title: title),
  ));
}

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.url, this.title = 'Photo'});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SafeImage(
            path: url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      color: Colors.white70, size: 48),
                  SizedBox(height: 8),
                  Text('This image could not be loaded.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
