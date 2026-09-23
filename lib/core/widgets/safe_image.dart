import 'package:flutter/material.dart';

class SafeImage extends StatelessWidget {
  final String path;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const SafeImage({
    super.key,
    required this.path,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return errorBuilder?.call(context, Exception('Empty path'), null) ?? const Icon(Icons.broken_image);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    } else {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }
  }
}
