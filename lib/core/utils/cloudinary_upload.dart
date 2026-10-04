import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_backend.dart';
import 'app_errors.dart';
import 'image_upload.dart';

/// Uploads public images without Firebase Storage using Cloudinary's unsigned
/// upload API. Never use this for private evidence or payment documents.
Future<CloudinaryImage> uploadPublicImage(PickedImage image) async {
  if (!kUseCloudinary ||
      kCloudinaryCloudName.isEmpty ||
      kCloudinaryUploadPreset.isEmpty) {
    throw const AppException('Public image hosting is not configured.');
  }
  final request = http.MultipartRequest(
    'POST',
    Uri.parse(
        'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/auto/upload'),
  )
    ..fields['upload_preset'] = kCloudinaryUploadPreset
    ..files.add(http.MultipartFile.fromBytes(
      'file',
      image.bytes,
      filename: image.name,
    ));

  final response = await request.send();
  final body = await response.stream.bytesToString();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw AppException('Public image upload failed (${response.statusCode}).');
  }
  final data = jsonDecode(body);
  if (data is! Map || data['secure_url'] is! String) {
    throw const AppException('Public image upload returned no URL.');
  }
  return CloudinaryImage(
    url: data['secure_url'] as String,
    publicId: (data['public_id'] ?? '').toString(),
  );
}

class CloudinaryImage {
  const CloudinaryImage({required this.url, required this.publicId});

  final String url;
  final String publicId;
}
