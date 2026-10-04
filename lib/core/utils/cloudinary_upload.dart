import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_backend.dart';
import 'app_errors.dart';
import 'image_upload.dart';

/// Uploads raw public media without Firebase Storage using Cloudinary's unsigned
/// upload API. Never use this for private evidence or payment documents.
Future<CloudinaryMedia> uploadPublicMedia(Uint8List bytes, String fileName) async {
  if (!kUseCloudinary ||
      kCloudinaryCloudName.isEmpty ||
      kCloudinaryUploadPreset.isEmpty) {
    throw const AppException('Public media hosting is not configured.');
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
      filename: fileName,
    ));

  final response = await request.send();
  final body = await response.stream.bytesToString();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw AppException('Public media upload failed (${response.statusCode}).');
  }
  final data = jsonDecode(body);
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
  return uploadPublicMedia(image.bytes, image.name);
}
class CloudinaryMedia {
  const CloudinaryMedia({required this.url, required this.publicId});

  final String url;
  final String publicId;
}
