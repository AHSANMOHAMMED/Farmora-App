import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import 'app_errors.dart';

/// Upper bound enforced by `storage.rules` for every image path.
const int kMaxImageBytes = 5 * 1024 * 1024;

/// An image chosen on the device, held in memory until it is uploaded.
///
/// Bytes (not `dart:io` File paths) so the same code works on Flutter Web,
/// Android and iOS.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.name,
    required this.contentType,
  });

  final Uint8List bytes;
  final String name;
  final String contentType;

  /// File extension matching [contentType].
  String get extension => switch (contentType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/gif' => 'gif',
        _ => 'jpg',
      };
}

/// Detects the real image type from magic bytes. Returns null when the data
/// is not a supported image (the picker's reported MIME type and extension
/// can't be trusted, and HEIC/SVG/PDF must be rejected).
String? sniffImageContentType(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A) {
    return 'image/png';
  }
  if (b.length >= 12 &&
      b[0] == 0x52 && // RIFF....WEBP
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50) {
    return 'image/webp';
  }
  if (b.length >= 6 &&
      b[0] == 0x47 && // GIF87a / GIF89a
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x38) {
    return 'image/gif';
  }
  return null;
}

/// Validates raw bytes and wraps them as a [PickedImage].
/// Throws [AppException] with a user-facing message when unusable.
PickedImage validateImageBytes(Uint8List bytes, {String name = 'image'}) {
  if (bytes.isEmpty) {
    throw const AppException('The selected file is empty.');
  }
  final type = sniffImageContentType(bytes);
  if (type == null) {
    throw const AppException(
        'Unsupported file. Please choose a JPG, PNG or WebP photo.');
  }
  if (bytes.length > kMaxImageBytes) {
    final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
    throw AppException('Image is too large ($mb MB). The limit is 5 MB.');
  }
  final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return PickedImage(
    bytes: bytes,
    name: safe.isEmpty ? 'image' : safe,
    contentType: type,
  );
}

/// Picks images through `image_picker`, which uses a file input on the web
/// and the native gallery/camera on Android and iOS. Photos are downscaled by
/// the picker first so typical phone photos fit under [kMaxImageBytes].
class ImagePickerHelper {
  ImagePickerHelper({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxDimension = 1600.0;
  static const _quality = 80;

  /// One image, or null when the user cancels.
  Future<PickedImage?> pickOne({ImageSource source = ImageSource.gallery}) async {
    final XFile? file = await _guard(() => _picker.pickImage(
          source: source,
          maxWidth: _maxDimension,
          maxHeight: _maxDimension,
          imageQuality: _quality,
        ));
    if (file == null) return null;
    return validateImageBytes(await file.readAsBytes(), name: file.name);
  }

  /// Up to [limit] images. Invalid files are skipped and reported through
  /// [rejected] so one bad file doesn't discard the others. Empty on cancel.
  Future<List<PickedImage>> pickMany({
    required int limit,
    void Function(String reason)? rejected,
  }) async {
    if (limit <= 0) return const [];
    final files = await _guard(() => _picker.pickMultiImage(
              maxWidth: _maxDimension,
              maxHeight: _maxDimension,
              imageQuality: _quality,
            )) ??
        const <XFile>[];
    final out = <PickedImage>[];
    for (final file in files) {
      if (out.length >= limit) {
        rejected?.call('Only $limit more photo(s) can be added.');
        break;
      }
      try {
        out.add(validateImageBytes(await file.readAsBytes(), name: file.name));
      } on AppException catch (e) {
        rejected?.call('${file.name}: ${e.message}');
      }
    }
    return out;
  }

  /// Maps picker platform errors (permission denied, no camera, …) to
  /// [AppException]s with actionable messages.
  Future<T?> _guard<T>(Future<T?> Function() pick) async {
    try {
      return await pick();
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('camera_access_denied') ||
          code.contains('photo_access_denied') ||
          code.contains('denied') ||
          code.contains('permission')) {
        throw AppException(
          code.contains('camera')
              ? 'Camera access was denied. Allow it in your device settings.'
              : 'Photo access was denied. Allow it in your device settings.',
          cause: e,
        );
      }
      if (code.contains('no_available_camera')) {
        throw AppException('No camera is available on this device.',
            cause: e);
      }
      throw AppException('Could not open the photo picker.', cause: e);
    }
  }
}
