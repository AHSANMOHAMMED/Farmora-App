import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_backend.dart';
import 'app_errors.dart';
import 'image_upload.dart';

import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

/// Uploads raw public media without Firebase Storage using Cloudinary's unsigned
/// upload API. Never use this for private evidence or payment documents.
Future<CloudinaryMedia> uploadPublicMedia(
  Uint8List bytes,
  String fileName, {
  String? contentType,
}) async {
  if (!kUseCloudinary ||
      kCloudinaryCloudName.isEmpty ||
      kCloudinaryUploadPreset.isEmpty) {
    throw const AppException('Public media hosting is not configured.');
  }

  final safeName = fileName.trim().isNotEmpty
      ? fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
      : 'file_${DateTime.now().millisecondsSinceEpoch}';

  MediaType? mediaType;
  if (contentType != null && contentType.contains('/')) {
    try {
      mediaType = MediaType.parse(contentType);
    } catch (_) {}
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse(
        'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/auto/upload'),
  )
    ..fields['upload_preset'] = kCloudinaryUploadPreset
    ..files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: safeName,
      contentType: mediaType,
    ));

  final streamed = await request.send().timeout(const Duration(seconds: 45));
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    debugPrint('Cloudinary upload failed (${response.statusCode}): ${response.body}');
    throw AppException('Public media upload failed (${response.statusCode}).');
  }
  final data = jsonDecode(response.body);
  if (data is! Map || data['secure_url'] is! String) {
    throw const AppException('Public media upload returned no URL.');
  }
  return CloudinaryMedia(
    url: data['secure_url'] as String,
    publicId: (data['public_id'] ?? '').toString(),
  );
}

/// Uploads public images without Firebase Storage using Cloudinary's unsigned
/// upload API. Never use this for private evidence or payment documents.
Future<CloudinaryMedia> uploadPublicImage(PickedImage image) async {
  final nameWithExt = image.name.contains('.')
      ? image.name
      : '${image.name}.${image.extension}';
  return uploadPublicMedia(
    image.bytes,
    nameWithExt,
    contentType: image.contentType,
  );
}
class CloudinaryMedia {
  const CloudinaryMedia({required this.url, required this.publicId});

  final String url;
  final String publicId;
}
