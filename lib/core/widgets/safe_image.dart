import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      return errorBuilder?.call(context, Exception('Empty path'), null) ?? const Icon(Icons.broken_image, color: Colors.grey);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (kIsWeb) {
        // On web, fetching bytes needs CORS on the Storage bucket. Fall back
        // to an <img> element so Firebase Storage URLs render either way.
        return Image.network(
          path,
          fit: fit,
          width: width,
          height: height,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
          errorBuilder: errorBuilder ??
              (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        width: width,
        height: height,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => errorBuilder != null 
          ? errorBuilder!(context, error, null)
          : const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }
}
